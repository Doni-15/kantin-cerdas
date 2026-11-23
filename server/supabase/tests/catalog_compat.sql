-- Catalog compatibility test after Owner migrations (OWNER-002 one-owner-one-stall).
-- Historical server/supabase/tests/catalog.sql seeded 3 stalls under 1 owner_id prior
-- to OWNER-002's unique index `catalog_stalls_one_per_owner` and is preserved unchanged.
-- This test uses distinct owners per stall to verify Catalog + Owner behavior together.
begin;

do $$
declare
  client_role text;
begin
  foreach client_role in array array['anon', 'authenticated'] loop
    if has_table_privilege(client_role, 'public.catalog_stalls', 'select')
       or has_table_privilege(client_role, 'public.catalog_menu_items', 'select')
       or has_function_privilege(client_role, 'public.kc_catalog_stalls(text,uuid,uuid,integer)', 'execute')
       or has_function_privilege(client_role, 'public.kc_catalog_menu(text,uuid,uuid,integer)', 'execute') then
      raise exception 'Unexpected catalog privilege for %', client_role;
    end if;
  end loop;
end;
$$;

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-000000001101', 'compat1@example.test'),
  ('00000000-0000-0000-0000-000000001102', 'compat2@example.test'),
  ('00000000-0000-0000-0000-000000001103', 'compat3@example.test');

set local role service_role;

insert into public.catalog_stalls (id, owner_id, name, campus, block, is_listed, is_open) values
  ('00000000-0000-0000-0000-000000001001', '00000000-0000-0000-0000-000000001101', 'QA-KC-7639 % Dapur', 'USU', 'A', true, false),
  ('00000000-0000-0000-0000-000000001002', '00000000-0000-0000-0000-000000001102', 'QA-KC-7639 Kopi', 'USU', 'B', true, true),
  ('00000000-0000-0000-0000-000000001003', '00000000-0000-0000-0000-000000001103', 'QA-KC-7639 Tersembunyi', 'USU', 'A', false, true);

insert into public.owner_menu_categories (id, stall_id, name, sort_order) values
  ('00000000-0000-0000-0000-000000001301', '00000000-0000-0000-0000-000000001001', 'Makanan', 1),
  ('00000000-0000-0000-0000-000000001303', '00000000-0000-0000-0000-000000001003', 'Makanan', 1);

insert into public.catalog_menu_items (id, stall_id, category_id, name, category, price, is_listed, is_archived, is_available) values
  ('00000000-0000-0000-0000-000000001201', '00000000-0000-0000-0000-000000001001', '00000000-0000-0000-0000-000000001301', 'Nasi ayam', 'Makanan', 15000, true, false, true),
  ('00000000-0000-0000-0000-000000001202', '00000000-0000-0000-0000-000000001001', '00000000-0000-0000-0000-000000001301', 'Menu tersembunyi', 'Makanan', 15000, false, true, true),
  ('00000000-0000-0000-0000-000000001203', '00000000-0000-0000-0000-000000001003', '00000000-0000-0000-0000-000000001303', 'Menu pada stan tersembunyi', 'Makanan', 15000, true, false, true);

do $$
declare
  first_id constant uuid := '00000000-0000-0000-0000-000000001001';
  second_id constant uuid := '00000000-0000-0000-0000-000000001002';
  hidden_id constant uuid := '00000000-0000-0000-0000-000000001003';
  visible_menu constant uuid := '00000000-0000-0000-0000-000000001201';
  result jsonb;
begin
  if (select array_agg(id) from public.kc_catalog_stalls('qa-kc-7639', null, null, 1))
      is distinct from array[first_id] then
    raise exception 'Incorrect first stall page';
  end if;
  if (select array_agg(id) from public.kc_catalog_stalls('qa-kc-7639', first_id, null, 40))
      is distinct from array[second_id] then
    raise exception 'Incorrect next stall page';
  end if;
  if (select array_agg(id) from public.kc_catalog_stalls('qa-kc-7639 %', null, null, 40))
      is distinct from array[first_id] then
    raise exception 'Search must match percent signs literally';
  end if;
  if exists (select from public.kc_catalog_stalls('', null, hidden_id, 1)) then
    raise exception 'An unlisted stall was disclosed';
  end if;
  select item into strict result from public.kc_catalog_stalls('', null, first_id, 1);
  if result ?| array['owner_id', 'is_listed'] then
    raise exception 'Stall payload contains internal fields';
  end if;
  if (select array_agg(id) from public.kc_catalog_menu('qa-kc-7639', null, null, 40))
      is distinct from array[visible_menu] then
    raise exception 'Menu search included an archived menu or unlisted stall';
  end if;
  select item into strict result from public.kc_catalog_menu('mAKanan', null, first_id, 40);
  if result->>'stall_id' is distinct from first_id::text
      or result->>'price' is distinct from '15000'
      or result->>'stall_is_open' is distinct from 'false'
      or result->>'is_available' is distinct from 'true' then
    raise exception 'Menu payload does not preserve price and availability';
  end if;
  if exists (select from public.kc_catalog_menu('', null, second_id, 40)) then
    raise exception 'Stall menu includes another stall';
  end if;
end;
$$;

rollback;
