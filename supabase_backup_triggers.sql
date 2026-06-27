-- SQL Script to create backup tables and synchronization triggers for Spendly.
-- Run this in your Supabase SQL Editor.

-- 1. Create Backup Tables with exact same structures
CREATE TABLE IF NOT EXISTS public.users_backup (LIKE public.users INCLUDING ALL);
CREATE TABLE IF NOT EXISTS public.families_backup (LIKE public.families INCLUDING ALL);
CREATE TABLE IF NOT EXISTS public.family_members_backup (LIKE public.family_members INCLUDING ALL);
CREATE TABLE IF NOT EXISTS public.expenses_backup (LIKE public.expenses INCLUDING ALL);
CREATE TABLE IF NOT EXISTS public.budgets_backup (LIKE public.budgets INCLUDING ALL);
CREATE TABLE IF NOT EXISTS public.profiles_backup (LIKE public.profiles INCLUDING ALL);

-- Remove foreign key constraints from backup tables so they don't break if original rows are deleted
ALTER TABLE public.families_backup DROP CONSTRAINT IF EXISTS families_created_by_fkey CASCADE;
ALTER TABLE public.family_members_backup DROP CONSTRAINT IF EXISTS family_members_user_id_fkey CASCADE;
ALTER TABLE public.family_members_backup DROP CONSTRAINT IF EXISTS family_members_family_id_fkey CASCADE;
ALTER TABLE public.expenses_backup DROP CONSTRAINT IF EXISTS expenses_created_by_fkey CASCADE;
ALTER TABLE public.expenses_backup DROP CONSTRAINT IF EXISTS expenses_family_id_fkey CASCADE;
ALTER TABLE public.budgets_backup DROP CONSTRAINT IF EXISTS budgets_family_id_fkey CASCADE;
ALTER TABLE public.profiles_backup DROP CONSTRAINT IF EXISTS profiles_id_fkey CASCADE;


-- 2. Create Synchronization Functions for each table
-- users
CREATE OR REPLACE FUNCTION sync_users_backup() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.users_backup SELECT NEW.*;
    ELSIF TG_OP = 'UPDATE' THEN
        DELETE FROM public.users_backup WHERE id = OLD.id;
        INSERT INTO public.users_backup SELECT NEW.*;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- families
CREATE OR REPLACE FUNCTION sync_families_backup() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.families_backup SELECT NEW.*;
    ELSIF TG_OP = 'UPDATE' THEN
        DELETE FROM public.families_backup WHERE id = OLD.id;
        INSERT INTO public.families_backup SELECT NEW.*;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- family_members
CREATE OR REPLACE FUNCTION sync_family_members_backup() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.family_members_backup SELECT NEW.*;
    ELSIF TG_OP = 'UPDATE' THEN
        DELETE FROM public.family_members_backup WHERE id = OLD.id;
        INSERT INTO public.family_members_backup SELECT NEW.*;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- expenses
CREATE OR REPLACE FUNCTION sync_expenses_backup() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.expenses_backup SELECT NEW.*;
    ELSIF TG_OP = 'UPDATE' THEN
        DELETE FROM public.expenses_backup WHERE id = OLD.id;
        INSERT INTO public.expenses_backup SELECT NEW.*;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- budgets
CREATE OR REPLACE FUNCTION sync_budgets_backup() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.budgets_backup SELECT NEW.*;
    ELSIF TG_OP = 'UPDATE' THEN
        DELETE FROM public.budgets_backup WHERE id = OLD.id;
        INSERT INTO public.budgets_backup SELECT NEW.*;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- profiles
CREATE OR REPLACE FUNCTION sync_profiles_backup() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.profiles_backup SELECT NEW.*;
    ELSIF TG_OP = 'UPDATE' THEN
        DELETE FROM public.profiles_backup WHERE id = OLD.id;
        INSERT INTO public.profiles_backup SELECT NEW.*;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Attach Triggers to original tables (Notice we removed "OR DELETE")
DROP TRIGGER IF EXISTS trg_users_backup ON public.users;
CREATE TRIGGER trg_users_backup AFTER INSERT OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION sync_users_backup();

DROP TRIGGER IF EXISTS trg_families_backup ON public.families;
CREATE TRIGGER trg_families_backup AFTER INSERT OR UPDATE ON public.families FOR EACH ROW EXECUTE FUNCTION sync_families_backup();

DROP TRIGGER IF EXISTS trg_family_members_backup ON public.family_members;
CREATE TRIGGER trg_family_members_backup AFTER INSERT OR UPDATE ON public.family_members FOR EACH ROW EXECUTE FUNCTION sync_family_members_backup();

DROP TRIGGER IF EXISTS trg_expenses_backup ON public.expenses;
CREATE TRIGGER trg_expenses_backup AFTER INSERT OR UPDATE ON public.expenses FOR EACH ROW EXECUTE FUNCTION sync_expenses_backup();

DROP TRIGGER IF EXISTS trg_budgets_backup ON public.budgets;
CREATE TRIGGER trg_budgets_backup AFTER INSERT OR UPDATE ON public.budgets FOR EACH ROW EXECUTE FUNCTION sync_budgets_backup();

DROP TRIGGER IF EXISTS trg_profiles_backup ON public.profiles;
CREATE TRIGGER trg_profiles_backup AFTER INSERT OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION sync_profiles_backup();

-- 4. Initial Copy of existing data to backup tables (Optional, if tables already contain data)
-- This assumes backup tables are currently empty
INSERT INTO public.users_backup SELECT * FROM public.users ON CONFLICT DO NOTHING;
INSERT INTO public.families_backup SELECT * FROM public.families ON CONFLICT DO NOTHING;
INSERT INTO public.family_members_backup SELECT * FROM public.family_members ON CONFLICT DO NOTHING;
INSERT INTO public.expenses_backup SELECT * FROM public.expenses ON CONFLICT DO NOTHING;
INSERT INTO public.budgets_backup SELECT * FROM public.budgets ON CONFLICT DO NOTHING;
INSERT INTO public.profiles_backup SELECT * FROM public.profiles ON CONFLICT DO NOTHING;
