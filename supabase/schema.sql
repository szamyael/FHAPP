-- FoodHub (Flutter Web) - Supabase schema
--
-- This is a starter schema that matches the current Flutter app models.
-- For a prototype, you can disable RLS while building.

create extension if not exists pgcrypto;

create table if not exists public.accounts (
  id text primary key,
  display_name text not null,
  role text not null check (role in ('user', 'seller', 'rider', 'admin')),
  status text not null check (status in ('pending', 'approved', 'declined', 'suspended')),
  credentials_submitted boolean not null default false,
  username text,
  email text,
  email_verified boolean not null default false,
  password_salt text,
  password_hash text,
  profile jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Ensure the status check constraint includes 'suspended' even on existing installs.
alter table public.accounts drop constraint if exists accounts_status_check;
alter table public.accounts
  add constraint accounts_status_check
  check (status in ('pending', 'approved', 'declined', 'suspended'));

alter table public.accounts add column if not exists username text;
alter table public.accounts add column if not exists email text;
alter table public.accounts add column if not exists email_verified boolean not null default false;
alter table public.accounts add column if not exists password_salt text;
alter table public.accounts add column if not exists password_hash text;
alter table public.accounts add column if not exists profile jsonb not null default '{}'::jsonb;

create unique index if not exists idx_accounts_username_lower_unique
  on public.accounts (lower(username))
  where username is not null and username <> '';

create unique index if not exists idx_accounts_email_lower_unique
  on public.accounts (lower(email))
  where email is not null and email <> '';

create table if not exists public.products (
  id text primary key,
  seller_id text not null references public.accounts(id) on delete cascade,
  name text not null,
  description text not null,
  price numeric not null,
  stock integer not null,
  expiry_date date not null,
  discount_percent numeric not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id text primary key,
  buyer_id text not null references public.accounts(id),
  seller_id text not null references public.accounts(id),
  rider_id text references public.accounts(id),
  product_id text not null references public.products(id),
  quantity integer not null,
  unit_price numeric not null,
  discount_percent numeric not null default 0,
  created_at timestamptz not null default now(),
  status text not null,
  rating_stars integer,
  constraint rating_stars_range check (rating_stars is null or (rating_stars between 1 and 5))
);

create table if not exists public.messages (
  id text primary key,
  thread_id text not null references public.orders(id) on delete cascade,
  sender_id text not null references public.accounts(id),
  text text not null,
  sent_at timestamptz not null default now()
);

create index if not exists idx_products_seller_id on public.products(seller_id);
create index if not exists idx_orders_buyer_id on public.orders(buyer_id);
create index if not exists idx_orders_seller_id on public.orders(seller_id);
create index if not exists idx_orders_rider_id on public.orders(rider_id);
create index if not exists idx_messages_thread_id on public.messages(thread_id);

-- Supabase Auth integration
--
-- The Flutter app uses Supabase Auth for sign-in/sign-up.
-- Each auth user must have a matching row in public.accounts where:
--   accounts.id = auth.users.id

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta jsonb;
  v_role text;
  v_display_name text;
  v_username text;
  v_credentials_submitted boolean;
  v_profile jsonb;
begin
  meta := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_role := coalesce(nullif(meta->>'role', ''), 'user');
  if v_role not in ('user', 'seller', 'rider', 'admin') then
    v_role := 'user';
  end if;

  v_username := nullif(meta->>'username', '');
  v_display_name := coalesce(
    nullif(meta->>'display_name', ''),
    nullif(meta->>'username', ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'User'
  );

  v_credentials_submitted := coalesce((meta->>'credentials_submitted')::boolean, false);
  v_profile := coalesce(meta->'profile', '{}'::jsonb);

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
  values (
    new.id::text,
    v_display_name,
    v_role,
    'pending',
    v_credentials_submitted,
    v_username,
    new.email,
    (new.email_confirmed_at is not null),
    v_profile
  )
  on conflict (id) do update set
    display_name = excluded.display_name,
    role = excluded.role,
    credentials_submitted = excluded.credentials_submitted,
    username = coalesce(public.accounts.username, excluded.username),
    email = coalesce(public.accounts.email, excluded.email),
    email_verified = public.accounts.email_verified or excluded.email_verified,
    profile = coalesce(public.accounts.profile, excluded.profile);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- RLS (Row Level Security)
--
-- These are prototype-friendly policies: products and accounts are readable to support registration
-- and username-based sign-in. Writes require authenticated users.

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.accounts a
    where a.id = auth.uid()::text
      and a.role = 'admin'
      and a.status = 'approved'
  );
$$;

create or replace function public.is_seller()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.accounts a
    where a.id = auth.uid()::text
      and a.role = 'seller'
      and a.status = 'approved'
  );
$$;

create or replace function public.is_rider()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.accounts a
    where a.id = auth.uid()::text
      and a.role = 'rider'
      and a.status = 'approved'
  );
