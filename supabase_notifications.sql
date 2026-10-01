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
  family_id in (select public.get_user_family_ids(auth.uid()))
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

-- Enable Realtime publication for notifications table
alter publication supabase_realtime add table public.notifications;
