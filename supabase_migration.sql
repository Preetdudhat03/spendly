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
begin
  -- Update families table
  update public.families
  set created_by = new_user_id
  where created_by = old_user_id;

  -- Update family_members table
  update public.family_members
  set user_id = new_user_id
  where user_id = old_user_id;

  -- Update expenses table
  update public.expenses
  set created_by = new_user_id
  where created_by = old_user_id;

  -- Update profile record to link legacy_user_id and mark completed
  update public.profiles
  set legacy_user_id = old_user_id,
      migration_completed = true
  where id = new_user_id;
end;
$$ language plpgsql security definer;