$$;

alter table public.accounts enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.messages enable row level security;

-- accounts
drop policy if exists "accounts_select_all" on public.accounts;
create policy "accounts_select_all"
on public.accounts
for select
using (true);

drop policy if exists "accounts_update_admin" on public.accounts;
create policy "accounts_update_admin"
on public.accounts
for update
using (public.is_admin())
with check (public.is_admin());

-- products
drop policy if exists "products_select_all" on public.products;
create policy "products_select_all"
on public.products
for select
using (true);

drop policy if exists "products_write_seller_or_admin" on public.products;
create policy "products_write_seller_or_admin"
on public.products
for insert
to authenticated
with check (seller_id = auth.uid()::text or public.is_admin());

drop policy if exists "products_update_seller_or_admin" on public.products;
create policy "products_update_seller_or_admin"
on public.products
for update
to authenticated
using (seller_id = auth.uid()::text or public.is_admin())
with check (seller_id = auth.uid()::text or public.is_admin());

drop policy if exists "products_delete_seller_or_admin" on public.products;
create policy "products_delete_seller_or_admin"
on public.products
for delete
to authenticated
using (seller_id = auth.uid()::text or public.is_admin());

-- orders
drop policy if exists "orders_select_participants" on public.orders;
create policy "orders_select_participants"
on public.orders
for select
to authenticated
using (
  public.is_admin()
  or buyer_id = auth.uid()::text
  or seller_id = auth.uid()::text
  or rider_id = auth.uid()::text
);

-- Allow approved riders to see unassigned orders that are ready for pickup.
drop policy if exists "orders_select_available_to_riders" on public.orders;
create policy "orders_select_available_to_riders"
on public.orders
for select
to authenticated
using (
  public.is_rider()
  and rider_id is null
  and status = 'confirmedAwaitingPickup'
);

drop policy if exists "orders_insert_buyer" on public.orders;
create policy "orders_insert_buyer"
on public.orders
for insert
to authenticated
with check (buyer_id = auth.uid()::text);

drop policy if exists "orders_update_participants" on public.orders;
create policy "orders_update_participants"
on public.orders
for update
to authenticated
using (
  public.is_admin()
  or buyer_id = auth.uid()::text
  or seller_id = auth.uid()::text
  or rider_id = auth.uid()::text
)
with check (
  public.is_admin()
  or buyer_id = auth.uid()::text
  or seller_id = auth.uid()::text
  or rider_id = auth.uid()::text
);

-- Allow riders to claim an unassigned order once it's ready for pickup.
drop policy if exists "orders_update_claim_rider" on public.orders;
create policy "orders_update_claim_rider"
on public.orders
for update
to authenticated
using (
  public.is_rider()
  and rider_id is null
  and status = 'confirmedAwaitingPickup'
)
with check (
  rider_id = auth.uid()::text
  and status = 'confirmedAwaitingPickup'
);

drop policy if exists "orders_delete_admin" on public.orders;
create policy "orders_delete_admin"
on public.orders
for delete
to authenticated
using (public.is_admin());

-- messages
drop policy if exists "messages_select_participants" on public.messages;
create policy "messages_select_participants"
on public.messages
for select
to authenticated
using (
  exists (
    select 1
    from public.orders o
    where o.id = thread_id
      and (
        public.is_admin()
        or o.buyer_id = auth.uid()::text
        or o.seller_id = auth.uid()::text
        or o.rider_id = auth.uid()::text
      )
  )
);

drop policy if exists "messages_insert_participants" on public.messages;
create policy "messages_insert_participants"
on public.messages
for insert
to authenticated
with check (
  sender_id = auth.uid()::text
  and exists (
    select 1
    from public.orders o
    where o.id = thread_id
      and (
        public.is_admin()
        or o.buyer_id = auth.uid()::text
        or o.seller_id = auth.uid()::text
        or o.rider_id = auth.uid()::text
      )
  )
);

drop policy if exists "messages_delete_admin" on public.messages;
create policy "messages_delete_admin"
on public.messages
for delete
to authenticated
using (public.is_admin());

-- RPC helpers for role dashboards (safe, minimal writes)

