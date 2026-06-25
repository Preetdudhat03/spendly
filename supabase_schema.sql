-- SQL Script to set up your Supabase database for Spendly (Custom Authentication)
-- Copy and paste this script directly into the SQL Editor on your Supabase Dashboard, then click "Run".

-- 1. Drop old tables if they exist to clear conflicts or bad foreign keys
drop table if exists public.budgets cascade;
drop table if exists public.expenses cascade;
drop table if exists public.family_members cascade;
drop table if exists public.families cascade;
drop table if exists public.users cascade;

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 2. Create Custom Users Table
-- Since the app uses custom authentication (SHA-256 hashed password in the database),
-- we store and authenticate users in public.users instead of auth.users.
create table public.users (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  password text not null, -- SHA-256 client-side hashed password
  display_name text not null,
  created_at timestamptz not null default now()
);

-- Index for fast user search during login
create index idx_users_email on public.users(email);

-- 3. Create Families Table
create table public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  family_code text not null unique,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Index for family code lookup when joining a family
create index idx_families_code on public.families(family_code);

-- 4. Create Family Members Table
create table public.family_members (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  role text not null check (role in ('admin', 'member')),
  joined_at timestamptz not null default now(),
  unique(family_id, user_id)
);

create index idx_family_members_user on public.family_members(user_id);

-- 5. Create Expenses Table
create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  created_by uuid not null references public.users(id) on delete cascade,
  amount numeric(12, 2) not null check (amount > 0),
  category text not null,
  description text not null default '',
  payment_method text not null,
  expense_date timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index idx_expenses_family_date on public.expenses(family_id, expense_date desc);

-- 6. Create Budgets Table
create table public.budgets (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  monthly_budget numeric(12, 2) not null check (monthly_budget >= 0),
  month integer not null check (month between 1 and 12),
  year integer not null check (year > 2000),
  unique(family_id, month, year)
);

-- 7. Disable Row Level Security (RLS)
-- Since the application performs database transactions anonymously via the anon key (custom authentication),
-- disabling RLS is necessary to grant anonymous users read/write permissions to public schemas.
alter table public.users disable row level security;
alter table public.families disable row level security;
alter table public.family_members disable row level security;
alter table public.expenses disable row level security;
alter table public.budgets disable row level security;
