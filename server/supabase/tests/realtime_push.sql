-- Disposable PostgreSQL 16 verification suite for Realtime & Push Notification Finalization.
-- Covers ORDER-017, ORDER-017A (exact 7 push events, no selesai/gagal_diambil/Admin push),
-- RT-TECH-002 (deduplicated delivery & bounded retry), RT-TECH-003 (strict Customer/Owner isolation),
-- RT-TECH-005 & R2 (topic rotation, device revocation, account switch, deactivation revocation).

\set ON_ERROR_STOP on

begin;

do $$
declare
  v_owner_a uuid := 'aaaaaaaa-0000-4000-8000-000000000901';
  v_owner_b uuid := 'aaaaaaaa-0000-4000-8000-000000000902';
  v_cust_a  uuid := 'bbbbbbbb-0000-4000-8000-000000000901';
  v_cust_b  uuid := 'bbbbbbbb-0000-4000-8000-000000000902';
  v_admin   uuid := 'cccccccc-0000-4000-8000-000000000901';

  v_stall_a uuid;
  v_cat_a   uuid;
  v_menu_a  uuid;

  v_order_1 uuid;
  v_order_2 uuid;
  v_order_3 uuid;
  v_order_4 uuid;
  v_order_5 uuid;
  v_order_6 uuid;

  v_cart    jsonb;
  v_attempt uuid;
  v_version integer;
  v_json    jsonb;
  v_claim   jsonb;
  v_item    jsonb;
  v_poll    jsonb;
  v_grant_1 jsonb;
  v_grant_2 jsonb;
  v_err     text;
  v_count   integer;
  v_now     timestamptz := now();
  v_events  text[];
