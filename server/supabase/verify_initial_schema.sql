-- Read-only checks for the two initial Kantin Cerdas migrations.
with auth_functions(oid) as (
  values
    (to_regprocedure('public.kc_auth_session_status(uuid,uuid)')),
    (to_regprocedure('public.kc_auth_can_recover_password(text)')),
    (to_regprocedure('public.kc_auth_recovery_link_pending(text,integer)')),
    (to_regprocedure('public.kc_auth_registration_exists(text)'))
), catalog_tables(oid) as (
  values
    (to_regclass('public.catalog_stalls')),
    (to_regclass('public.catalog_menu_items'))
), catalog_functions(oid) as (
  values
    (to_regprocedure('public.kc_catalog_stalls(text,uuid,uuid,integer)')),
    (to_regprocedure('public.kc_catalog_menu(text,uuid,uuid,integer)'))
)
select
  '20261118000001' as versi,
  'auth_initial' as migrasi,
  exists (
    select 1 from storage.buckets
    where id = 'kantin-avatars'
      and not public
      and file_size_limit = 2097152
      and allowed_mime_types = array['image/jpeg']::text[]
  ) and exists (
    select 1
    from pg_catalog.pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'kantin_avatars_require_backend'
      and permissive = 'RESTRICTIVE'
      and cmd = 'ALL'
      and roles @> array['anon', 'authenticated']::name[]
  ) and exists (
    select 1 from pg_catalog.pg_class
    where oid = to_regclass('storage.objects') and relrowsecurity
  ) and not exists (
    select 1
    from auth_functions f
    where f.oid is null
      or not has_function_privilege('service_role', f.oid, 'execute')
      or has_function_privilege('anon', f.oid, 'execute')
      or has_function_privilege('authenticated', f.oid, 'execute')
  ) as siap
union all
select
  '20261118000002',
  'catalog',
  not exists (
    select 1
    from catalog_tables t
    left join pg_catalog.pg_class c on c.oid = t.oid
    where c.oid is null
      or not c.relrowsecurity
      or not has_table_privilege('service_role', c.oid, 'select')
      or has_table_privilege('anon', c.oid, 'select')
      or has_table_privilege('authenticated', c.oid, 'select')
  ) and not exists (
    select 1
    from catalog_functions f
    where f.oid is null
      or not has_function_privilege('service_role', f.oid, 'execute')
      or has_function_privilege('anon', f.oid, 'execute')
      or has_function_privilege('authenticated', f.oid, 'execute')
  )
order by versi;