create or replace function public.set_store_open(p_is_open boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_seller() then
    raise exception 'not authorized';
  end if;

  update public.accounts
  set profile = jsonb_set(
    coalesce(profile, '{}'::jsonb),
    '{store,is_open}',
    to_jsonb(coalesce(p_is_open, false)),
    true
  )
  where id = auth.uid()::text;
end;
$$;

create or replace function public.set_rider_online(p_is_online boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_rider() then
    raise exception 'not authorized';
  end if;

  update public.accounts
  set profile = jsonb_set(
    coalesce(profile, '{}'::jsonb),
    '{rider,is_online}',
    to_jsonb(coalesce(p_is_online, false)),
    true
  )
  where id = auth.uid()::text;
end;
$$;

create or replace function public.admin_set_seller_commission_rate(
  p_seller_id text,
  p_rate numeric
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  update public.accounts
  set profile = jsonb_set(
    coalesce(profile, '{}'::jsonb),
    '{commission,rate}',
    to_jsonb(p_rate),
    true
  )
  where id = p_seller_id;
end;
$$;

grant execute on function public.set_store_open(boolean) to authenticated;
grant execute on function public.set_rider_online(boolean) to authenticated;
grant execute on function public.admin_set_seller_commission_rate(text, numeric) to authenticated;

-- Registration finalization + admin invitation codes

create table if not exists public.invitation_codes (
  id uuid primary key default gen_random_uuid(),
  role text not null check (role in ('admin')),
  code text not null,
  created_by text not null references public.accounts(id) on delete cascade,
  created_at timestamptz not null default now(),
  used_by text references public.accounts(id),
  used_at timestamptz
);

create unique index if not exists idx_invitation_codes_code_unique
  on public.invitation_codes (code);

create index if not exists idx_invitation_codes_role_unused
  on public.invitation_codes (role, created_at)
  where used_by is null;

alter table public.invitation_codes enable row level security;

-- RLS policies for invitation codes.
--
-- The app primarily uses SECURITY DEFINER RPCs for generating and consuming
-- codes, but policies make the system more resilient across environments and
-- allow safe client-side fallbacks.
drop policy if exists "invitation_codes_insert_admin" on public.invitation_codes;
create policy "invitation_codes_insert_admin"
on public.invitation_codes
for insert
with check (
  auth.uid() is not null
  and public.is_admin()
  and role = 'admin'
  and created_by = auth.uid()::text
  and used_by is null
);

drop policy if exists "invitation_codes_consume_admin" on public.invitation_codes;
create policy "invitation_codes_consume_admin"
on public.invitation_codes
for update
using (
  auth.uid() is not null
  and role = 'admin'
  and used_by is null
)
with check (
  auth.uid() is not null
  and role = 'admin'
  and used_by = auth.uid()::text
);

create or replace function public.admin_generate_invitation_code(
  p_role text,
  p_length int
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text;
  v_length int;
  v_code text;
  tries int := 0;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  v_role := coalesce(nullif(p_role, ''), 'admin');
  if v_role <> 'admin' then
    raise exception 'unsupported role';
  end if;

  v_length := coalesce(p_length, 8);
  if v_length <> 8 then
    raise exception 'invalid length';
  end if;

  loop
    tries := tries + 1;
    v_code := upper(encode(gen_random_bytes(4), 'hex'));
    begin
      insert into public.invitation_codes (role, code, created_by)
      values (v_role, v_code, auth.uid()::text);
      exit;
    exception when unique_violation then
      if tries > 5 then
        raise exception 'unable to generate unique code';
      end if;
    end;
  end loop;

  return v_code;
end;
$$;

create or replace function public.finalize_registration(
  p_role text,
  p_display_name text,
  p_credentials_submitted boolean,
  p_profile jsonb,
  p_admin_invitation_code text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid text;
  v_role text;
  v_email_confirmed_at timestamptz;
  v_status text;
  v_display_name text;
begin
  v_uid := auth.uid()::text;
  if v_uid is null or v_uid = '' then
    raise exception 'not authenticated';
  end if;

  v_role := coalesce(nullif(p_role, ''), 'user');
  if v_role not in ('user', 'seller', 'rider', 'admin') then
    raise exception 'invalid role';
  end if;

  select u.email_confirmed_at
  into v_email_confirmed_at
  from auth.users u
  where u.id::text = v_uid;

  if v_email_confirmed_at is null then
    raise exception 'email not verified';
  end if;

  if v_role = 'admin' then
    if coalesce(nullif(p_admin_invitation_code, ''), '') = '' then
      raise exception 'invitation code required';
    end if;

    update public.invitation_codes
    set used_by = v_uid,
        used_at = now()
    where role = 'admin'
      and code = upper(p_admin_invitation_code)
      and used_by is null;

    if not found then
      raise exception 'invalid invitation code';
    end if;

    v_status := 'approved';
  elsif v_role = 'user' then
    v_status := 'approved';
  else
    v_status := 'pending';
  end if;

  v_display_name := nullif(coalesce(p_display_name, ''), '');

  update public.accounts
  set display_name = coalesce(v_display_name, public.accounts.display_name),
      role = v_role,
      status = v_status,
      credentials_submitted = coalesce(p_credentials_submitted, false),
      email_verified = true,
      profile = coalesce(p_profile, '{}'::jsonb)
  where id = v_uid;

  if not found then
    raise exception 'account row not found';
  end if;
end;
$$;

grant execute on function public.admin_generate_invitation_code(text, int) to authenticated;
grant execute on function public.finalize_registration(text, text, boolean, jsonb, text) to authenticated;
