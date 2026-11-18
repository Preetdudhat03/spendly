-- ==============================================================================
-- Spendly Notifications & Preferences Database Migration
-- Native Supabase Auth & Row Level Security (RLS)
-- ==============================================================================

-- 1. Notifications Table
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  family_id uuid not null references public.families(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  read_at timestamptz,
  priority text not null default 'normal' check (priority in ('low', 'normal', 'high', 'urgent')),
  deep_link text,
  notification_key text,
  expires_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Idempotency and search indexes
create unique index if not exists idx_notifications_idempotency 
  on public.notifications (family_id, notification_key) 
  where notification_key is not null;

create index if not exists idx_notifications_family_user_date 
  on public.notifications (family_id, user_id, created_at desc);

create index if not exists idx_notifications_unread 
  on public.notifications (family_id, is_read, created_at desc);

-- 2. User Device Tokens Table (for multi-device push notifications)
create table if not exists public.user_device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null,
  platform text not null check (platform in ('android', 'ios', 'web', 'windows', 'macos', 'linux')),
  push_token text not null,
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, device_id)
);

create index if not exists idx_device_tokens_user 
  on public.user_device_tokens (user_id, is_active);

-- 3. Notification Preferences Table
create table if not exists public.notification_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  push_enabled boolean not null default true,
  expense_alerts boolean not null default true,
  budget_alerts boolean not null default true,
  family_alerts boolean not null default true,
  spending_insights boolean not null default true,
  expense_reminders boolean not null default false,
  reminder_time text not null default '20:00',
  updated_at timestamptz not null default now()
);

-- Enable Row Level Security (RLS)
alter table public.notifications enable row level security;
alter table public.user_device_tokens enable row level security;
alter table public.notification_preferences enable row level security;

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- Notifications Policies
drop policy if exists "Users can view family notifications" on public.notifications;
create policy "Users can view family notifications"
on public.notifications for select
to authenticated
using (
  family_id in (select public.get_user_family_ids(auth.uid()))
  and (user_id is null or user_id = auth.uid())
);

drop policy if exists "Members can insert notifications for family" on public.notifications;
create policy "Members can insert notifications for family"
on public.notifications for insert
to authenticated
with check (
  created_by = auth.uid()
  or family_id in (select public.get_user_family_ids(auth.uid()))
);

drop policy if exists "Users can update their notifications or family notifications" on public.notifications;
create policy "Users can update their notifications or family notifications"
on public.notifications for update
to authenticated
using (
  family_id in (select public.get_user_family_ids(auth.uid()))
  and (user_id is null or user_id = auth.uid())
);

drop policy if exists "Users or admins can delete notifications" on public.notifications;
create policy "Users or admins can delete notifications"
on public.notifications for delete
to authenticated
using (
  family_id in (select public.get_user_family_ids(auth.uid()))
  and (user_id = auth.uid() or created_by = auth.uid() or public.is_family_admin(auth.uid(), family_id))
);

-- Device Tokens Policies
drop policy if exists "Users can manage their own device tokens" on public.user_device_tokens;
create policy "Users can manage their own device tokens"
on public.user_device_tokens for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Preferences Policies
drop policy if exists "Users can manage their own notification preferences" on public.notification_preferences;
create policy "Users can manage their own notification preferences"
on public.notification_preferences for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Enable full replication payload & Realtime publication for notifications table
alter table public.notifications replica identity full;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;

-- 4. Clean Multi-Account Device Token Reassignment Trigger
-- Ensures that when an account activates a device token, any previous account on that physical device
-- or sharing the same FCM token is cleanly deactivated.
create or replace function public.handle_device_token_reassignment()
returns trigger as $$
begin
  if new.is_active = true then
    update public.user_device_tokens
    set is_active = false, updated_at = now()
    where (device_id = new.device_id or push_token = new.push_token)
      and user_id != new.user_id
      and is_active = true;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_device_token_registered on public.user_device_tokens;
create trigger on_device_token_registered
  before insert or update of is_active, push_token on public.user_device_tokens
  for each row
  execute function public.handle_device_token_reassignment();

-- Ensure created_by column exists on notifications table
alter table public.notifications add column if not exists created_by uuid references auth.users(id) on delete set null;

-- 5. Atomic RPC for Device Token Registration with Guaranteed Multi-Account Isolation
create or replace function public.register_device_token(
  p_device_id text,
  p_platform text,
  p_push_token text
)
returns void as $$
begin
  -- Deactivate any active token for other users sharing this physical device ID or push token
  update public.user_device_tokens
  set is_active = false, updated_at = now()
  where (device_id = p_device_id or push_token = p_push_token)
    and user_id != auth.uid()
    and is_active = true;

  -- Upsert current user's token
  insert into public.user_device_tokens (
    user_id,
    device_id,
    platform,
    push_token,
    device_token,
    is_active,
    last_seen_at,
    updated_at
  )
  values (
    auth.uid(),
    p_device_id,
    p_platform,
    p_push_token,
    p_push_token,
    true,
    now(),
    now()
  )
  on conflict (user_id, device_id)
  do update set
    platform = excluded.platform,
    push_token = excluded.push_token,
    device_token = excluded.device_token,
    is_active = true,
    last_seen_at = now(),
    updated_at = now();
end;
$$ language plpgsql security definer;

-- 6. Atomic RPC for Deactivating Device Token on Logout
create or replace function public.deactivate_device_token(
  p_device_id text,
  p_push_token text default null
)
returns void as $$
begin
  update public.user_device_tokens
  set is_active = false, updated_at = now()
  where user_id = auth.uid()
    and (device_id = p_device_id or (p_push_token is not null and push_token = p_push_token));
end;
$$ language plpgsql security definer;


