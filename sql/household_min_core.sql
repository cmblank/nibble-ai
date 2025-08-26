-- Minimal Household Sharing Core Schema for Integration Tests
-- Run this in the Supabase SQL editor (or via supabase db execute) BEFORE running the Flutter integration test.
-- It creates only the tables / policies / functions required by integration_test/household_integration_flow_test.dart
-- Safe to re-run (uses IF NOT EXISTS / CREATE OR REPLACE where feasible). Adjust ownership or additional policies as needed.

create extension if not exists pgcrypto;

-- Core tables
create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.household_invites (
  code text primary key,
  household_id uuid not null references public.households(id) on delete cascade,
  invited_email text not null,
  created_by uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','revoked','expired')),
  expires_at timestamptz not null default (now() + interval '7 days'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.household_members (
  id bigserial primary key,
  household_id uuid not null references public.households(id) on delete cascade,
  user_email text not null,
  user_id uuid references auth.users(id) on delete cascade,
  invite_code text references public.household_invites(code) on delete set null,
  role text not null default 'member' check (role in ('owner','member')),
  added_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists household_members_unique_email on public.household_members(household_id, lower(user_email));
create unique index if not exists household_members_unique_user on public.household_members(household_id, user_id) where user_id is not null;

-- Timestamp helper
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;

drop trigger if exists set_updated_at_households on public.households;
create trigger set_updated_at_households before update on public.households for each row execute procedure public.set_updated_at();
drop trigger if exists set_updated_at_household_invites on public.household_invites;
create trigger set_updated_at_household_invites before update on public.household_invites for each row execute procedure public.set_updated_at();
drop trigger if exists set_updated_at_household_members on public.household_members;
create trigger set_updated_at_household_members before update on public.household_members for each row execute procedure public.set_updated_at();

-- Enable RLS
alter table public.households enable row level security;
alter table public.household_invites enable row level security;
alter table public.household_members enable row level security;

-- NOTE: PostgreSQL does not support IF NOT EXISTS for CREATE POLICY; emulate idempotency with DROP POLICY IF EXISTS then CREATE POLICY.
drop policy if exists households_owner_select on public.households;
create policy households_owner_select on public.households for select using (auth.uid() = owner_id);
-- Replace monolithic ALL policy with granular policies permitting ownership transfer (owner can update row even if new owner_id differs)
drop policy if exists households_owner_all on public.households; -- legacy
drop policy if exists households_owner_insert on public.households;
drop policy if exists households_owner_update on public.households;
drop policy if exists households_owner_delete on public.households;
create policy households_owner_insert on public.households for insert with check (auth.uid() = owner_id);
create policy households_owner_update on public.households for update using (auth.uid() = owner_id) with check (true);
create policy households_owner_delete on public.households for delete using (auth.uid() = owner_id);

drop policy if exists household_invites_select_owner on public.household_invites;
create policy household_invites_select_owner on public.household_invites for select using ( auth.uid() = created_by );
drop policy if exists household_invites_select_invited on public.household_invites;
create policy household_invites_select_invited on public.household_invites for select using ( status = 'pending' and lower(invited_email) = lower(auth.email()) and now() < expires_at );
-- New: allow any existing household member (by membership) to view invites for that household (needed for accepted invite visibility after ownership transfer)
drop policy if exists household_invites_select_member on public.household_invites;
create policy household_invites_select_member on public.household_invites for select using (
  exists (
    select 1 from public.household_members m
    where m.household_id = household_id
      and (m.user_id = auth.uid() or lower(m.user_email)=lower(auth.email()))
  )
);
drop policy if exists household_invites_insert_owner on public.household_invites;
create policy household_invites_insert_owner on public.household_invites for insert with check ( created_by = auth.uid() AND (select owner_id from public.households h where h.id = household_id) = auth.uid() );
-- Consolidated update policy: owner OR invited pending user may update (e.g., accept). Owner can update any of their rows; invited user only their pending invite transitioning to accepted.
drop policy if exists household_invites_update_owner on public.household_invites; -- legacy name
drop policy if exists household_invites_accept_invited on public.household_invites; -- legacy name
drop policy if exists household_invites_update_combined on public.household_invites;
create policy household_invites_update_combined on public.household_invites for update
  using (
    created_by = auth.uid()
    OR (
      status = 'pending'
      and lower(invited_email) = lower(auth.email())
      and now() < expires_at
    )
  )
  with check (
    created_by = auth.uid()
    OR (
      lower(invited_email) = lower(auth.email())
      and status in ('accepted','pending')
    )
  );
drop policy if exists household_invites_delete_owner on public.household_invites;
create policy household_invites_delete_owner on public.household_invites for delete using ( created_by = auth.uid() );

-- Reverted: original select policy (owner sees all rows; non-owner sees only own row) to avoid recursion.
drop policy if exists household_members_select on public.household_members;
create policy household_members_select on public.household_members for select using (
  (select owner_id from public.households h where h.id = household_id) = auth.uid()
  or lower(user_email)=lower(auth.email())
);
drop policy if exists household_members_insert on public.household_members;
create policy household_members_insert on public.household_members for insert with check ( (select owner_id from public.households h where h.id = household_id) = auth.uid() or lower(user_email) = lower(auth.email()) );
drop policy if exists household_members_update_owner on public.household_members;
create policy household_members_update_owner on public.household_members for update using ( (select owner_id from public.households h where h.id = household_id) = auth.uid() ) with check ( (select owner_id from public.households h where h.id = household_id) = auth.uid() );
drop policy if exists household_members_delete on public.household_members;
create policy household_members_delete on public.household_members for delete using ( (select owner_id from public.households h where h.id = household_id) = auth.uid() or lower(user_email) = lower(auth.email()) );

-- Audit (minimal) --------------------------------------------------------
create table if not exists public.household_audit (
  id bigserial primary key,
  household_id uuid not null references public.households(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  details jsonb,
  created_at timestamptz not null default now()
);
alter table public.household_audit enable row level security;
drop policy if exists household_audit_select on public.household_audit;
create policy household_audit_select ON public.household_audit FOR SELECT USING (
  exists (select 1 from public.household_members m where m.household_id = household_id and (m.user_id = auth.uid() or lower(m.user_email)=lower(auth.email())))
);

create or replace function public.household_audit_log(p_household_id uuid, p_action text, p_details jsonb DEFAULT '{}'::jsonb)
returns void language plpgsql security definer as $$
begin
  insert into public.household_audit(household_id, actor_user_id, action, details)
  values (p_household_id, auth.uid(), p_action, p_details);
end;$$;
revoke all on function public.household_audit_log(uuid,text,jsonb) from public;
grant execute on function public.household_audit_log(uuid,text,jsonb) to authenticated;

-- Helper used by resend in client
create or replace function public.bump_invite_timestamp(p_code text)
returns void language plpgsql security definer as $$
begin
  update public.household_invites set updated_at = now() where code = p_code and created_by = auth.uid() and status = 'pending';
end;$$;
revoke all on function public.bump_invite_timestamp(text) from public;
grant execute on function public.bump_invite_timestamp(text) to authenticated;

-- Status regression guard (prevents accepted/revoked/expired reverting to pending)
create or replace function public.enforce_invite_status_guard()
returns trigger language plpgsql as $$
begin
  if tg_op = 'UPDATE' then
    if old.status <> new.status then
      if old.status in ('accepted','revoked','expired') then
        raise exception 'Cannot change status from terminal state %', old.status;
      end if;
      if old.status = 'pending' and new.status not in ('pending','accepted','revoked','expired') then
        raise exception 'Invalid transition from % to %', old.status, new.status;
      end if;
    end if;
  end if;
  return new;
end;$$;
drop trigger if exists household_invites_status_guard on public.household_invites;
create trigger household_invites_status_guard
before update on public.household_invites
for each row execute function public.enforce_invite_status_guard();

-- Pending invite limit (enforces max pending count per household)
create or replace function public.enforce_household_pending_invite_limit()
returns trigger language plpgsql as $$
declare v_count int; begin
  if new.status = 'pending' then
    select count(*) into v_count from public.household_invites where household_id = new.household_id and status = 'pending';
    if v_count >= 10 then
      raise exception 'Household pending invite limit (10) reached';
    end if;
  end if;
  return new;
end;$$;
drop trigger if exists household_invites_limit on public.household_invites;
create trigger household_invites_limit before insert on public.household_invites for each row execute function public.enforce_household_pending_invite_limit();

-- Accept invite helper (security definer) to perform atomic accept + member add under RLS
create or replace function public.accept_household_invite(p_code text)
returns boolean language plpgsql security definer as $$
declare
  v_invite public.household_invites%rowtype;
  v_member_exists int;
begin
  select * into v_invite
  from public.household_invites
  where code = p_code
    and status = 'pending'
    and now() < expires_at
    and lower(invited_email) = lower(auth.email())
  limit 1;
  if not found then
    return false;
  end if;
  -- Transition to accepted (status guard trigger allows pending -> accepted)
  update public.household_invites set status='accepted' where code = p_code;
  -- Ensure member row exists (idempotent)
  select count(*) into v_member_exists from public.household_members
   where household_id = v_invite.household_id and lower(user_email)=lower(v_invite.invited_email);
  if v_member_exists = 0 then
    insert into public.household_members(household_id,user_email,user_id,invite_code,role,added_by)
    values (v_invite.household_id, v_invite.invited_email, auth.uid(), p_code, 'member', v_invite.created_by);
  else
    -- Backfill user_id if an existing placeholder member row lacks it
    update public.household_members
      set user_id = coalesce(user_id, auth.uid())
      where household_id = v_invite.household_id
        and lower(user_email) = lower(v_invite.invited_email)
        and user_id is null;
  end if;
  begin
    perform public.household_audit_log(v_invite.household_id,'invite_accepted', jsonb_build_object('code',p_code,'member_email',v_invite.invited_email));
  exception when others then
    -- swallow audit errors
    null;
  end;
  return true;
end;$$;
revoke all on function public.accept_household_invite(text) from public;
grant execute on function public.accept_household_invite(text) to authenticated;

-- Backfill member user_id by email (used during ownership transfer if legacy rows lack user_id)
create or replace function public.backfill_member_user_id(p_household_id uuid, p_email text)
returns boolean language plpgsql security definer as $$
declare
  v_uid uuid;
  v_updated int;
begin
  select id into v_uid from auth.users where lower(email)=lower(p_email) limit 1;
  if v_uid is null then
    return false; -- no matching auth user
  end if;
  update public.household_members
    set user_id = v_uid
    where household_id = p_household_id
      and lower(user_email)=lower(p_email)
      and user_id is null;
  get diagnostics v_updated = row_count;
  if v_updated > 0 then
    begin
      perform public.household_audit_log(p_household_id,'member_user_id_backfilled', jsonb_build_object('email',p_email));
    exception when others then null; end;
    return true;
  end if;
  return false;
end;$$;
revoke all on function public.backfill_member_user_id(uuid,text) from public;
grant execute on function public.backfill_member_user_id(uuid,text) to authenticated;

-- Atomic ownership transfer (demote current owner, promote target) before changing households.owner_id
create or replace function public.transfer_household_ownership(p_household_id uuid, p_target_email text)
returns boolean language plpgsql security definer as $$
declare
  v_current_owner uuid;
  v_target_member record;
  v_target_user_id uuid;
begin
  -- Verify caller is current owner
  select owner_id into v_current_owner from public.households where id = p_household_id;
  if v_current_owner is null or v_current_owner <> auth.uid() then
    return false; -- not authorized
  end if;
  -- Locate target member row
  select * into v_target_member from public.household_members
    where household_id = p_household_id and lower(user_email)=lower(p_target_email)
  limit 1;
  if not found then
    return false; -- no such member
  end if;
  v_target_user_id := v_target_member.user_id;
  if v_target_user_id is null then
    select id into v_target_user_id from auth.users where lower(email)=lower(p_target_email) limit 1;
    if v_target_user_id is not null then
      update public.household_members set user_id = v_target_user_id
        where id = v_target_member.id and user_id is null; -- backfill
    end if;
  end if;
  if v_target_user_id is null then
    return false; -- cannot transfer to member without user_id
  end if;
  -- Update member roles first while caller is still owner
  update public.household_members set role='member'
    where household_id = p_household_id and role='owner';
  update public.household_members set role='owner'
    where id = v_target_member.id;
  -- Finally update household owner_id
  update public.households set owner_id = v_target_user_id
    where id = p_household_id and owner_id = v_current_owner;
  if not found then
    return false; -- concurrent change
  end if;
  begin
    perform public.household_audit_log(p_household_id,'ownership_transferred', jsonb_build_object('to_email', p_target_email));
  exception when others then null; end;
  return true;
end;$$;
revoke all on function public.transfer_household_ownership(uuid,text) from public;
grant execute on function public.transfer_household_ownership(uuid,text) to authenticated;

-- DONE. Optional verification:
-- select * from public.household_invites limit 1;
