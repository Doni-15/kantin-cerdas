-- SQL verification suite for Customer Cart, Checkout, Orders, Active-Order Indicator,
-- and Owner Applications (CUSTOMER-001..006A, ORDER-001..017A, OWNER-005A, ADMIN-001..003B).
begin;

-- 1. Verify anon/authenticated cannot query tables or call service_role RPCs directly.
do $$
declare
  client_role text;
begin
  foreach client_role in array array['anon', 'authenticated'] loop
    if has_table_privilege(client_role, 'public.customer_carts', 'select')
       or has_table_privilege(client_role, 'public.customer_cart_items', 'select')
       or has_table_privilege(client_role, 'public.customer_checkout_attempts', 'select')
       or has_table_privilege(client_role, 'public.owner_applications', 'select')
       or has_function_privilege(client_role, 'public.kc_customer_checkout(uuid,text,uuid,integer)', 'execute')
       or has_function_privilege(client_role, 'public.kc_admin_user_active_order_indicator(uuid)', 'execute') then
      raise exception 'Unexpected client privilege for role %', client_role;
    end if;
  end loop;
end;
$$;

-- 2. Seed test users (Owner A active, Owner B active, Customer 1 verified, Customer 2 verified).
insert into auth.users (id, email, email_confirmed_at) values
  ('00000000-0000-0000-0000-00000000c101', 'cu-ownera@example.test', now()),
  ('00000000-0000-0000-0000-00000000c102', 'cu-ownerb@example.test', now()),
  ('00000000-0000-0000-0000-00000000c201', 'cu-cust1@example.test', now()),
  ('00000000-0000-0000-0000-00000000c202', 'cu-cust2@example.test', now());

set local role service_role;

do $$
declare
  v_owner_a constant uuid := '00000000-0000-0000-0000-00000000c101';
  v_owner_b constant uuid := '00000000-0000-0000-0000-00000000c102';
  v_cust1 constant uuid := '00000000-0000-0000-0000-00000000c201';
  v_cust2 constant uuid := '00000000-0000-0000-0000-00000000c202';

  v_stall_a uuid;
  v_stall_b uuid;
  v_cat_a uuid;
  v_cat_b uuid;
  v_menu_a1 uuid;
  v_menu_a2 uuid;
  v_menu_b1 uuid;

  v_cart jsonb;
  v_item_id uuid;
  v_attempt_id uuid;
  v_attempt_2 uuid;
  v_version integer;
  v_checkout jsonb;
  v_order_id uuid;
  v_order_num text;
  v_indicator jsonb;
  v_err text;
