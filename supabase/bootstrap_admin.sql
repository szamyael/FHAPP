-- FoodHub - Bootstrap Admin Account (Supabase Auth)
--
-- This project uses Supabase Auth (email/password) for sign-in.
-- The app's "account type" is stored in `public.accounts.role`.
--
-- Goal: create an Admin that can sign in as:
--   Username: Admin
--   Password: Admin123
--
-- IMPORTANT
-- - You still must create the Auth user (password lives in Supabase Auth, not in `public.accounts`).
-- - Run this ONLY for prototype/dev. Do NOT ship default credentials.
--
-- Step 1) Create the Auth user (Dashboard)
-- Supabase Dashboard → Authentication → Users → Add user
--   Email:    admin@foodhub.local
--   Password: Admin123
--
-- Step 2) Ensure the `public.accounts` row exists
-- (Normally it is created automatically by the `on_auth_user_created` trigger in `supabase/schema.sql`.)
select id::text as id, email, created_at
from auth.users
where lower(email) = lower('admin@foodhub.local');

-- If the row is missing (for example: user existed before you installed the trigger), create it:
insert into public.accounts (
  id,
  display_name,
  role,
  status,
  credentials_submitted,
  username,
  email,
  email_verified,
  profile
)
select
  u.id::text,
  'Admin',
  'admin',
  'approved',
  true,
  'Admin',
  u.email,
  (u.email_confirmed_at is not null),
  '{}'::jsonb
from auth.users u
where lower(u.email) = lower('admin@foodhub.local')
on conflict (id) do update set
  display_name = excluded.display_name,
  username = excluded.username,
  email = excluded.email;

-- Step 3) Promote + approve (if it already existed)
update public.accounts
set
  display_name = 'Admin',
  username = coalesce(nullif(username, ''), 'Admin'),
  role = 'admin',
  status = 'approved',
  credentials_submitted = true
where lower(email) = lower('admin@foodhub.local');

-- Verify
select id, display_name, username, email, role, status
from public.accounts
where lower(email) = lower('admin@foodhub.local');

-- Step 4) Admin invitation codes (for creating additional admins)
--
-- If you don't see the `invitation_codes` table in Supabase, make sure you've
-- applied the latest schema updates from `supabase/schema.sql`.
--
-- Quick check:
select to_regclass('public.invitation_codes') as invitation_codes_table;

-- Recommended: Sign in to the app as the approved admin, then use:
-- Admin → Dashboard → "Admin invitation code" → Generate code
--
-- Advanced (SQL Editor): emulate an authenticated admin call to the RPC.
-- 1) Find admin auth user id:
--    select id::text from auth.users where lower(email) = lower('admin@foodhub.local');
-- 2) Set the JWT subject to that id for this session:
--    select set_config('request.jwt.claim.sub', '<ADMIN_UUID>', true);
-- 3) Generate a code:
--    select public.admin_generate_invitation_code('admin', 8) as code;
-- 4) Inspect generated codes:
--    select * from public.invitation_codes order by created_at desc limit 25;
