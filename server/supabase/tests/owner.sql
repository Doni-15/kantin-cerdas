-- Run against a disposable PostgreSQL database after all migrations (01..04).
begin;

-- 1. Verify RLS and least-privilege isolation for anon & authenticated
do $$
declare
  client_role text;
begin
  foreach client_role in array array['anon', 'authenticated'] loop
    if has_table_privilege(client_role, 'public.owner_stall_schedules', 'select')
       or has_table_privilege(client_role, 'public.owner_menu_categories', 'select')
       or has_table_privilege(client_role, 'public.orders', 'select')
       or has_table_privilege(client_role, 'public.order_items', 'select')
       or has_table_privilege(client_role, 'public.order_status_events', 'select')
       or has_table_privilege(client_role, 'public.order_notification_events', 'select')
       or has_function_privilege(client_role, 'public.kc_owner_create_stall(uuid,text,text,text,text,integer)', 'execute')
       or has_function_privilege(client_role, 'public.kc_owner_transition_order(uuid,uuid,text,text,boolean,boolean)', 'execute') then
      raise exception 'Unexpected Owner privilege for %', client_role;
    end if;
  end loop;
end;
$$;

-- 2. Seed test users (Owner A, Owner B, Inactive Owner C, Customer 1)
insert into auth.users (id, email, banned_until) values
  ('10000000-0000-0000-0000-000000000001', 'ownera@example.test', null),
  ('10000000-0000-0000-0000-000000000002', 'ownerb@example.test', null),
  ('10000000-0000-0000-0000-000000000003', 'ownerc@example.test', now() + interval '1 day'),
  ('10000000-0000-0000-0000-000000000004', 'customer1@example.test', null);

-- Verify bucket kantin-media exists and is private (checked as superuser/owner like verify_initial_schema.sql)
do $$
begin
  if not exists (
    select 1 from storage.buckets
    where id = 'kantin-media' and not public and file_size_limit = 2097152
  ) then
    raise exception 'Bucket kantin-media missing or misconfigured';
  end if;
end;
$$;

set local role service_role;

do $$
declare
  v_owner_a constant uuid := '10000000-0000-0000-0000-000000000001';
  v_owner_b constant uuid := '10000000-0000-0000-0000-000000000002';
  v_owner_c constant uuid := '10000000-0000-0000-0000-000000000003';
  v_cust    constant uuid := '10000000-0000-0000-0000-000000000004';
  v_res jsonb;
  v_stall_a uuid;
  v_stall_c uuid;
  v_cats jsonb;
  v_cat_makanan uuid;
  v_cat_camilan uuid;
  v_cat_custom uuid;
  v_menu_1 uuid;
  v_menu_2 uuid;
  v_order_1 uuid := '20000000-0000-0000-0000-000000000001';
  v_order_2 uuid := '20000000-0000-0000-0000-000000000002';
  v_order_3 uuid := '20000000-0000-0000-0000-000000000003';
  v_order_4 uuid := '20000000-0000-0000-0000-000000000004';
  v_order_5 uuid := '20000000-0000-0000-0000-000000000005';
