-- Run only on disposable test data after the ordered migrations.
begin;

insert into auth.users (id, email, encrypted_password, email_confirmed_at, banned_until)
values
  ('00000000-0000-0000-0000-000000000101', 'password@example.test', 'fixture', now(), null),
  ('00000000-0000-0000-0000-000000000102', 'google@example.test', null, now(), null),
  ('00000000-0000-0000-0000-000000000103', 'banned@example.test', 'fixture', now(), now() + interval '1 day'),
  ('00000000-0000-0000-0000-000000000104', 'pending@example.test', 'fixture', null, null);

insert into auth.sessions (id, user_id, not_after)
values
  ('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000101', null),
  ('00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000101', null),
  ('00000000-0000-0000-0000-000000000203', '00000000-0000-0000-0000-000000000101', now() - interval '1 second'),
  ('00000000-0000-0000-0000-000000000204', '00000000-0000-0000-0000-000000000103', null);

insert into auth.identities (provider_id, provider, user_id, identity_data)
select id::text, case when email = 'google@example.test' then 'google' else 'email' end,
  id, jsonb_build_object('sub', id, 'email', email)
from auth.users where id::text like '00000000-0000-0000-0000-00000000010%';

do $$
declare
  client_role text;
begin
  if not exists (
    select 1 from storage.buckets
    where id = 'kantin-avatars'
      and not public
      and file_size_limit = 2097152
      and allowed_mime_types = array['image/jpeg']::text[]
  ) or not exists (
    select 1
    from pg_catalog.pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'kantin_avatars_require_backend'
      and permissive = 'RESTRICTIVE'
      and cmd = 'ALL'
      and roles @> array['anon', 'authenticated']::name[]
  ) then
    raise exception 'Avatar bucket or restrictive policy is missing';
  end if;

  foreach client_role in array array['anon', 'authenticated'] loop
    if has_function_privilege(client_role, 'public.kc_auth_session_status(uuid,uuid)', 'execute')
      or has_function_privilege(client_role, 'public.kc_auth_can_recover_password(text)', 'execute')
      or has_function_privilege(client_role, 'public.kc_auth_recovery_link_pending(text,integer)', 'execute')
      or has_function_privilege(client_role, 'public.kc_auth_registration_exists(text)', 'execute') then
      raise exception 'Client role % can call a private auth RPC', client_role;
    end if;
  end loop;
end;
$$;

delete from auth.sessions where id = '00000000-0000-0000-0000-000000000201';

update auth.users
set recovery_token = repeat(left(email, 1), 64), recovery_sent_at = now()
where email in ('password@example.test', 'google@example.test');

set local role service_role;
do $$
declare
  password_user constant uuid := '00000000-0000-0000-0000-000000000101';
  google_user constant uuid := '00000000-0000-0000-0000-000000000102';
  banned_user constant uuid := '00000000-0000-0000-0000-000000000103';
  second_session constant uuid := '00000000-0000-0000-0000-000000000202';
begin
  if public.kc_auth_session_status(password_user, '00000000-0000-0000-0000-000000000201') <> 'invalid'
    or public.kc_auth_session_status(password_user, second_session) <> 'active'
    or public.kc_auth_session_status(google_user, second_session) <> 'invalid'
    or public.kc_auth_session_status(password_user, '00000000-0000-0000-0000-000000000203') <> 'invalid'
    or public.kc_auth_session_status(banned_user, '00000000-0000-0000-0000-000000000204') <> 'inactive' then
    raise exception 'Unexpected session state';
  end if;
  if not public.kc_auth_can_recover_password('password@example.test')
    or public.kc_auth_can_recover_password('google@example.test')
    or public.kc_auth_can_recover_password('banned@example.test')
    or public.kc_auth_can_recover_password('pending@example.test')
    or public.kc_auth_can_recover_password('unknown@example.test') then
    raise exception 'Unexpected password recovery eligibility';
  end if;
  if not public.kc_auth_recovery_link_pending(repeat('p', 64), 3600)
    or public.kc_auth_recovery_link_pending(repeat('g', 64), 3600)
    or public.kc_auth_recovery_link_pending(repeat('x', 64), 3600) then
    raise exception 'Unexpected recovery link eligibility';
  end if;
  if not public.kc_auth_registration_exists('pending@example.test')
    or not public.kc_auth_registration_exists('google@example.test')
    or public.kc_auth_registration_exists('unknown@example.test') then
    raise exception 'Unexpected registration conflict lookup';
  end if;
end;
$$;

reset role;
update auth.users set recovery_sent_at = now() - interval '1 hour'
where email = 'password@example.test';
set local role service_role;
do $$
begin
  if public.kc_auth_recovery_link_pending(repeat('p', 64), 900) then
    raise exception 'Expired recovery link was accepted';
  end if;
end;
$$;

rollback;
