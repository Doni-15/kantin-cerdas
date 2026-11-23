-- Initial Authentication migration for Kantin Cerdas.
-- Supabase Auth and Storage already exist in a hosted project.
begin;

-- =============================================================================
-- 1. Private avatar storage bucket and restrictive RLS policy
-- =============================================================================
-- Profile photos are reachable only through authenticated Shelf routes.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('kantin-avatars', 'kantin-avatars', false, 2097152, array['image/jpeg'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy kantin_avatars_require_backend
on storage.objects
as restrictive
for all
to anon, authenticated
using (bucket_id <> 'kantin-avatars')
with check (bucket_id <> 'kantin-avatars');

-- =============================================================================
-- 2. Session status and account ban check
-- =============================================================================
-- Shelf calls this after Supabase Auth has authenticated the bearer.
create function public.kc_auth_session_status(p_user_id uuid, p_session_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select case
      when u.banned_until > now() then 'inactive'
      when s.id is null or s.not_after <= now() then 'invalid'
      else 'active'
    end
    from auth.users as u
    left join auth.sessions as s
      on s.user_id = u.id and s.id = p_session_id
    where u.id = p_user_id
  ), 'invalid')
$$;

revoke all on function public.kc_auth_session_status(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.kc_auth_session_status(uuid, uuid)
  to service_role;

-- =============================================================================
-- 3. Password recovery eligibility check
-- =============================================================================
-- A recovery request must not add a password to a Google-only account.
create function public.kc_auth_can_recover_password(p_email text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from auth.users as u
    where lower(u.email) = p_email
      and coalesce(u.encrypted_password, '') <> ''
      and u.email_confirmed_at is not null
      and (u.banned_until is null or u.banned_until <= now())
      and exists (
        select 1 from auth.identities as i
        where i.user_id = u.id and i.provider = 'email'
      )
  )
$$;

revoke all on function public.kc_auth_can_recover_password(text)
  from public, anon, authenticated;
grant execute on function public.kc_auth_can_recover_password(text)
  to service_role;

-- =============================================================================
-- 4. Pending recovery link validation (depends on kc_auth_can_recover_password)
-- =============================================================================
-- Shelf checks whether to open the password form without consuming the link.
-- Supabase Auth still verifies and consumes the token when saving the password.
create function public.kc_auth_recovery_link_pending(p_token_hash text, p_ttl_seconds integer)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select pg_catalog.length(p_token_hash) between 32 and 256
    and p_token_hash ~ '^[A-Za-z0-9_-]+$'
    and p_ttl_seconds between 1 and 86400
    and exists (
      select 1
      from auth.users as u
      where u.recovery_token = p_token_hash
        and u.recovery_sent_at >= now() - pg_catalog.make_interval(secs => p_ttl_seconds)
        and public.kc_auth_can_recover_password(lower(u.email))
    )
$$;

revoke all on function public.kc_auth_recovery_link_pending(text, integer)
  from public, anon, authenticated;
grant execute on function public.kc_auth_recovery_link_pending(text, integer)
  to service_role;

-- =============================================================================
-- 5. Concurrent registration conflict check
-- =============================================================================
-- GoTrue can return an ambiguous database error when a concurrent signup wins.
-- Shelf checks the resulting state before returning its usual neutral response.
create function public.kc_auth_registration_exists(p_email text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from auth.users as u
    where lower(u.email) = p_email
  )
$$;

revoke all on function public.kc_auth_registration_exists(text)
  from public, anon, authenticated;
grant execute on function public.kc_auth_registration_exists(text)
  to service_role;

commit;
