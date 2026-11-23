-- SQL verification suite for AI Food Assistant (AI-001..AI-006B, AI-TECH-001).
begin;

-- 1. Verify anon/authenticated have zero privileges on AI tables & RPCs.
do $$
declare
  client_role text;
begin
  foreach client_role in array array['anon', 'authenticated'] loop
    if has_table_privilege(client_role, 'public.ai_daily_usage', 'select')
       or has_table_privilege(client_role, 'public.ai_daily_usage', 'insert')
       or has_table_privilege(client_role, 'public.ai_project_daily_usage', 'select')
       or has_table_privilege(client_role, 'public.ai_call_attempts', 'select')
       or has_function_privilege(client_role, 'public.kc_ai_get_quota_status(uuid,integer,integer,timestamptz)', 'execute')
       or has_function_privilege(client_role, 'public.kc_ai_reserve_call(uuid,text,text,integer,integer,timestamptz)', 'execute')
       or has_function_privilege(client_role, 'public.kc_ai_search_catalog(text,integer,boolean,integer)', 'execute')
       or has_function_privilege(client_role, 'public.kc_ai_verify_menu_candidates(uuid[],integer,boolean)', 'execute') then
      raise exception 'Unexpected AI privilege for role %', client_role;
    end if;
  end loop;
end;
$$;