begin
  -- Seed users (including Customer with omitted kantin_role matching GoTrue v2.186.0)
  insert into auth.users (id, email, email_confirmed_at, raw_app_meta_data, raw_user_meta_data)
  values
    (v_owner_a, 'rt-owner-a@example.test', v_now, '{"kantin_role":"owner"}'::jsonb, '{"display_name":"Owner RT A"}'::jsonb),
    (v_owner_b, 'rt-owner-b@example.test', v_now, '{"kantin_role":"owner"}'::jsonb, '{"display_name":"Owner RT B"}'::jsonb),
    (v_cust_a,  'rt-cust-a@example.test',  v_now, '{}'::jsonb, '{"display_name":"Customer RT A"}'::jsonb),
    (v_cust_b,  'rt-cust-b@example.test',  v_now, '{"kantin_role":"customer"}'::jsonb, '{"display_name":"Customer RT B"}'::jsonb),
    (v_admin,   'rt-admin@example.test',   v_now, '{"kantin_role":"admin"}'::jsonb, '{"display_name":"Admin RT"}'::jsonb);

  -- Setup published open stall & menu for Owner A
  perform public.kc_owner_create_stall(v_owner_a, 'Kantin Realtime A', 'USU', 'Blok RT-1', 'Kantin uji realtime', 10);
  select id into v_stall_a from public.catalog_stalls where owner_id = v_owner_a;
  select id into v_cat_a from public.owner_menu_categories where stall_id = v_stall_a limit 1;
  v_menu_a := (public.kc_owner_create_menu(v_owner_a, 'Ayam Penyet RT', v_cat_a, 18000, true, 'Enak')->>'id')::uuid;
  perform public.kc_owner_publish_stall(v_owner_a);
  perform public.kc_owner_set_stall_open(v_owner_a, true);

  -- 1. Admin MUST NOT register push devices or acquire order realtime grants (ORDER-017A, ADMIN-005)
  begin
    perform public.kc_rt_register_push_device(v_admin, 'admin-dev-1', 'fcm_token_admin_1234567890123456');
    raise exception 'Expected Admin push device registration to fail';
  exception when raise_exception then
    get stacked diagnostics v_err = pg_exception_detail;
    assert v_err = 'KC_PUSH_ROLE_NOT_ALLOWED', format('Unexpected error for admin push device: %s', v_err);
  end;

  begin
    perform public.kc_rt_get_channel_grant(v_admin);
    raise exception 'Expected Admin realtime grant to fail';
  exception when raise_exception then
    get stacked diagnostics v_err = pg_exception_detail;
    assert v_err = 'KC_PUSH_ROLE_NOT_ALLOWED', format('Unexpected error for admin grant: %s', v_err);
  end;

  -- 2. Register push devices for Owner A (2 devices) and Customer A (1 device)
  perform public.kc_rt_register_push_device(v_owner_a, 'owner-phone-1', 'fcm_token_owner_phone_0000000001');
  perform public.kc_rt_register_push_device(v_owner_a, 'owner-phone-2', 'fcm_token_owner_phone_0000000002');
  perform public.kc_rt_register_push_device(v_cust_a,  'cust-phone-1',  'fcm_token_cust_a_phone_000000001');

  -- 3. Account-switch safety: registering same FCM token/device for Customer B detaches Customer A
  perform public.kc_rt_register_push_device(v_cust_b,  'cust-phone-1',  'fcm_token_cust_a_phone_000000001');
  select count(*) into v_count
  from public.user_push_devices
  where user_id = v_cust_a and is_active = true;
  assert v_count = 0, 'Previous account device must be deactivated on account switch';

  -- Re-register Customer A on a fresh device for matrix test
  perform public.kc_rt_register_push_device(v_cust_a,  'cust-a-fresh',  'fcm_token_cust_a_fresh_000000001');

  -- 4. Exercise ALL 7 ORDER-017A push events + 2 non-push terminal transitions (selesai, gagal_diambil)
  -- Order 1: checkout (order_created -> owner) -> cancel (order_cancelled -> owner)
  v_cart := public.kc_customer_add_cart_item(v_cust_a, v_menu_a, 1, '', false);
  v_version := (v_cart->>'draft_version')::integer;
  v_attempt := (public.kc_customer_create_checkout_attempt(v_cust_a, v_version)->>'attempt_id')::uuid;
  v_json := public.kc_customer_checkout(v_cust_a, 'Customer RT A', v_attempt, v_version);
  v_order_1 := (v_json->'order'->>'id')::uuid;
  perform public.kc_customer_cancel_order(v_cust_a, v_order_1);

  -- Order 2: checkout -> reject (order_rejected -> customer)
  v_cart := public.kc_customer_add_cart_item(v_cust_a, v_menu_a, 1, '', false);
  v_version := (v_cart->>'draft_version')::integer;
  v_attempt := (public.kc_customer_create_checkout_attempt(v_cust_a, v_version)->>'attempt_id')::uuid;
  v_json := public.kc_customer_checkout(v_cust_a, 'Customer RT A', v_attempt, v_version);
  v_order_2 := (v_json->'order'->>'id')::uuid;
  perform public.kc_owner_transition_order(v_owner_a, v_order_2, 'reject', 'Bahan habis', false, false);

  -- Order 3: checkout -> accept (order_accepted -> customer) -> fail_fulfillment (order_failed_fulfill -> customer)
  v_cart := public.kc_customer_add_cart_item(v_cust_a, v_menu_a, 1, '', false);
  v_version := (v_cart->>'draft_version')::integer;
  v_attempt := (public.kc_customer_create_checkout_attempt(v_cust_a, v_version)->>'attempt_id')::uuid;
  v_json := public.kc_customer_checkout(v_cust_a, 'Customer RT A', v_attempt, v_version);
  v_order_3 := (v_json->'order'->>'id')::uuid;
  perform public.kc_owner_transition_order(v_owner_a, v_order_3, 'accept', null, false, false);
  perform public.kc_owner_transition_order(v_owner_a, v_order_3, 'fail_fulfillment', 'Kompor rusak', false, false);

  -- Order 4: checkout -> accept -> ready (order_ready -> customer) -> complete (selesai -> NO PUSH, YES REALTIME)
  v_cart := public.kc_customer_add_cart_item(v_cust_a, v_menu_a, 1, '', false);
  v_version := (v_cart->>'draft_version')::integer;
  v_attempt := (public.kc_customer_create_checkout_attempt(v_cust_a, v_version)->>'attempt_id')::uuid;
  v_json := public.kc_customer_checkout(v_cust_a, 'Customer RT A', v_attempt, v_version);
  v_order_4 := (v_json->'order'->>'id')::uuid;
  perform public.kc_owner_transition_order(v_owner_a, v_order_4, 'accept', null, false, false);
  perform public.kc_owner_transition_order(v_owner_a, v_order_4, 'ready', null, false, false);
  perform public.kc_owner_transition_order(v_owner_a, v_order_4, 'complete', null, true, true);

  -- Order 5: checkout -> accept -> ready -> not_picked_up (order_not_picked_up -> customer)
  v_cart := public.kc_customer_add_cart_item(v_cust_a, v_menu_a, 1, '', false);
  v_version := (v_cart->>'draft_version')::integer;
  v_attempt := (public.kc_customer_create_checkout_attempt(v_cust_a, v_version)->>'attempt_id')::uuid;
  v_json := public.kc_customer_checkout(v_cust_a, 'Customer RT A', v_attempt, v_version);
  v_order_5 := (v_json->'order'->>'id')::uuid;
  perform public.kc_owner_transition_order(v_owner_a, v_order_5, 'accept', null, false, false);
  perform public.kc_owner_transition_order(v_owner_a, v_order_5, 'ready', null, false, false);
  perform public.kc_owner_transition_order(v_owner_a, v_order_5, 'not_picked_up', null, false, false);

  -- Order 6: checkout -> accept -> ready -> fail_pickup (gagal_diambil -> NO PUSH, YES REALTIME)
  v_cart := public.kc_customer_add_cart_item(v_cust_a, v_menu_a, 1, '', false);
  v_version := (v_cart->>'draft_version')::integer;
  v_attempt := (public.kc_customer_create_checkout_attempt(v_cust_a, v_version)->>'attempt_id')::uuid;
  v_json := public.kc_customer_checkout(v_cust_a, 'Customer RT A', v_attempt, v_version);
  v_order_6 := (v_json->'order'->>'id')::uuid;
  perform public.kc_owner_transition_order(v_owner_a, v_order_6, 'accept', null, false, false);
  perform public.kc_owner_transition_order(v_owner_a, v_order_6, 'ready', null, false, false);
  perform public.kc_owner_transition_order(v_owner_a, v_order_6, 'fail_pickup', 'Makanan tumpah', false, false);

  -- Verify exact 7 distinct event types in outbox & ZERO admin recipients
  select array_agg(distinct event_type order by event_type)
  into v_events
  from public.order_notification_events;

  assert v_events = array[
    'order_accepted',
    'order_cancelled',
    'order_created',
    'order_failed_fulfill',
    'order_not_picked_up',
    'order_ready',
    'order_rejected'
  ], format('Unexpected push event types: %s', v_events);

  select count(*) into v_count
  from public.order_notification_events
  where recipient_id = v_admin;
  assert v_count = 0, 'Admin must never receive order notification events';

  -- Verify Realtime signals DO include selesai AND gagal_diambil!
  select count(*) into v_count
  from public.order_realtime_signals
  where order_id = v_order_4 and to_status = 'selesai';
  assert v_count = 1, 'selesai must emit a realtime signal without push';

  select count(*) into v_count
  from public.order_realtime_signals
  where order_id = v_order_6 and to_status = 'gagal_diambil';
  assert v_count = 1, 'gagal_diambil must emit a realtime signal without push';

  -- 5. Strict Realtime isolation (RT-TECH-003): Customer B & Owner B see ZERO signals from Customer A / Stall A
  v_poll := public.kc_rt_poll_signals(v_cust_b, 0, 100);
  assert jsonb_array_length(v_poll->'items') = 0, 'Customer B must never see Customer A signals';

  v_poll := public.kc_rt_poll_signals(v_owner_b, 0, 100);
  assert jsonb_array_length(v_poll->'items') = 0, 'Owner B must never see Stall A signals';

  -- Customer A & Owner A both see all transitions for their orders
  v_poll := public.kc_rt_poll_signals(v_cust_a, 0, 100);
  assert jsonb_array_length(v_poll->'items') = 19,
    format('Expected 19 realtime signals for Customer A, got %s', jsonb_array_length(v_poll->'items'));

  v_poll := public.kc_rt_poll_signals(v_owner_a, 0, 100);
  assert jsonb_array_length(v_poll->'items') = 19,
    format('Expected 19 realtime signals for Owner A, got %s', jsonb_array_length(v_poll->'items'));

  -- 6. Claim push deliveries, verify deduplication + retry + permanent UNREGISTERED deactivation (R1)
  v_claim := public.kc_push_claim_pending_deliveries(100, 3, 60, v_now);
  -- Owner A has 2 devices -> 6 order_created + 1 order_cancelled = 7 events * 2 devices = 14 deliveries
  -- Customer A has 1 device -> 1 reject + 4 accept + 1 fail_fulfill + 3 ready + 1 not_picked_up = 10 deliveries
  -- Total = 24 deliveries
  assert jsonb_array_length(v_claim->'items') = 24,
    format('Expected 24 claimed deliveries, got %s', jsonb_array_length(v_claim->'items'));

  -- Immediate second claim while in-flight must return 0 (no double-send!)
  assert jsonb_array_length(
    (public.kc_push_claim_pending_deliveries(100, 3, 60, v_now))->'items'
  ) = 0, 'In-flight deliveries must not be double-claimed';

  -- Complete first delivery with transient retry -> scheduled at +30s
  v_item := (v_claim->'items')->0;
  v_json := public.kc_push_complete_delivery(
    (v_item->>'delivery_id')::uuid, 'retry', 'FCM_UNAVAILABLE', null, 30, false, v_now
  );
  assert v_json->>'status' = 'retry_scheduled', 'Expected retry_scheduled';

  -- Before 30s -> not yet due; at +31s -> claimed again (attempt 2)
  assert jsonb_array_length(
    (public.kc_push_claim_pending_deliveries(100, 3, 60, v_now + interval '10 seconds'))->'items'
  ) = 0, 'Retry must respect next_retry_at backoff';

  v_json := public.kc_push_claim_pending_deliveries(100, 3, 60, v_now + interval '31 seconds');
  assert jsonb_array_length(v_json->'items') = 1, 'Retry should become due after backoff';
  assert ((v_json->'items')->0->>'attempt_count')::int = 2, 'Attempt count must increment to 2';

  -- Mark it sent
  perform public.kc_push_complete_delivery(
    (v_item->>'delivery_id')::uuid, 'sent', null, 'projects/test/messages/1', 30, false, v_now + interval '31 seconds'
  );

  -- Mark second delivery failed_permanent with UNREGISTERED -> deactivates that device
  v_item := (v_claim->'items')->1;
  perform public.kc_push_complete_delivery(
    (v_item->>'delivery_id')::uuid, 'failed_permanent', 'UNREGISTERED', null, 30, true, v_now + interval '31 seconds'
  );
  select count(*) into v_count
  from public.user_push_devices
  where fcm_token = (v_item->>'fcm_token') and is_active = true;
  assert v_count = 0, 'UNREGISTERED permanent failure must deactivate device token';

  -- 7. Topic rotation on device logout (RT-TECH-005 & R2):
  -- Owner A has phone-1 and phone-2; revoking phone-1 rotates topic epoch while leaving valid devices intact.
  v_grant_1 := public.kc_rt_get_channel_grant(v_owner_a);
  perform public.kc_rt_revoke_push_device(v_owner_a, 'owner-phone-1', true);
  v_grant_2 := public.kc_rt_get_channel_grant(v_owner_a);
  assert (v_grant_2->>'customer_epoch')::int = (v_grant_1->>'customer_epoch')::int + 1,
    'Customer topic epoch must rotate on logout';
  assert (v_grant_2->>'stall_epoch')::int = (v_grant_1->>'stall_epoch')::int + 1,
    'Stall topic epoch must rotate on logout';
  assert (v_grant_2->>'stall_topic') <> (v_grant_1->>'stall_topic'),
    'Rotated stall topic string must change';

  -- 8. Deactivating Customer A via auth.users automatically rotates topic, revokes devices, and blocks grant/poll (R2)
  update auth.users
  set banned_until = 'infinity'::timestamptz
  where id = v_cust_a;

  select count(*) into v_count
  from public.user_push_devices
  where user_id = v_cust_a and is_active = true;
  assert v_count = 0, 'Deactivating user must revoke all active push devices';

  begin
    perform public.kc_rt_get_channel_grant(v_cust_a);
    raise exception 'Expected inactive customer grant to fail';
  exception when raise_exception then
    get stacked diagnostics v_err = pg_exception_detail;
    assert v_err = 'KC_RT_ACCOUNT_INACTIVE', format('Unexpected error for inactive grant: %s', v_err);
  end;

  begin
    perform public.kc_rt_poll_signals(v_cust_a, 0, 50);
    raise exception 'Expected inactive customer poll to fail';
  exception when raise_exception then
    get stacked diagnostics v_err = pg_exception_detail;
    assert v_err = 'KC_RT_ACCOUNT_INACTIVE', format('Unexpected error for inactive poll: %s', v_err);
  end;

  -- 9. Unbroadcasted realtime signals claim works atomically and only claims once
  v_json := public.kc_rt_claim_unbroadcasted_signals(50, v_now);
  assert jsonb_array_length(v_json->'items') = 19, 'Expected 19 unbroadcasted signals';
  assert jsonb_array_length(
    (public.kc_rt_claim_unbroadcasted_signals(50, v_now))->'items'
  ) = 0, 'Broadcasted signals must not be double-claimed';

  -- Verify no anon/authenticated table access
  assert not has_table_privilege('anon', 'public.order_realtime_signals', 'select');
  assert not has_table_privilege('authenticated', 'public.order_realtime_signals', 'select');
  assert not has_table_privilege('anon', 'public.user_push_devices', 'select');
  assert not has_table_privilege('authenticated', 'public.user_push_devices', 'select');
  assert not has_table_privilege('anon', 'public.order_push_deliveries', 'select');
  assert not has_table_privilege('authenticated', 'public.order_push_deliveries', 'select');

  raise notice 'realtime_push.sql PASSED all assertions.';
end;
$$;

rollback;
