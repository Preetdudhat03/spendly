-- SQL Script to set up your Supabase database for Spendly (Native Supabase Auth & RLS)
-- Copy and paste this script directly into the SQL Editor on your Supabase Dashboard, then click "Run".

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Profiles Table (Linked to auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_email on public.profiles(email);

-- 2. Families Table
create table if not exists public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  family_code text not null unique,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists idx_families_code on public.families(family_code);

-- 3. Family Members Table
create table if not exists public.family_members (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('admin', 'member')),
  joined_at timestamptz not null default now(),
  unique(family_id, user_id)
);

create index if not exists idx_family_members_user on public.family_members(user_id);
create index if not exists idx_family_members_family on public.family_members(family_id);

-- 4. Expenses Table
create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  amount numeric(12, 2) not null check (amount > 0),
  category text not null,
  description text not null default '',
  payment_method text not null,
  expense_date timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists idx_expenses_family_date on public.expenses(family_id, expense_date desc);

-- 5. Budgets Table
create table if not exists public.budgets (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  monthly_budget numeric(12, 2) not null check (monthly_budget >= 0),
  month integer not null check (month between 1 and 12),
  year integer not null check (year > 2000),
  unique(family_id, month, year)
);

-- 6. Trigger for New User Registration
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do update set
    email = excluded.email,
    display_name = coalesce(profiles.display_name, excluded.display_name);
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert or update on auth.users
  for each row execute procedure public.handle_new_user();

-- 7. Account Deletion RPC
create or replace function public.delete_user_account(target_user_id uuid)
returns void as $$
begin
  if auth.uid() is not null and auth.uid() != target_user_id then
    raise exception 'Unauthorized: You can only delete your own account.';
  end if;

  delete from public.family_members where user_id = target_user_id;
  delete from auth.users where id = target_user_id;
end;
$$ language plpgsql security definer;