begin

  -- OWNER-001 & OWNER-002: Create stall for Owner A; second stall must fail
  v_res := public.kc_owner_create_stall(v_owner_a, 'Kantin A', 'USU', 'Blok A-01', '', 15);
  v_stall_a := (v_res->'stall'->>'id')::uuid;
  if (v_res->'stall'->>'is_listed')::boolean or (v_res->'stall'->>'is_open')::boolean then
    raise exception 'New stall must start unpublished and closed';
  end if;

  begin
    perform public.kc_owner_create_stall(v_owner_a, 'Kantin A2', 'USU', 'Blok A-02', '', 10);
    raise exception 'Expected duplicate stall creation to fail';
  exception
    when others then
      if sqlerrm <> 'KC_STALL_ALREADY_EXISTS' then
        raise;
      end if;
  end;

  -- OWNER-004: Default 3 categories seeded
  v_cats := public.kc_owner_list_categories(v_owner_a);
  if jsonb_array_length(v_cats) <> 3 then
    raise exception 'Expected 3 default categories, got %', jsonb_array_length(v_cats);
  end if;
  v_cat_makanan := (v_cats->0->>'id')::uuid;
  v_cat_camilan := (v_cats->2->>'id')::uuid;

  -- OWNER-002: Cannot publish without at least 1 available menu
  begin
    perform public.kc_owner_publish_stall(v_owner_a);
    raise exception 'Publish without menus should fail';
  exception
    when others then
      if sqlerrm <> 'KC_PUBLISH_MENU_REQUIRED' then
        raise;
      end if;
  end;

  -- Add sold-out menu: publish must still fail
  v_res := public.kc_owner_create_menu(v_owner_a, 'Es Teh', v_cat_makanan, 5000, false, 'Dingin');
  v_menu_1 := (v_res->>'id')::uuid;
  begin
    perform public.kc_owner_publish_stall(v_owner_a);
    raise exception 'Publish with only sold-out menu should fail';
  exception
    when others then
      if sqlerrm <> 'KC_PUBLISH_MENU_REQUIRED' then
        raise;
      end if;
  end;

  -- Add available menu in custom category -> publish succeeds and starts Tutup!
  v_res := public.kc_owner_create_category(v_owner_a, 'Spesial');
  v_cat_custom := (v_res->>'id')::uuid;
  v_res := public.kc_owner_create_menu(v_owner_a, 'Nasi Goreng', v_cat_custom, 18000, true, '');
  v_menu_2 := (v_res->>'id')::uuid;

  v_res := public.kc_owner_publish_stall(v_owner_a);
  if not (v_res->'stall'->>'is_listed')::boolean or (v_res->'stall'->>'is_open')::boolean then
    raise exception 'Published stall must be listed and initially closed';
  end if;

  -- OWNER-002B: Unpublish via direct SQL update is blocked by trigger
  begin
    update public.catalog_stalls set is_listed = false where id = v_stall_a;
    raise exception 'Unpublish trigger failed to block';
  exception
    when others then
      if sqlerrm <> 'KC_UNPUBLISH_NOT_ALLOWED' then
        raise;
      end if;
  end;

  -- OWNER-004A: Archive menu_2 -> category Spesial STILL cannot be deleted!
  perform public.kc_owner_archive_menu(v_owner_a, v_menu_2);
  if public.kc_order_is_menu_orderable(v_menu_2) then
    raise exception 'Archived menu must not be orderable';
  end if;

  begin
    perform public.kc_owner_delete_category(v_owner_a, v_cat_custom);
    raise exception 'Deleting category with archived menu should fail';
  exception
    when others then
      if sqlerrm <> 'KC_CATEGORY_NOT_EMPTY' then
        raise;
      end if;
  end;

  -- Move archived menu_2 to Camilan -> now Spesial can be deleted
  perform public.kc_owner_update_menu(v_owner_a, v_menu_2, 'Nasi Goreng', v_cat_camilan, 20000, true, '');
  perform public.kc_owner_delete_category(v_owner_a, v_cat_custom);

  -- Restore menu_2 and open stall
  perform public.kc_owner_restore_menu(v_owner_a, v_menu_2);
  perform public.kc_owner_set_stall_open(v_owner_a, true);
  if not public.kc_order_is_menu_orderable(v_menu_2) then
    raise exception 'Restored available menu on open listed active stall must be orderable';
  end if;

  -- OWNER-002A: Even when all menus become sold-out or archived, stall stays listed and open
  perform public.kc_owner_set_menu_availability(v_owner_a, v_menu_2, false);
  if not exists (select 1 from public.kc_catalog_stalls('', null, v_stall_a, 1)) then
    raise exception 'Published stall with all menus unavailable must remain visible';
  end if;

  -- OWNER-003: Informative schedule does not toggle is_open
  perform public.kc_owner_set_stall_schedule(
    v_owner_a,
    jsonb_build_array(
      jsonb_build_object('day_of_week', 1, 'is_open_day', true, 'open_time', '08:00', 'close_time', '16:00'),
      jsonb_build_object('day_of_week', 2, 'is_open_day', false, 'open_time', null, 'close_time', null),
      jsonb_build_object('day_of_week', 3, 'is_open_day', false, 'open_time', null, 'close_time', null),
      jsonb_build_object('day_of_week', 4, 'is_open_day', false, 'open_time', null, 'close_time', null),
      jsonb_build_object('day_of_week', 5, 'is_open_day', false, 'open_time', null, 'close_time', null),
      jsonb_build_object('day_of_week', 6, 'is_open_day', false, 'open_time', null, 'close_time', null),
      jsonb_build_object('day_of_week', 7, 'is_open_day', false, 'open_time', null, 'close_time', null)
    )
  );

  -- ADMIN-003B: Inactive owner stall cannot accept new orders even when listed & open
  v_res := public.kc_owner_create_stall(v_owner_c, 'Kantin C', 'USU', 'Blok C', '', 10);
  v_stall_c := (v_res->'stall'->>'id')::uuid;
  v_cats := public.kc_owner_list_categories(v_owner_c);
  perform public.kc_owner_create_menu(v_owner_c, 'Mie', (v_cats->0->>'id')::uuid, 12000, true, '');
  perform public.kc_owner_publish_stall(v_owner_c);
  perform public.kc_owner_set_stall_open(v_owner_c, true);
  if public.kc_order_is_stall_accepting_orders(v_stall_c) then
    raise exception 'Inactive owner stall must not accept new orders';
  end if;

  -- Snapshot immutability + Order state transitions + Gagal Diambil
  insert into public.orders (id, order_number, stall_id, customer_id, customer_name, status, payment_status, total_amount)
  values
    (v_order_1, '0042', v_stall_a, v_cust, 'Budi', 'menunggu_konfirmasi', 'belum_lunas', 20000),
    (v_order_2, '0043', v_stall_a, v_cust, 'Sari', 'menunggu_konfirmasi', 'belum_lunas', 20000),
    (v_order_3, '0044', v_stall_a, v_cust, 'Andi', 'menunggu_konfirmasi', 'belum_lunas', 20000),
    (v_order_4, '0045', v_stall_a, v_cust, 'Rina', 'menunggu_konfirmasi', 'belum_lunas', 20000),
    (v_order_5, '0046', v_stall_a, v_cust, 'Tono', 'menunggu_konfirmasi', 'belum_lunas', 20000);

  insert into public.order_items (order_id, menu_item_id, menu_name, unit_price, quantity, line_total)
  values
    (v_order_1, v_menu_2, 'Nasi Goreng', 20000, 1, 20000),
    (v_order_2, v_menu_2, 'Nasi Goreng', 20000, 1, 20000);

  -- Edit menu price to 25000 and archive it -> existing order_items snapshot stays 20000!
  perform public.kc_owner_update_menu(v_owner_a, v_menu_2, 'Nasi Goreng Spesial', v_cat_camilan, 25000, true, '');
  perform public.kc_owner_archive_menu(v_owner_a, v_menu_2);
  if (select unit_price from public.order_items where order_id = v_order_1) <> 20000 then
    raise exception 'Order snapshot price changed after menu update';
  end if;

  -- Direct mutation/deletion of order_items snapshot must be blocked by trigger
  begin
    update public.order_items set unit_price = 99999 where order_id = v_order_1;
    raise exception 'Order snapshot update must fail';
  exception
    when others then
      if sqlerrm <> 'KC_ORDER_SNAPSHOT_IMMUTABLE' then
        raise;
      end if;
  end;
  begin
    delete from public.order_items where order_id = v_order_1;
    raise exception 'Order snapshot delete must fail';
  exception
    when others then
      if sqlerrm <> 'KC_ORDER_SNAPSHOT_IMMUTABLE' then
        raise;
      end if;
  end;

  -- Invariant check: non-selesai order cannot be lunas; notification event limited to 7 types
  begin
    update public.orders set payment_status = 'lunas' where id = v_order_1;
    raise exception 'orders_payment_status_invariant must block lunas before selesai';
  exception
    when check_violation then null;
  end;

  -- Leading zero lookup + Owner isolation
  if public.kc_owner_lookup_order(v_owner_a, '0042') is null then
    raise exception 'Lookup with leading zero failed';
  end if;
  if public.kc_owner_lookup_order(v_owner_b, '0042') is not null then
    raise exception 'Owner B must not see Owner A order';
  end if;

  -- Order 1: accept -> ready -> complete (Selesai + Lunas, no push event)
  v_res := public.kc_owner_transition_order(v_owner_a, v_order_1, 'accept');
  if (v_res->>'prep_estimate_minutes')::integer <> 15 then
    raise exception 'Accept must capture prep_estimate_minutes';
  end if;
  -- ORDER-013A: cannot fail_fulfillment from siap_diambil
  perform public.kc_owner_transition_order(v_owner_a, v_order_1, 'ready');
  begin
    perform public.kc_owner_transition_order(v_owner_a, v_order_1, 'fail_fulfillment', 'Habis');
    raise exception 'fail_fulfillment from siap_diambil must fail';
  exception
    when others then
      if sqlerrm <> 'KC_INVALID_ORDER_TRANSITION' then
        raise;
      end if;
  end;
  -- Complete requires both cash_received and food_handed_over
  v_res := public.kc_owner_transition_order(v_owner_a, v_order_1, 'complete', null, true, true);
  if v_res->>'status' <> 'selesai' or v_res->>'payment_status' <> 'lunas' then
    raise exception 'Complete must set selesai and lunas atomically';
  end if;

  -- Order 2: accept -> ready -> fail_pickup (Gagal Diambil, Belum Lunas, no push)
  perform public.kc_owner_transition_order(v_owner_a, v_order_2, 'accept');
  perform public.kc_owner_transition_order(v_owner_a, v_order_2, 'ready');
  begin
    perform public.kc_owner_transition_order(v_owner_a, v_order_2, 'fail_pickup', '   ');
    raise exception 'fail_pickup without reason must fail';
  exception
    when others then
      if sqlerrm <> 'KC_REASON_REQUIRED' then
        raise;
      end if;
  end;
  v_res := public.kc_owner_transition_order(v_owner_a, v_order_2, 'fail_pickup', 'Makanan tumpah');
  if v_res->>'status' <> 'gagal_diambil' or v_res->>'payment_status' <> 'belum_lunas'
     or v_res->>'status_reason' <> 'Makanan tumpah' then
    raise exception 'fail_pickup did not store gagal_diambil + belum_lunas + reason';
  end if;

  -- Verify ORDER-017A push outbox does NOT include selesai or gagal_diambil
  if exists (
    select 1 from public.order_notification_events
    where order_id = v_order_2 and event_type not in ('order_accepted', 'order_ready')
  ) then
    raise exception 'Unexpected push notification for gagal_diambil';
  end if;

  -- Order 3: reject (requires reason)
  v_res := public.kc_owner_transition_order(v_owner_a, v_order_3, 'reject', 'Bahan habis');
  if v_res->>'status' <> 'ditolak' or v_res->>'payment_status' <> 'belum_lunas' then
    raise exception 'Reject failed';
  end if;

  -- Order 4: accept -> fail_fulfillment
  perform public.kc_owner_transition_order(v_owner_a, v_order_4, 'accept');
  v_res := public.kc_owner_transition_order(v_owner_a, v_order_4, 'fail_fulfillment', 'Kompor mati');
  if v_res->>'status' <> 'gagal_dipenuhi' or v_res->>'payment_status' <> 'belum_lunas' then
    raise exception 'fail_fulfillment failed';
  end if;

  -- Order 5: accept -> ready -> not_picked_up
  perform public.kc_owner_transition_order(v_owner_a, v_order_5, 'accept');
  perform public.kc_owner_transition_order(v_owner_a, v_order_5, 'ready');
  v_res := public.kc_owner_transition_order(v_owner_a, v_order_5, 'not_picked_up');
  if v_res->>'status' <> 'tidak_diambil' or v_res->>'payment_status' <> 'belum_lunas' then
    raise exception 'not_picked_up failed';
  end if;
end;
$$;

rollback;