begin
  perform public.kc_owner_create_stall(v_owner_a, 'Kantin Customer A', 'USU', 'Blok A', 'Enak', 12);
  perform public.kc_owner_create_stall(v_owner_b, 'Kantin Customer B', 'USU', 'Blok B', 'Mantap', 8);

  select id into v_stall_a from public.catalog_stalls where owner_id = v_owner_a;
  select id into v_stall_b from public.catalog_stalls where owner_id = v_owner_b;
  select id into v_cat_a from public.owner_menu_categories where stall_id = v_stall_a limit 1;
  select id into v_cat_b from public.owner_menu_categories where stall_id = v_stall_b limit 1;

  v_menu_a1 := (public.kc_owner_create_menu(v_owner_a, 'Nasi Goreng A', v_cat_a, 15000, true, '')->>'id')::uuid;
  v_menu_a2 := (public.kc_owner_create_menu(v_owner_a, 'Es Teh A', v_cat_a, 5000, true, '')->>'id')::uuid;
  v_menu_b1 := (public.kc_owner_create_menu(v_owner_b, 'Bakso B', v_cat_b, 18000, true, '')->>'id')::uuid;

  perform public.kc_owner_publish_stall(v_owner_a);
  perform public.kc_owner_publish_stall(v_owner_b);

  -- Cannot add to cart when stall is still Tutup.
  begin
    perform public.kc_customer_add_cart_item(v_cust1, v_menu_a1, 1, '', false);
    raise exception 'Expected KC_STALL_CLOSED when adding from closed stall';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_STALL_CLOSED' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  perform public.kc_owner_set_stall_open(v_owner_a, true);
  perform public.kc_owner_set_stall_open(v_owner_b, true);

  -- Add item to stall A + second stall confirmation guard (ORDER-009).
  v_cart := public.kc_customer_add_cart_item(v_cust1, v_menu_a1, 2, 'Pedas', false);
  if (v_cart->>'subtotal')::integer <> 30000 or (v_cart->>'item_count')::integer <> 2 then
    raise exception 'Cart subtotal mismatch: %', v_cart;
  end if;

  begin
    perform public.kc_customer_add_cart_item(v_cust1, v_menu_b1, 1, '', false);
    raise exception 'Expected KC_CART_DIFFERENT_STALL';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_CART_DIFFERENT_STALL' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  -- Confirm switch to stall B replaces cart cleanly, then switch back to stall A.
  v_cart := public.kc_customer_add_cart_item(v_cust1, v_menu_b1, 1, '', true);
  if (v_cart->'stall'->>'id')::uuid <> v_stall_b or jsonb_array_length(v_cart->'items') <> 1 then
    raise exception 'Failed explicit stall switch';
  end if;
  v_cart := public.kc_customer_add_cart_item(v_cust1, v_menu_a1, 1, 'Sedang', true);

  -- OWNER-005A: archiving menu keeps row in cart with is_archived=true & blocks checkout.
  perform public.kc_owner_archive_menu(v_owner_a, v_menu_a1);
  v_cart := public.kc_customer_get_cart(v_cust1);
  if (v_cart->>'can_checkout')::boolean or not ((v_cart->'blockers') @> '["has_archived_item"]'::jsonb) then
    raise exception 'Archived menu in cart must stay visible and block checkout: %', v_cart;
  end if;
  v_version := (v_cart->>'draft_version')::integer;
  v_attempt_id := (public.kc_customer_create_checkout_attempt(v_cust1, v_version)->>'attempt_id')::uuid;
  begin
    perform public.kc_customer_checkout(v_cust1, 'Cust 1', v_attempt_id, v_version);
    raise exception 'Expected KC_MENU_ARCHIVED during checkout';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_MENU_ARCHIVED' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  -- Restore + change price (ORDER-005) -> blocks checkout until acknowledged.
  perform public.kc_owner_restore_menu(v_owner_a, v_menu_a1);
  perform public.kc_owner_update_menu(v_owner_a, v_menu_a1, 'Nasi Goreng A', v_cat_a, 17500, true, '');
  v_cart := public.kc_customer_get_cart(v_cust1);
  if not ((v_cart->'blockers') @> '["has_price_change"]'::jsonb) then
    raise exception 'Expected price change blocker: %', v_cart;
  end if;
  v_attempt_id := (public.kc_customer_create_checkout_attempt(v_cust1, (v_cart->>'draft_version')::integer)->>'attempt_id')::uuid;
  begin
    perform public.kc_customer_checkout(v_cust1, 'Cust 1', v_attempt_id, (v_cart->>'draft_version')::integer);
    raise exception 'Expected KC_PRICE_CHANGED during checkout';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_PRICE_CHANGED' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  -- Acknowledge price, add general note, add second menu then remove via qty=0 (ORDER-010).
  v_cart := public.kc_customer_acknowledge_cart_prices(v_cust1, (v_cart->>'draft_version')::integer);
  v_cart := public.kc_customer_add_cart_item(v_cust1, v_menu_a2, 1, '', false);
  v_item_id := (
    select (elem->>'id')::uuid
    from jsonb_array_elements(v_cart->'items') elem
    where (elem->>'menu_item_id')::uuid = v_menu_a2
  );
  v_cart := public.kc_customer_update_cart_item(v_cust1, v_item_id, 0, null);
  v_cart := public.kc_customer_set_cart_note(v_cust1, 'Ambil cepat');
  v_version := (v_cart->>'draft_version')::integer;

  -- Valid idempotent checkout (replaying same attempt + version returns same order without duplicate).
  v_attempt_id := (public.kc_customer_create_checkout_attempt(v_cust1, v_version)->>'attempt_id')::uuid;
  v_checkout := public.kc_customer_checkout(v_cust1, 'Cust Satu', v_attempt_id, v_version);
  if (v_checkout->>'replayed')::boolean is true then
    raise exception 'First checkout must not be marked replayed';
  end if;
  v_order_id := (v_checkout->'order'->>'id')::uuid;
  v_order_num := v_checkout->'order'->>'order_number';
  if left(v_order_num, 1) <> '0' then
    raise exception 'Generated order number must keep leading zero: %', v_order_num;
  end if;

  -- Replay same attempt_id + version -> replayed = true, same order_id.
  v_checkout := public.kc_customer_checkout(v_cust1, 'Cust Satu', v_attempt_id, v_version);
  if not (v_checkout->>'replayed')::boolean or (v_checkout->'order'->>'id')::uuid <> v_order_id then
    raise exception 'Idempotent checkout replay failed: %', v_checkout;
  end if;

  -- Reusing old attempt_id with different cart version -> KC_IDEMPOTENCY_CONFLICT.
  begin
    perform public.kc_customer_checkout(v_cust1, 'Cust Satu', v_attempt_id, v_version + 1);
    raise exception 'Expected KC_IDEMPOTENCY_CONFLICT';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_IDEMPOTENCY_CONFLICT' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  -- Another customer cannot view or cancel v_cust1's order.
  if public.kc_customer_get_order(v_cust2, v_order_id) is not null then
    raise exception 'Customer 2 accessed Customer 1 order';
  end if;

  -- CUSTOMER-006A: active order indicator is true; submitting Owner app succeeds without auto-blocking.
  v_indicator := public.kc_admin_user_active_order_indicator(v_cust1);
  if not (v_indicator->>'has_active_orders')::boolean or (v_indicator->>'active_order_count')::integer <> 1 then
    raise exception 'Active order indicator mismatch: %', v_indicator;
  end if;
  perform public.kc_customer_submit_owner_application(v_cust1, 'Kantin Baru', 'USU Pintu 1', 'Ingin jualan');

  -- Duplicate pending Owner app rejected (ADMIN-002).
  begin
    perform public.kc_customer_submit_owner_application(v_cust1, 'Kantin Duplikat', 'USU', 'Duplikat');
    raise exception 'Expected KC_APPLICATION_ALREADY_PENDING';
  exception
    when sqlstate 'P0001' then get stacked diagnostics v_err = message_text;
    if v_err <> 'KC_APPLICATION_ALREADY_PENDING' then raise exception 'Unexpected err: %', v_err; end if;
  end;

  -- Cancel pending order transitions cleanly & decrements active indicator (and emits order_cancelled outbox).
  perform public.kc_customer_cancel_order(v_cust1, v_order_id);
  v_indicator := public.kc_admin_user_active_order_indicator(v_cust1);
  if (v_indicator->>'has_active_orders')::boolean or (v_indicator->>'active_order_count')::integer <> 0 then
    raise exception 'Cancelled order must not stay in active indicator: %', v_indicator;
  end if;
  if not exists (
    select 1 from public.order_notification_events
    where order_id = v_order_id and event_type = 'order_cancelled' and recipient_id = v_owner_a
  ) then
    raise exception 'Missing order_cancelled notification event';
  end if;
end;
$$;

reset role;
update auth.users
set banned_until = now() + interval '1 day'
where id = '00000000-0000-0000-0000-00000000c102';

set local role service_role;
do $$
declare
  v_stall_b uuid;
  v_detail jsonb;
begin
  select id into v_stall_b from public.catalog_stalls where owner_id = '00000000-0000-0000-0000-00000000c102';
  v_detail := public.kc_customer_get_stall_detail(v_stall_b);
  if (v_detail->'stall'->>'is_listed')::boolean is not true
     or (v_detail->'stall'->>'is_open')::boolean is not true
     or (v_detail->'stall'->>'owner_active')::boolean is not false then
    raise exception 'Banned owner stall must stay listed & open with owner_active=false: %', v_detail;
  end if;
end;
$$;

rollback;
