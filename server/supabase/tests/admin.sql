-- SQL verification suite for Admin Module (ADMIN-001..ADMIN-005,
-- ADMIN-003A, ADMIN-003B, CUSTOMER-006A, ORDER-013B).
begin;

-- 1. Verify anon/authenticated cannot access admin_action_logs or execute kc_admin_* RPCs.
do $$
declare
  client_role text;
begin
  foreach client_role in array array['anon', 'authenticated'] loop
    if has_table_privilege(client_role, 'public.admin_action_logs', 'select')
       or has_table_privilege(client_role, 'public.admin_action_logs', 'insert')
       or has_function_privilege(client_role, 'public.kc_admin_dashboard(uuid)', 'execute')
       or has_function_privilege(client_role, 'public.kc_admin_review_application(uuid,uuid,text,text)', 'execute')
       or has_function_privilege(client_role, 'public.kc_admin_set_user_active_status(uuid,uuid,boolean,text)', 'execute')
       or has_function_privilege(client_role, 'public.kc_admin_list_stalls(uuid,text,integer,integer)', 'execute') then
      raise exception 'Unexpected client privilege for role %', client_role;
    end if;
  end loop;
end;
$$;

-- 2. Seed two Admins, one active Owner with open published stall, and two Customers.
insert into auth.users (id, email, email_confirmed_at, raw_app_meta_data, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000a001', 'adm1@example.test', now(), '{"kantin_role":"admin"}', '{"display_name":"Admin Satu"}'),
  ('00000000-0000-0000-0000-00000000a002', 'adm2@example.test', now(), '{"kantin_role":"admin"}', '{"display_name":"Admin Dua"}'),
  ('00000000-0000-0000-0000-00000000a101', 'adm-own@example.test', now(), '{"kantin_role":"owner"}', '{"display_name":"Owner Uji"}'),
  ('00000000-0000-0000-0000-00000000a201', 'adm-cust1@example.test', now(), '{"kantin_role":"customer"}', '{"display_name":"Pemohon Satu"}'),
  ('00000000-0000-0000-0000-00000000a202', 'adm-cust2@example.test', now(), '{"kantin_role":"customer"}', '{"display_name":"Pembeli Dua"}');

set local role service_role;

do $$
declare
  v_admin1 constant uuid := '00000000-0000-0000-0000-00000000a001';
  v_admin2 constant uuid := '00000000-0000-0000-0000-00000000a002';
  v_owner constant uuid := '00000000-0000-0000-0000-00000000a101';
  v_cust1 constant uuid := '00000000-0000-0000-0000-00000000a201';
  v_cust2 constant uuid := '00000000-0000-0000-0000-00000000a202';

  v_stall_id uuid;
  v_cat_id uuid;
  v_menu_id uuid;
  v_cart jsonb;
  v_attempt uuid;
  v_order_id uuid;

  v_app_state jsonb;
  v_app_id uuid;
  v_dash jsonb;
  v_reviewed jsonb;
  v_user_detail jsonb;
  v_stall_detail jsonb;
  v_err text;
begin
  -- Owner creates, publishes, and opens stall + menu.
  perform public.kc_owner_create_stall(v_owner, 'Kantin Admin QA', 'USU', 'Blok D-01', 'Segar', 10);
  select id into v_stall_id from public.catalog_stalls where owner_id = v_owner;
  select id into v_cat_id from public.owner_menu_categories where stall_id = v_stall_id limit 1;
  v_menu_id := (public.kc_owner_create_menu(v_owner, 'Soto Ayam', v_cat_id, 14000, true, '')->>'id')::uuid;
  perform public.kc_owner_publish_stall(v_owner);
  perform public.kc_owner_set_stall_open(v_owner, true);

  -- Non-admin must fail Admin RPC.
  begin
    perform public.kc_admin_dashboard(v_cust1);
    raise exception 'Expected KC_ADMIN_REQUIRED';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_ADMIN_REQUIRED' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  -- Customer 1 creates an active order and submits an Owner application (CUSTOMER-006A).
  v_cart := public.kc_customer_add_cart_item(v_cust1, v_menu_id, 1, '', false);
  v_attempt := ((public.kc_customer_create_checkout_attempt(v_cust1, (v_cart->>'draft_version')::integer))->>'attempt_id')::uuid;
  v_order_id := ((public.kc_customer_checkout(v_cust1, 'Pemohon Satu', v_attempt, (v_cart->>'draft_version')::integer))->'order'->>'id')::uuid;

  v_app_state := public.kc_customer_submit_owner_application(
    v_cust1, 'Warung Baru', 'Blok E-02', 'Ingin membuka stan makanan.'
  );
  v_app_id := (v_app_state->'latest_application'->>'id')::uuid;

  -- Dashboard counts reflect pending application cleanly.
  v_dash := public.kc_admin_dashboard(v_admin1);
  if (v_dash->>'pending_applications')::integer < 1 or (v_dash->>'open_stalls')::integer < 1 then
    raise exception 'Unexpected dashboard counts: %', v_dash;
  end if;

  -- Approve while Customer 1 still has active order must fail (CUSTOMER-006A).
  begin
    perform public.kc_admin_review_application(v_admin1, v_app_id, 'disetujui', null);
    raise exception 'Expected KC_ACTIVE_ORDERS_PRESENT on approval with active order';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_ACTIVE_ORDERS_PRESENT' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  -- Reject without reason must fail (ADMIN-002).
  begin
    perform public.kc_admin_review_application(v_admin1, v_app_id, 'ditolak', '   ');
    raise exception 'Expected KC_REASON_REQUIRED';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_REASON_REQUIRED' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  -- Reject with valid reason succeeds & writes audit log.
  v_reviewed := public.kc_admin_review_application(
    v_admin1, v_app_id, 'ditolak', 'Masih memiliki pesanan aktif menunggu konfirmasi.'
  );
  if v_reviewed->>'status' <> 'ditolak' then
    raise exception 'Expected ditolak status, got %', v_reviewed;
  end if;

  -- Deactivating Customer 1 OR Owner while order is active must fail (ADMIN-003A).
  begin
    perform public.kc_admin_set_user_active_status(v_admin1, v_cust1, false, 'Uji nonaktif saat aktif');
    raise exception 'Expected KC_ACTIVE_ORDERS_PRESENT on cust1 deactivate';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_ACTIVE_ORDERS_PRESENT' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  begin
    perform public.kc_admin_set_user_active_status(v_admin1, v_owner, false, 'Uji nonaktif owner saat aktif');
    raise exception 'Expected KC_ACTIVE_ORDERS_PRESENT on owner deactivate';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_ACTIVE_ORDERS_PRESENT' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  -- Move order to Siap Diambil -> Gagal Diambil (ORDER-013B terminal, NOT active).
  perform public.kc_owner_transition_order(v_owner, v_order_id, 'accept');
  perform public.kc_owner_transition_order(v_owner, v_order_id, 'ready');
  perform public.kc_owner_transition_order(v_owner, v_order_id, 'fail_pickup', 'Pemesan tidak datang');

  -- Customer 1 resubmits Owner application; now zero active orders -> Admin approves -> role becomes owner!
  v_app_state := public.kc_customer_submit_owner_application(
    v_cust1, 'Warung Baru', 'Blok E-02', 'Semua pesanan sudah selesai/terminal.'
  );
  select id into v_app_id
  from public.owner_applications
  where customer_id = v_cust1 and status = 'menunggu_review';
  v_reviewed := public.kc_admin_review_application(v_admin1, v_app_id, 'disetujui', null);
  if v_reviewed->>'status' <> 'disetujui' then
    raise exception 'Expected disetujui status, got %', v_reviewed;
  end if;
  if (public.kc_admin_get_user(v_admin1, v_cust1)->>'role') <> 'owner' then
    raise exception 'Expected Customer 1 promoted to owner';
  end if;
  if exists (select 1 from public.catalog_stalls where owner_id = v_cust1) then
    raise exception 'ADMIN-001 violation: approval must not auto-create stall';
  end if;

  -- Customer 2 prepares cart & checkout attempt BEFORE Owner is deactivated (ADMIN-003B race).
  v_cart := public.kc_customer_add_cart_item(v_cust2, v_menu_id, 1, '', false);
  v_attempt := ((public.kc_customer_create_checkout_attempt(v_cust2, (v_cart->>'draft_version')::integer))->>'attempt_id')::uuid;

  -- Deactivating Owner now succeeds (gagal_diambil does not block per ORDER-013B)
  -- AND preserves stall is_listed=true & is_open=true (ADMIN-003B), while blocking Customer 2 checkout.
  v_user_detail := public.kc_admin_set_user_active_status(v_admin1, v_owner, false, 'Audit kelayakan');
  if (v_user_detail->>'is_active')::boolean then
    raise exception 'Expected owner inactive';
  end if;
  v_stall_detail := public.kc_admin_get_stall(v_admin1, v_stall_id);
  if not (v_stall_detail->>'is_listed')::boolean or not (v_stall_detail->>'is_open')::boolean or (v_stall_detail->>'owner_is_active')::boolean then
    raise exception 'Expected ADMIN-003B stall open/listed preserved while owner_is_active=false: %', v_stall_detail;
  end if;

  -- Customer 2 cannot checkout from deactivated Owner's stall (ADMIN-003B).
  begin
    perform public.kc_customer_checkout(v_cust2, 'Pembeli Dua', v_attempt, (v_cart->>'draft_version')::integer);
    raise exception 'Expected KC_OWNER_INACTIVE';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_OWNER_INACTIVE' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  -- Check list queries return expected administrative records.
  if jsonb_array_length(public.kc_admin_list_applications(v_admin1, 'history', 10, 0)->'items') < 2 then
    raise exception 'Expected >= 2 history applications';
  end if;
  if jsonb_array_length(public.kc_admin_list_users(v_admin1, null, null, 'Owner Uji', 10, 0)->'items') <> 1 then
    raise exception 'Expected 1 matching user for Owner Uji';
  end if;
  if jsonb_array_length(public.kc_admin_list_stalls(v_admin1, 'Kantin Admin QA', 10, 0)->'items') <> 1 then
    raise exception 'Expected 1 matching stall';
  end if;
  if jsonb_array_length(public.kc_admin_list_action_logs(v_admin1, null, 20, 0)->'items') < 3 then
    raise exception 'Expected >= 3 audit log entries';
  end if;

  -- Reactivate Owner (ADMIN-003) -> Customer 2 checkout now succeeds.
  v_user_detail := public.kc_admin_set_user_active_status(v_admin1, v_owner, true, 'Terverifikasi kembali');
  if not (v_user_detail->>'is_active')::boolean then
    raise exception 'Expected owner reactivated';
  end if;

  -- Admin 1 deactivates Admin 2 (reason required), then Admin 2 cannot run Admin RPC,
  -- and Admin 1 is now the last active Admin so self-deactivation is blocked (ADMIN-005).
  begin
    perform public.kc_admin_set_user_active_status(v_admin1, v_admin2, false, '');
    raise exception 'Expected KC_REASON_REQUIRED';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_REASON_REQUIRED' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  perform public.kc_admin_set_user_active_status(v_admin1, v_admin2, false, 'Rotasi petugas');
  begin
    perform public.kc_admin_dashboard(v_admin2);
    raise exception 'Expected KC_ADMIN_INACTIVE for deactivated admin2';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_ADMIN_INACTIVE' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  begin
    perform public.kc_admin_set_user_active_status(v_admin1, v_admin1, false, 'Self check');
    raise exception 'Expected KC_SELF_DEACTIVATION_NOT_ALLOWED';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_SELF_DEACTIVATION_NOT_ALLOWED' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  -- Verify service_role lacks update/delete privileges on audit logs.
  begin
    update public.admin_action_logs set summary = 'tamper';
    raise exception 'Expected insufficient_privilege on audit log update';
  exception
    when insufficient_privilege then null;
  end;
end;
$$;

-- Verify database immutability trigger also rejects table-owner update/delete.
reset role;
do $$
declare
  v_err text;
begin
  begin
    update public.admin_action_logs set summary = 'tamper';
    raise exception 'Expected KC_ADMIN_AUDIT_IMMUTABLE on update';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_ADMIN_AUDIT_IMMUTABLE' then raise exception 'Unexpected err: %', v_err; end if;
  end;
end;
$$;

rollback;
