-- Migration SQL for Spendly (Native Supabase Authentication Migration)
-- Execute this script in your Supabase SQL Editor.

-- 1. Drop the foreign key constraints to public.users(id) on existing tables
-- This allows user IDs to be migrated to the new auth.users.id UUIDs.
alter table public.families drop constraint if exists families_created_by_fkey;
alter table public.family_members drop constraint if exists family_members_user_id_fkey;
alter table public.expenses drop constraint if exists expenses_created_by_fkey;

-- 2. Create the Profiles table which links auth.users to custom user metadata
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  legacy_user_id uuid, -- stores reference to old public.users(id)
  email text not null,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  migration_completed boolean not null default false
);

-- Index profiles for search performance
create index if not exists idx_profiles_legacy_user_id on public.profiles(legacy_user_id);
create index if not exists idx_profiles_email on public.profiles(email);

-- Disable Row Level Security (RLS) on profiles to match other tables (Phase 1/2 compatibility)
alter table public.profiles disable row level security;

-- 3. Trigger to auto-create profiles ONLY when the email is confirmed
create or replace function public.handle_new_user()
returns trigger as $$
declare
  legacy_id uuid;
begin
  -- Only create profile if the email is confirmed!
  if new.email_confirmed_at is not null then
    legacy_id := (new.raw_user_meta_data->>'legacy_user_id')::uuid;
    
    insert into public.profiles (id, email, display_name, legacy_user_id, migration_completed)
    values (
      new.id,
      new.email,
      coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
      legacy_id,
      case when legacy_id is null then true else false end -- true for new users, false for migrating users
    )
    on conflict (id) do update set
      email = excluded.email,
      display_name = coalesce(profiles.display_name, excluded.display_name);
  end if;
  return new;
end;
$$ language plpgsql security definer;

-- Bind the trigger function to run on insert or update
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert or update on auth.users
  for each row execute procedure public.handle_new_user();

-- 4. Transactional RPC function to complete legacy user relationship migration atomically
create or replace function public.complete_user_migration(old_user_id uuid, new_user_id uuid)
returns void as $$
declare
  legacy_name text;
  legacy_email text;
begin
  -- Get legacy user name and email
  select display_name, email into legacy_name, legacy_email
  from public.users
  where id = old_user_id;

  -- Update families table
  update public.families
  set created_by = new_user_id
  where created_by = old_user_id;

  -- Clean up any duplicate family member records created by new_user_id during stuck phases
  -- only if we actually have a legacy member row to migrate.
  if exists (select 1 from public.family_members where user_id = old_user_id) then
    delete from public.family_members
    where user_id = new_user_id;
  end if;

  -- Update family_members table
  update public.family_members
  set user_id = new_user_id
  where user_id = old_user_id;

  -- Update expenses table
  update public.expenses
  set created_by = new_user_id
  where created_by = old_user_id;

  -- Upsert profile record to link legacy_user_id, set display name and email, and mark completed
  insert into public.profiles (id, email, display_name, legacy_user_id, migration_completed)
  values (
    new_user_id,
    coalesce(legacy_email, ''),
    coalesce(legacy_name, 'Family Member'),
    old_user_id,
    true
  )
  on conflict (id) do update set
    legacy_user_id = excluded.legacy_user_id,
    migration_completed = true,
    display_name = coalesce(profiles.display_name, excluded.display_name),
    email = coalesce(profiles.email, excluded.email);
end;
$$ language plpgsql security definer;

-- 5. RPC function to delete a user account (supports both legacy and native auth)
create or replace function public.delete_user_account(target_user_id uuid)
returns void as $$
declare
  associated_legacy_id uuid;
begin
  -- Security check: if the request is authenticated via native Supabase Auth,
  -- ensure users can only delete their own account.
  if auth.uid() is not null and auth.uid() != target_user_id then
    raise exception 'Unauthorized: You can only delete your own account.';
  end if;

  -- Find any associated legacy user ID from profiles
  select legacy_user_id into associated_legacy_id
  from public.profiles
  where id = target_user_id;

  -- Delete user from family memberships
  delete from public.family_members where user_id = target_user_id;
  if associated_legacy_id is not null then
    delete from public.family_members where user_id = associated_legacy_id;
  end if;

  -- Delete user from public.users (legacy credentials table)
  delete from public.users where id = target_user_id;
  if associated_legacy_id is not null then
    delete from public.users where id = associated_legacy_id;
  end if;

  -- Delete user from auth.users (this will cascade delete profiles)
  delete from auth.users where id = target_user_id;
end;
$$ language plpgsql security definer;