-- 2. Seed users: GoTrue-style Customer (missing kantin_role defaults to customer), Admin, Active Owner, Inactive Owner, Closed Owner.
insert into auth.users (id, email, email_confirmed_at, raw_app_meta_data, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000b001', 'ai-cust@example.test', now(), '{"provider":"email"}', '{"display_name":"Ai Customer"}'),
  ('00000000-0000-0000-0000-00000000b002', 'ai-admin@example.test', now(), '{"kantin_role":"admin"}', '{"display_name":"Ai Admin"}'),
  ('00000000-0000-0000-0000-00000000b101', 'ai-own1@example.test', now(), '{"kantin_role":"owner"}', '{"display_name":"Owner Aktif"}'),
  ('00000000-0000-0000-0000-00000000b102', 'ai-own2@example.test', now(), '{"kantin_role":"owner"}', '{"display_name":"Owner Tutup"}');

set local role service_role;

do $$
declare
  v_cust constant uuid := '00000000-0000-0000-0000-00000000b001';
  v_admin constant uuid := '00000000-0000-0000-0000-00000000b002';
  v_own1 constant uuid := '00000000-0000-0000-0000-00000000b101';
  v_own2 constant uuid := '00000000-0000-0000-0000-00000000b102';

  v_stall1 uuid;
  v_cat1 uuid;
  v_menu_cheap uuid;
  v_menu_expensive uuid;
  v_menu_habis uuid;
  v_menu_archived uuid;

  v_stall2 uuid;
  v_cat2 uuid;
  v_menu_closed uuid;

  v_day1_end constant timestamptz := '2026-11-22T16:59:59Z'; -- 2026-11-22 23:59:59 WIB
  v_day2_start constant timestamptz := '2026-11-22T17:00:00Z'; -- 2026-11-23 00:00:00 WIB

  v_status jsonb;
  v_res jsonb;
  v_att uuid;
  v_att_fail uuid;
  v_att_uncertain uuid;
  v_search jsonb;
  v_verified jsonb;
  v_err text;
  i integer;
begin
  -- Set up stall 1 (published, open, active owner) with cheap, expensive, habis, archived menus.
  perform public.kc_owner_create_stall(v_own1, 'Kantin Segar', 'USU', 'Blok A-1', 'Bersih', 10);
  select id into v_stall1 from public.catalog_stalls where owner_id = v_own1;
  select id into v_cat1 from public.owner_menu_categories where stall_id = v_stall1 limit 1;

  v_menu_cheap := (public.kc_owner_create_menu(v_own1, 'Nasi Ayam Geprek', v_cat1, 18000, true, 'Pedas gurih')->>'id')::uuid;
  v_menu_expensive := (public.kc_owner_create_menu(v_own1, 'Ayam Bakar Jumbo', v_cat1, 25000, true, 'Pedas manis')->>'id')::uuid;
  v_menu_habis := (public.kc_owner_create_menu(v_own1, 'Ayam Penyet Spesial', v_cat1, 19000, false, 'Habis sementara')->>'id')::uuid;
  v_menu_archived := (public.kc_owner_create_menu(v_own1, 'Ayam Arsip Lama', v_cat1, 15000, true, '')->>'id')::uuid;
  perform public.kc_owner_publish_stall(v_own1);
  perform public.kc_owner_set_stall_open(v_own1, true);
  perform public.kc_owner_archive_menu(v_own1, v_menu_archived);

  -- Set up stall 2 (published, closed).
  perform public.kc_owner_create_stall(v_own2, 'Warung Malam', 'USU', 'Blok B-2', 'Tutup siang', 15);
  select id into v_stall2 from public.catalog_stalls where owner_id = v_own2;
  select id into v_cat2 from public.owner_menu_categories where stall_id = v_stall2 limit 1;
  v_menu_closed := (public.kc_owner_create_menu(v_own2, 'Nasi Goreng Ayam', v_cat2, 17000, true, '')->>'id')::uuid;
  perform public.kc_owner_publish_stall(v_own2);

  -- Admin cannot call Customer AI quota RPC.
  begin
    perform public.kc_ai_get_quota_status(v_admin, 10, 100, v_day1_end);
    raise exception 'Expected KC_AI_CUSTOMER_REQUIRED for Admin';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_AI_CUSTOMER_REQUIRED' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  -- Catalog search respects budget max 20000, hides archived & closed/habis by default (AI-002, AI-004).
  v_search := public.kc_ai_search_catalog('ayam', 20000, false, 20);
  if jsonb_array_length(v_search->'items') <> 1 or (v_search->'items'->0->>'id')::uuid <> v_menu_cheap then
    raise exception 'Expected only v_menu_cheap for max 20000 available search, got %', v_search;
  end if;

  -- Including unavailable shows Habis + Closed with explicit labels, NEVER Archived.
  v_search := public.kc_ai_search_catalog('ayam', 20000, true, 20);
  if jsonb_array_length(v_search->'items') <> 3 then
    raise exception 'Expected 3 non-archived items <=20000 (1 orderable + 1 habis + 1 closed), got %', v_search;
  end if;
  if exists (
    select 1 from jsonb_array_elements(v_search->'items') elem
    where (elem->>'id')::uuid = v_menu_archived
  ) then
    raise exception 'Archived menu leaked into AI catalog search';
  end if;

  -- Verify hallucinated/over-budget/archived menu IDs are stripped & authoritative DB price preserved (AI-002).
  v_verified := public.kc_ai_verify_menu_candidates(
    array[v_menu_cheap, v_menu_expensive, v_menu_archived, gen_random_uuid()],
    20000,
    false
  );
  if jsonb_array_length(v_verified->'items') <> 1 or (v_verified->'items'->0->>'price')::integer <> 18000 then
    raise exception 'Expected only verified cheap item with authoritative price 18000, got %', v_verified;
  end if;

  -- Unverified project cap (0) fails closed without consuming quota.
  v_res := public.kc_ai_reserve_call(v_cust, 'catalog_chat', 'gemini-3.5-flash-lite', 10, 0, v_day1_end);
  if (v_res->>'reserved')::boolean or (v_res->>'reason') <> 'project_cap_unverified' then
    raise exception 'Expected project_cap_unverified, got %', v_res;
  end if;

  -- Reservation #1 failed before dispatch -> quota refunded cleanly.
  v_res := public.kc_ai_reserve_call(v_cust, 'catalog_chat', 'gemini-3.5-flash-lite', 10, 50, v_day1_end);
  v_att_fail := (v_res->>'attempt_id')::uuid;
  perform public.kc_ai_finalize_attempt(v_cust, v_att_fail, 'failed_before_dispatch');
  v_status := public.kc_ai_get_quota_status(v_cust, 10, 50, v_day1_end);
  if (v_status->>'used_today')::integer <> 0 then
    raise exception 'Expected failed_before_dispatch to refund quota, got %', v_status;
  end if;

  -- Reservation dispatched + uncertain outcome stays counted (AI-TECH-001).
  v_res := public.kc_ai_reserve_call(v_cust, 'general_culinary', 'gemini-3.5-flash-lite', 10, 50, v_day1_end);
  v_att_uncertain := (v_res->>'attempt_id')::uuid;
  perform public.kc_ai_finalize_attempt(v_cust, v_att_uncertain, 'dispatched');
  perform public.kc_ai_finalize_attempt(v_cust, v_att_uncertain, 'uncertain');
  v_status := public.kc_ai_get_quota_status(v_cust, 10, 50, v_day1_end);
  if (v_status->>'used_today')::integer <> 1 then
    raise exception 'Expected dispatched+uncertain to consume 1 quota, got %', v_status;
  end if;

  -- Consume remaining 9 calls -> 10 used, 11th call rejected with user_quota_exhausted.
  for i in 2..10 loop
    v_res := public.kc_ai_reserve_call(v_cust, 'catalog_chat', 'gemini-3.5-flash-lite', 10, 50, v_day1_end);
    if not (v_res->>'reserved')::boolean then
      raise exception 'Expected reservation #% to succeed: %', i, v_res;
    end if;
    v_att := (v_res->>'attempt_id')::uuid;
    perform public.kc_ai_finalize_attempt(v_cust, v_att, 'dispatched');
    perform public.kc_ai_finalize_attempt(v_cust, v_att, 'succeeded');
  end loop;

  v_res := public.kc_ai_reserve_call(v_cust, 'catalog_chat', 'gemini-3.5-flash-lite', 10, 50, v_day1_end);
  if (v_res->>'reserved')::boolean or (v_res->>'reason') <> 'user_quota_exhausted' then
    raise exception 'Expected 11th call blocked with user_quota_exhausted, got %', v_res;
  end if;

  -- Verify inactive Owner stall (even with is_open=true) is blocked from orderable results (AI-002).
  perform public.kc_owner_set_stall_open(v_own2, true);
  perform public.kc_admin_set_user_active_status(v_admin, v_own2, false, 'Uji owner nonaktif');
  v_search := public.kc_ai_search_catalog('goreng', 20000, false, 20);
  if jsonb_array_length(v_search->'items') <> 0 then
    raise exception 'Expected inactive Owner stall blocked from orderable AI search, got %', v_search;
  end if;
  v_search := public.kc_ai_search_catalog('goreng', 20000, true, 20);
  if jsonb_array_length(v_search->'items') <> 1 or (v_search->'items'->0->>'unavailable_reason') <> 'owner_inactive' then
    raise exception 'Expected owner_inactive label when include_unavailable=true, got %', v_search;
  end if;

  -- Crossing 00:00 WIB (2026-11-22T17:00:00Z) resets quota to 10/10 cleanly!
  v_status := public.kc_ai_get_quota_status(v_cust, 10, 50, v_day2_start);
  if (v_status->>'jakarta_date') <> '2026-11-23' or (v_status->>'used_today')::integer <> 0 or (v_status->>'remaining_today')::integer <> 10 then
    raise exception 'Expected 00:00 WIB reset, got %', v_status;
  end if;
end;
$$;

rollback;
