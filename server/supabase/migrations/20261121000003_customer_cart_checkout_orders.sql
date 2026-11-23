-- Customer module forward-only schema:
-- persistent single-stall carts, idempotent atomic cash checkout,
-- customer order read/cancel helpers, Admin active-order indicator, and Owner applications.
begin;

-- =============================================================================
-- 1. Order number sequence preserving leading zeros as text (ORDER-015 / BARCODE-TECH-001)
-- =============================================================================
create sequence if not exists public.kc_order_number_seq
  as bigint
  start with 1
  increment by 1
  minvalue 1;

create unique index if not exists orders_customer_idempotency_unique
  on public.orders (customer_id, idempotency_key)
  where idempotency_key is not null;

-- =============================================================================
-- 2. Persistent per-account Customer cart & items (ORDER-005..010, OWNER-005A)
-- =============================================================================
create table public.customer_carts (
  customer_id uuid primary key references auth.users(id) on delete cascade,
  stall_id uuid null references public.catalog_stalls(id) on delete set null,
  general_note text not null default '' check (char_length(general_note) <= 500),
  draft_version integer not null default 1 check (draft_version >= 1),
  updated_at timestamptz not null default now()
);

create table public.customer_cart_items (
  id uuid primary key default gen_random_uuid(),
  cart_id uuid not null references public.customer_carts(customer_id) on delete cascade,
  menu_item_id uuid not null references public.catalog_menu_items(id) on delete restrict,
  quantity integer not null check (quantity >= 1),
  item_note text not null default '' check (char_length(item_note) <= 300),
  seen_unit_price integer not null check (seen_unit_price >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index customer_cart_items_unique_line
  on public.customer_cart_items (cart_id, menu_item_id, item_note);

create index customer_cart_items_cart_created
  on public.customer_cart_items (cart_id, created_at, id);

alter table public.customer_carts enable row level security;
alter table public.customer_cart_items enable row level security;
revoke all on public.customer_carts, public.customer_cart_items
  from public, anon, authenticated;
grant select, insert, update, delete on public.customer_carts, public.customer_cart_items
  to service_role;

-- =============================================================================
-- 3. Logical checkout attempts for idempotency & connection drop recovery (ORDER-008, DB-TECH-002)
-- =============================================================================
create table public.customer_checkout_attempts (
  customer_id uuid not null references auth.users(id) on delete cascade,
  attempt_id uuid not null,
  cart_version integer not null check (cart_version >= 1),
  payload_hash text not null check (char_length(payload_hash) between 8 and 128),
  status text not null check (status in ('pending', 'committed')),
  order_id uuid null unique references public.orders(id),
  created_at timestamptz not null default now(),
  committed_at timestamptz null,
  primary key (customer_id, attempt_id)
);

create index customer_checkout_attempts_pending_lookup
  on public.customer_checkout_attempts (customer_id, cart_version, payload_hash, created_at desc);

alter table public.customer_checkout_attempts enable row level security;
revoke all on public.customer_checkout_attempts from public, anon, authenticated;
grant select, insert, update, delete on public.customer_checkout_attempts to service_role;

-- =============================================================================
-- 4. Owner applications (ADMIN-001, ADMIN-002, CUSTOMER-006A)
-- =============================================================================
create table public.owner_applications (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users(id) on delete cascade,
  planned_stall_name text not null check (char_length(btrim(planned_stall_name)) between 1 and 120),
  planned_location text not null check (char_length(btrim(planned_location)) between 1 and 120),
  reason text not null check (char_length(btrim(reason)) between 1 and 500),
  status text not null default 'menunggu_review'
    check (status in ('menunggu_review', 'disetujui', 'ditolak')),
  rejection_reason text null
    check (rejection_reason is null or char_length(btrim(rejection_reason)) between 1 and 500),
  decided_by uuid null references auth.users(id),
  decided_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ADMIN-002: maximum one pending application per Customer.
create unique index owner_applications_one_pending_per_customer
  on public.owner_applications (customer_id)
  where status = 'menunggu_review';

create index owner_applications_customer_created
  on public.owner_applications (customer_id, created_at desc);

alter table public.owner_applications enable row level security;
revoke all on public.owner_applications from public, anon, authenticated;
grant select, insert, update, delete on public.owner_applications to service_role;

-- =============================================================================
-- 5. Admin active-order indicator helper (CUSTOMER-006A, ADMIN-002, ADMIN-003A)
-- =============================================================================
create function public.kc_admin_user_active_order_indicator(p_user_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with counts as (
    select count(*)::integer as active_count
    from public.orders o
    join public.catalog_stalls s on s.id = o.stall_id
    where (o.customer_id = p_user_id or s.owner_id = p_user_id)
      and o.status in ('menunggu_konfirmasi', 'diproses', 'siap_diambil')
  )
  select jsonb_build_object(
    'user_id', p_user_id,
    'has_active_orders', active_count > 0,
    'active_order_count', active_count
  )
  from counts;
$$;

-- =============================================================================
-- 6. Customer Stall & Menu Detail + Private Photo Paths (CUSTOMER-002, ADMIN-003B)
-- =============================================================================
create function public.kc_customer_get_stall_detail(p_stall_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stall public.catalog_stalls%rowtype;
  v_owner_active boolean := false;
  v_schedules jsonb;
  v_categories jsonb;
  v_menus jsonb;
begin
  select s.*
  into v_stall
  from public.catalog_stalls s
  where s.id = p_stall_id
    and s.is_listed;

  if not found then
    return null;
  end if;

  select (u.banned_until is null or u.banned_until <= now())
  into v_owner_active
  from auth.users u
  where u.id = v_stall.owner_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'day_of_week', sch.day_of_week,
        'is_open_day', sch.is_open_day,
        'open_time', to_char(sch.open_time, 'HH24:MI'),
        'close_time', to_char(sch.close_time, 'HH24:MI')
      )
      order by sch.day_of_week
    ),
    '[]'::jsonb
  )
  into v_schedules
  from public.owner_stall_schedules sch
  where sch.stall_id = v_stall.id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', c.id,
        'name', c.name,
        'sort_order', c.sort_order
      )
      order by c.sort_order, lower(c.name), c.id
    ),
    '[]'::jsonb
  )
  into v_categories
  from public.owner_menu_categories c
  where c.stall_id = v_stall.id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', m.id,
        'stall_id', m.stall_id,
        'category_id', m.category_id,
        'category_name', coalesce(c.name, m.category),
        'name', m.name,
        'description', m.description,
        'price', m.price,
        'is_available', m.is_available,
        'has_photo', m.photo_path is not null
      )
      order by coalesce(c.sort_order, 9999), lower(m.name), m.id
    ),
    '[]'::jsonb
  )
  into v_menus
  from public.catalog_menu_items m
  left join public.owner_menu_categories c on c.id = m.category_id
  where m.stall_id = v_stall.id
    and m.is_listed
    and not m.is_archived;

  return jsonb_build_object(
    'stall', jsonb_build_object(
      'id', v_stall.id,
      'name', v_stall.name,
      'block', v_stall.block,
      'description', v_stall.description,
      'wait_minutes', v_stall.wait_minutes,
      'is_listed', v_stall.is_listed,
      'is_open', v_stall.is_open,
      'owner_active', coalesce(v_owner_active, false),
      'has_photo', v_stall.photo_path is not null
    ),
    'schedules', v_schedules,
    'categories', v_categories,
    'menus', v_menus
  );
end;
$$;

create function public.kc_customer_get_menu_detail(p_menu_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_menu public.catalog_menu_items%rowtype;
  v_stall public.catalog_stalls%rowtype;
  v_owner_active boolean := false;
  v_category_name text;
begin
  select m.*
  into v_menu
  from public.catalog_menu_items m
  join public.catalog_stalls s on s.id = m.stall_id
  where m.id = p_menu_id
    and s.is_listed
    and m.is_listed
    and not m.is_archived;

  if not found then
    return null;
  end if;

  select s.*
  into v_stall
  from public.catalog_stalls s
  where s.id = v_menu.stall_id;

  select (u.banned_until is null or u.banned_until <= now())
  into v_owner_active
  from auth.users u
  where u.id = v_stall.owner_id;

  select c.name
  into v_category_name
  from public.owner_menu_categories c
  where c.id = v_menu.category_id;

  return jsonb_build_object(
    'menu', jsonb_build_object(
      'id', v_menu.id,
      'stall_id', v_menu.stall_id,
      'category_id', v_menu.category_id,
      'category_name', coalesce(v_category_name, v_menu.category),
      'name', v_menu.name,
      'description', v_menu.description,
      'price', v_menu.price,
      'is_available', v_menu.is_available,
      'has_photo', v_menu.photo_path is not null
    ),
    'stall', jsonb_build_object(
      'id', v_stall.id,
      'name', v_stall.name,
      'block', v_stall.block,
      'description', v_stall.description,
      'wait_minutes', v_stall.wait_minutes,
      'is_listed', v_stall.is_listed,
      'is_open', v_stall.is_open,
      'owner_active', coalesce(v_owner_active, false),
      'has_photo', v_stall.photo_path is not null
    )
  );
end;
$$;

create function public.kc_customer_get_stall_photo_path(p_stall_id uuid)
returns text
language sql
stable
security invoker
set search_path = ''
as $$
  select s.photo_path
  from public.catalog_stalls s
  where s.id = p_stall_id
    and s.is_listed
    and s.photo_path is not null;
$$;

create function public.kc_customer_get_menu_photo_path(p_menu_id uuid)
returns text
language sql
stable
security invoker
set search_path = ''
as $$
  select m.photo_path
  from public.catalog_menu_items m
  join public.catalog_stalls s on s.id = m.stall_id
  where m.id = p_menu_id
    and s.is_listed
    and m.photo_path is not null;
$$;

-- =============================================================================
-- 7. Internal Cart Signature & Hydrated Cart Reader
-- =============================================================================
create function public.kc_customer_cart_signature(p_customer_id uuid)
returns text
language sql
stable
security invoker
set search_path = ''
as $$
  select md5(
    coalesce(c.stall_id::text, '') || '|' ||
    c.general_note || '|' ||
    coalesce((
      select string_agg(
        ci.menu_item_id::text || ':' ||
        ci.quantity::text || ':' ||
        ci.seen_unit_price::text || ':' ||
        ci.item_note,
        ';' order by ci.menu_item_id, ci.item_note
      )
      from public.customer_cart_items ci
      where ci.cart_id = c.customer_id
    ), '')
  )
  from public.customer_carts c
  where c.customer_id = p_customer_id;
$$;

create function public.kc_customer_get_cart(p_customer_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_cart public.customer_carts%rowtype;
  v_stall public.catalog_stalls%rowtype;
  v_owner_active boolean := false;
  v_items jsonb := '[]'::jsonb;
  v_blockers text[] := array[]::text[];
  v_subtotal integer := 0;
  v_seen_subtotal integer := 0;
  v_item_count integer := 0;
  v_has_archived boolean := false;
  v_has_unavailable boolean := false;
  v_has_price_change boolean := false;
begin
  select *
  into v_cart
  from public.customer_carts c
  where c.customer_id = p_customer_id;

  if not found or v_cart.stall_id is null then
    return jsonb_build_object(
      'stall', null,
      'items', '[]'::jsonb,
      'general_note', coalesce(v_cart.general_note, ''),
      'draft_version', coalesce(v_cart.draft_version, 0),
      'subtotal', 0,
      'seen_subtotal', 0,
      'item_count', 0,
      'can_checkout', false,
      'blockers', '[]'::jsonb
    );
  end if;

  select *
  into v_stall
  from public.catalog_stalls s
  where s.id = v_cart.stall_id;

  if found then
    select (u.banned_until is null or u.banned_until <= now())
    into v_owner_active
    from auth.users u
    where u.id = v_stall.owner_id;
  end if;

  select
    coalesce(jsonb_agg(
      jsonb_build_object(
        'id', ci.id,
        'menu_item_id', ci.menu_item_id,
        'menu_name', m.name,
        'category_name', coalesce(cat.name, m.category),
        'quantity', ci.quantity,
        'item_note', ci.item_note,
        'seen_unit_price', ci.seen_unit_price,
        'current_unit_price', m.price,
        'line_total', m.price * ci.quantity,
        'price_changed', m.price <> ci.seen_unit_price,
        'is_available', m.is_available,
        'is_archived', m.is_archived,
        'has_photo', m.photo_path is not null
      )
      order by ci.created_at asc, ci.id asc
    ), '[]'::jsonb),
    coalesce(sum(m.price * ci.quantity)::integer, 0),
    coalesce(sum(ci.seen_unit_price * ci.quantity)::integer, 0),
    coalesce(sum(ci.quantity)::integer, 0),
    coalesce(bool_or(m.is_archived), false),
    coalesce(bool_or(not m.is_archived and not m.is_available), false),
    coalesce(bool_or(m.price <> ci.seen_unit_price), false)
  into
    v_items,
    v_subtotal,
    v_seen_subtotal,
    v_item_count,
    v_has_archived,
    v_has_unavailable,
    v_has_price_change
  from public.customer_cart_items ci
  join public.catalog_menu_items m on m.id = ci.menu_item_id
  left join public.owner_menu_categories cat on cat.id = m.category_id
  where ci.cart_id = v_cart.customer_id;

  if jsonb_array_length(v_items) = 0 then
    return jsonb_build_object(
      'stall', null,
      'items', '[]'::jsonb,
      'general_note', '',
      'draft_version', v_cart.draft_version,
      'subtotal', 0,
      'seen_subtotal', 0,
      'item_count', 0,
      'can_checkout', false,
      'blockers', '[]'::jsonb
    );
  end if;

  if v_stall.id is null or not v_stall.is_listed then
    v_blockers := array_append(v_blockers, 'stall_unlisted');
  end if;
  if v_stall.id is null or not v_stall.is_open then
    v_blockers := array_append(v_blockers, 'stall_closed');
  end if;
  if not coalesce(v_owner_active, false) then
    v_blockers := array_append(v_blockers, 'owner_inactive');
  end if;
  if v_has_archived then
    v_blockers := array_append(v_blockers, 'has_archived_item');
  end if;
  if v_has_unavailable then
    v_blockers := array_append(v_blockers, 'has_unavailable_item');
  end if;
  if v_has_price_change then
    v_blockers := array_append(v_blockers, 'has_price_change');
  end if;

  return jsonb_build_object(
    'stall', jsonb_build_object(
      'id', v_stall.id,
      'name', v_stall.name,
      'block', v_stall.block,
      'description', v_stall.description,
      'wait_minutes', v_stall.wait_minutes,
      'is_listed', v_stall.is_listed,
      'is_open', v_stall.is_open,
      'owner_active', coalesce(v_owner_active, false),
      'has_photo', v_stall.photo_path is not null
    ),
    'items', v_items,
    'general_note', v_cart.general_note,
    'draft_version', v_cart.draft_version,
    'subtotal', v_subtotal,
    'seen_subtotal', v_seen_subtotal,
    'item_count', v_item_count,
    'can_checkout', coalesce(array_length(v_blockers, 1), 0) = 0,
    'blockers', to_jsonb(v_blockers)
  );
end;
$$;

-- =============================================================================
-- 8. Cart Mutations (ORDER-005..010, OWNER-005A)
-- =============================================================================
create function public.kc_customer_add_cart_item(
  p_customer_id uuid,
  p_menu_id uuid,
  p_quantity integer default 1,
  p_item_note text default '',
  p_replace_stall boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_qty integer := coalesce(p_quantity, 1);
  v_note text := btrim(coalesce(p_item_note, ''));
  v_menu public.catalog_menu_items%rowtype;
  v_stall public.catalog_stalls%rowtype;
  v_owner_active boolean := false;
  v_cart public.customer_carts%rowtype;
  v_has_existing boolean := false;
begin
  if v_qty < 1 or v_qty > 999 or char_length(v_note) > 300 then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  select m.*
  into v_menu
  from public.catalog_menu_items m
  where m.id = p_menu_id;

  if not found then
    raise exception 'KC_MENU_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_MENU_NOT_FOUND';
  end if;

  select s.*
  into v_stall
  from public.catalog_stalls s
  where s.id = v_menu.stall_id;

  if not found or not v_stall.is_listed then
    raise exception 'KC_MENU_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_MENU_NOT_FOUND';
  end if;

  select (u.banned_until is null or u.banned_until <= now())
  into v_owner_active
  from auth.users u
  where u.id = v_stall.owner_id;

  if not coalesce(v_owner_active, false) then
    raise exception 'KC_OWNER_INACTIVE'
      using errcode = 'P0001', detail = 'KC_OWNER_INACTIVE';
  end if;

  if not v_stall.is_open then
    raise exception 'KC_STALL_CLOSED'
      using errcode = 'P0001', detail = 'KC_STALL_CLOSED';
  end if;

  if v_menu.is_archived or not v_menu.is_listed then
    raise exception 'KC_MENU_ARCHIVED'
      using errcode = 'P0001', detail = 'KC_MENU_ARCHIVED';
  end if;

  if not v_menu.is_available then
    raise exception 'KC_MENU_UNAVAILABLE'
      using errcode = 'P0001', detail = 'KC_MENU_UNAVAILABLE';
  end if;

  insert into public.customer_carts (customer_id, stall_id)
  values (p_customer_id, v_stall.id)
  on conflict (customer_id) do nothing;

  select *
  into v_cart
  from public.customer_carts c
  where c.customer_id = p_customer_id
  for update;

  select exists (
    select 1
    from public.customer_cart_items ci
    where ci.cart_id = p_customer_id
  )
  into v_has_existing;

  if v_has_existing and v_cart.stall_id is distinct from v_stall.id then
    if not coalesce(p_replace_stall, false) then
      raise exception 'KC_CART_DIFFERENT_STALL'
        using errcode = 'P0001', detail = 'KC_CART_DIFFERENT_STALL';
    end if;

    delete from public.customer_cart_items
    where cart_id = p_customer_id;

    update public.customer_carts
    set stall_id = v_stall.id,
        general_note = '',
        draft_version = draft_version + 1,
        updated_at = now()
    where customer_id = p_customer_id;
  elsif v_cart.stall_id is null or not v_has_existing then
    update public.customer_carts
    set stall_id = v_stall.id,
        general_note = case when v_has_existing then general_note else '' end,
        draft_version = draft_version + 1,
        updated_at = now()
    where customer_id = p_customer_id;
  else
    update public.customer_carts
    set draft_version = draft_version + 1,
        updated_at = now()
    where customer_id = p_customer_id;
  end if;

  insert into public.customer_cart_items (
    cart_id, menu_item_id, quantity, item_note, seen_unit_price
  )
  values (
    p_customer_id, v_menu.id, v_qty, v_note, v_menu.price
  )
  on conflict (cart_id, menu_item_id, item_note) do update
  set quantity = least(public.customer_cart_items.quantity + excluded.quantity, 999),
      seen_unit_price = excluded.seen_unit_price,
      updated_at = now();

  return public.kc_customer_get_cart(p_customer_id);
end;
$$;

create function public.kc_customer_update_cart_item(
  p_customer_id uuid,
  p_item_id uuid,
  p_quantity integer,
  p_item_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cart public.customer_carts%rowtype;
  v_item public.customer_cart_items%rowtype;
  v_menu public.catalog_menu_items%rowtype;
  v_stall public.catalog_stalls%rowtype;
  v_owner_active boolean := false;
  v_next_note text;
  v_duplicate public.customer_cart_items%rowtype;
begin
  if p_quantity is null or p_quantity < 0 or p_quantity > 999 then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  select *
  into v_cart
  from public.customer_carts c
  where c.customer_id = p_customer_id
  for update;

  if not found then
    raise exception 'KC_CART_ITEM_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_CART_ITEM_NOT_FOUND';
  end if;

  select *
  into v_item
  from public.customer_cart_items ci
  where ci.id = p_item_id
    and ci.cart_id = p_customer_id
  for update;

  if not found then
    raise exception 'KC_CART_ITEM_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_CART_ITEM_NOT_FOUND';
  end if;

  if p_quantity = 0 then
    delete from public.customer_cart_items
    where id = v_item.id;
  else
    v_next_note := case
      when p_item_note is null then v_item.item_note
      else btrim(p_item_note)
    end;
    if char_length(v_next_note) > 300 then
      raise exception 'KC_INVALID_INPUT'
        using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
    end if;

    -- Increasing quantity requires the menu and stall to be currently orderable.
    if p_quantity > v_item.quantity then
      select m.* into v_menu from public.catalog_menu_items m where m.id = v_item.menu_item_id;
      select s.* into v_stall from public.catalog_stalls s where s.id = v_menu.stall_id;
      select (u.banned_until is null or u.banned_until <= now())
      into v_owner_active
      from auth.users u
      where u.id = v_stall.owner_id;

      if not coalesce(v_owner_active, false) then
        raise exception 'KC_OWNER_INACTIVE'
          using errcode = 'P0001', detail = 'KC_OWNER_INACTIVE';
      end if;
      if not v_stall.is_listed or not v_stall.is_open then
        raise exception 'KC_STALL_CLOSED'
          using errcode = 'P0001', detail = 'KC_STALL_CLOSED';
      end if;
      if v_menu.is_archived or not v_menu.is_listed then
        raise exception 'KC_MENU_ARCHIVED'
          using errcode = 'P0001', detail = 'KC_MENU_ARCHIVED';
      end if;
      if not v_menu.is_available then
        raise exception 'KC_MENU_UNAVAILABLE'
          using errcode = 'P0001', detail = 'KC_MENU_UNAVAILABLE';
      end if;
    end if;

    select *
    into v_duplicate
    from public.customer_cart_items ci
    where ci.cart_id = p_customer_id
      and ci.menu_item_id = v_item.menu_item_id
      and ci.item_note = v_next_note
      and ci.id <> v_item.id;

    if found then
      update public.customer_cart_items
      set quantity = least(v_duplicate.quantity + p_quantity, 999),
          seen_unit_price = v_item.seen_unit_price,
          updated_at = now()
      where id = v_duplicate.id;

      delete from public.customer_cart_items
      where id = v_item.id;
    else
      update public.customer_cart_items
      set quantity = p_quantity,
          item_note = v_next_note,
          updated_at = now()
      where id = v_item.id;
    end if;
  end if;

  if exists (select 1 from public.customer_cart_items ci where ci.cart_id = p_customer_id) then
    update public.customer_carts
    set draft_version = draft_version + 1,
        updated_at = now()
    where customer_id = p_customer_id;
  else
    update public.customer_carts
    set stall_id = null,
        general_note = '',
        draft_version = draft_version + 1,
        updated_at = now()
    where customer_id = p_customer_id;
  end if;

  return public.kc_customer_get_cart(p_customer_id);
end;
$$;

create function public.kc_customer_set_cart_note(
  p_customer_id uuid,
  p_general_note text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_note text := btrim(coalesce(p_general_note, ''));
begin
  if char_length(v_note) > 500 then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  update public.customer_carts
  set general_note = v_note,
      draft_version = draft_version + 1,
      updated_at = now()
  where customer_id = p_customer_id;

  return public.kc_customer_get_cart(p_customer_id);
end;
$$;

create function public.kc_customer_acknowledge_cart_prices(
  p_customer_id uuid,
  p_expected_version integer default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cart public.customer_carts%rowtype;
begin
  select *
  into v_cart
  from public.customer_carts c
  where c.customer_id = p_customer_id
  for update;

  if not found then
    return public.kc_customer_get_cart(p_customer_id);
  end if;

  if p_expected_version is not null and v_cart.draft_version <> p_expected_version then
    raise exception 'KC_CART_VERSION_CONFLICT'
      using errcode = 'P0001', detail = 'KC_CART_VERSION_CONFLICT';
  end if;

  update public.customer_cart_items ci
  set seen_unit_price = m.price,
      updated_at = now()
  from public.catalog_menu_items m
  where ci.cart_id = p_customer_id
    and m.id = ci.menu_item_id
    and ci.seen_unit_price <> m.price;

  update public.customer_carts
  set draft_version = draft_version + 1,
      updated_at = now()
  where customer_id = p_customer_id;

  return public.kc_customer_get_cart(p_customer_id);
end;
$$;

create function public.kc_customer_clear_cart(p_customer_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.customer_cart_items
  where cart_id = p_customer_id;

  update public.customer_carts
  set stall_id = null,
      general_note = '',
      draft_version = draft_version + 1,
      updated_at = now()
  where customer_id = p_customer_id;

  return public.kc_customer_get_cart(p_customer_id);
end;
$$;

-- =============================================================================
-- 9. Customer Orders Queries, Idempotent Atomic Checkout, & Pending Cancel
-- =============================================================================
create function public.kc_customer_order_summary_json(
  p_order public.orders,
  p_stall public.catalog_stalls
)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'id', p_order.id,
    'order_number', p_order.order_number,
    'stall_id', p_order.stall_id,
    'stall_name', p_stall.name,
    'stall_block', p_stall.block,
    'stall_campus', p_stall.campus,
    'customer_name', p_order.customer_name,
    'status', p_order.status,
    'payment_status', p_order.payment_status,
    'general_note', p_order.general_note,
    'total_amount', p_order.total_amount,
    'prep_estimate_minutes', p_order.prep_estimate_minutes,
    'status_reason', p_order.status_reason,
    'created_at', p_order.created_at,
    'accepted_at', p_order.accepted_at,
    'ready_at', p_order.ready_at,
    'terminal_at', p_order.terminal_at,
    'updated_at', p_order.updated_at,
    'item_summary', coalesce((
      select string_agg(oi.quantity::text || 'x ' || oi.menu_name, ', ' order by oi.id)
      from public.order_items oi
      where oi.order_id = p_order.id
    ), ''),
    'item_count', coalesce((
      select sum(oi.quantity)::integer
      from public.order_items oi
      where oi.order_id = p_order.id
    ), 0)
  );
$$;

create function public.kc_customer_list_orders(
  p_customer_id uuid,
  p_scope text default 'active',
  p_limit integer default 30,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_limit integer := least(greatest(coalesce(p_limit, 30), 1), 100);
  v_offset integer := greatest(coalesce(p_offset, 0), 0);
  v_items jsonb;
begin
  if p_scope not in ('active', 'history') then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  select coalesce(jsonb_agg(sub.summary), '[]'::jsonb)
  into v_items
  from (
    select public.kc_customer_order_summary_json(o, s) as summary
    from public.orders o
    join public.catalog_stalls s on s.id = o.stall_id
    where o.customer_id = p_customer_id
      and (
        (p_scope = 'active' and o.status in ('menunggu_konfirmasi', 'diproses', 'siap_diambil'))
        or (p_scope = 'history' and o.status in ('selesai', 'dibatalkan', 'ditolak', 'gagal_dipenuhi', 'tidak_diambil', 'gagal_diambil'))
      )
    order by
      case when p_scope = 'active' then o.created_at end desc,
      case when p_scope = 'history' then coalesce(o.terminal_at, o.updated_at) end desc,
      o.id desc
    limit v_limit + 1
    offset v_offset
  ) sub;

  return jsonb_build_object(
    'items',
    case
      when jsonb_array_length(v_items) > v_limit then
        (select coalesce(jsonb_agg(elem), '[]'::jsonb)
         from jsonb_array_elements(v_items) with ordinality as t(elem, ord)
         where ord <= v_limit)
      else v_items
    end,
    'has_more', jsonb_array_length(v_items) > v_limit
  );
end;
$$;

create function public.kc_customer_get_order(
  p_customer_id uuid,
  p_order_id uuid
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_stall public.catalog_stalls%rowtype;
  v_items jsonb;
  v_events jsonb;
begin
  select o.*
  into v_order
  from public.orders o
  where o.id = p_order_id
    and o.customer_id = p_customer_id;

  if not found then
    return null;
  end if;

  select *
  into v_stall
  from public.catalog_stalls s
  where s.id = v_order.stall_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', oi.id,
        'menu_item_id', oi.menu_item_id,
        'menu_name', oi.menu_name,
        'unit_price', oi.unit_price,
        'quantity', oi.quantity,
        'line_total', oi.line_total,
        'item_note', oi.item_note
      )
      order by oi.id
    ),
    '[]'::jsonb
  )
  into v_items
  from public.order_items oi
  where oi.order_id = v_order.id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', ev.id,
        'from_status', ev.from_status,
        'to_status', ev.to_status,
        'actor_role', ev.actor_role,
        'reason', ev.reason,
        'created_at', ev.created_at
      )
      order by ev.created_at asc, ev.id asc
    ),
    '[]'::jsonb
  )
  into v_events
  from public.order_status_events ev
  where ev.order_id = v_order.id;

  return public.kc_customer_order_summary_json(v_order, v_stall) || jsonb_build_object(
    'items', v_items,
    'events', v_events
  );
end;
$$;

create function public.kc_customer_create_checkout_attempt(
  p_customer_id uuid,
  p_expected_version integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cart public.customer_carts%rowtype;
  v_has_items boolean;
  v_hash text;
  v_attempt public.customer_checkout_attempts%rowtype;
  v_attempt_id uuid;
begin
  select *
  into v_cart
  from public.customer_carts c
  where c.customer_id = p_customer_id
  for update;

  select exists (
    select 1 from public.customer_cart_items ci where ci.cart_id = p_customer_id
  )
  into v_has_items;

  if not found or v_cart.stall_id is null or not v_has_items then
    raise exception 'KC_CART_EMPTY'
      using errcode = 'P0001', detail = 'KC_CART_EMPTY';
  end if;

  if v_cart.draft_version <> p_expected_version then
    raise exception 'KC_CART_VERSION_CONFLICT'
      using errcode = 'P0001', detail = 'KC_CART_VERSION_CONFLICT';
  end if;

  v_hash := public.kc_customer_cart_signature(p_customer_id);

  select *
  into v_attempt
  from public.customer_checkout_attempts a
  where a.customer_id = p_customer_id
    and a.cart_version = p_expected_version
    and a.payload_hash = v_hash
    and a.status = 'pending'
  order by a.created_at desc
  limit 1;

  if found then
    v_attempt_id := v_attempt.attempt_id;
  else
    v_attempt_id := gen_random_uuid();
    insert into public.customer_checkout_attempts (
      customer_id, attempt_id, cart_version, payload_hash, status
    )
    values (
      p_customer_id, v_attempt_id, p_expected_version, v_hash, 'pending'
    );
  end if;

  return jsonb_build_object(
    'attempt_id', v_attempt_id,
    'cart_version', p_expected_version,
    'payload_hash', v_hash
  );
end;
$$;

create function public.kc_customer_get_order_by_attempt(
  p_customer_id uuid,
  p_attempt_id uuid
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_attempt public.customer_checkout_attempts%rowtype;
begin
  select *
  into v_attempt
  from public.customer_checkout_attempts a
  where a.customer_id = p_customer_id
    and a.attempt_id = p_attempt_id;

  if not found then
    return null;
  end if;

  if v_attempt.order_id is null then
    return jsonb_build_object(
      'attempt_id', v_attempt.attempt_id,
      'status', v_attempt.status,
      'order', null
    );
  end if;

  return jsonb_build_object(
    'attempt_id', v_attempt.attempt_id,
    'status', v_attempt.status,
    'order', public.kc_customer_get_order(p_customer_id, v_attempt.order_id)
  );
end;
$$;

create function public.kc_customer_checkout(
  p_customer_id uuid,
  p_customer_name text,
  p_attempt_id uuid,
  p_expected_version integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text := coalesce(nullif(btrim(p_customer_name), ''), 'Customer');
  v_attempt public.customer_checkout_attempts%rowtype;
  v_cart public.customer_carts%rowtype;
  v_current_hash text;
  v_stall public.catalog_stalls%rowtype;
  v_customer_active boolean := false;
  v_customer_verified boolean := false;
  v_owner_active boolean := false;
  v_item record;
  v_total bigint := 0;
  v_seq bigint;
  v_order_number text;
  v_order_id uuid;
  v_now timestamptz := now();
begin
  if p_attempt_id is null or p_expected_version is null or p_expected_version < 1 then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  -- Lock any pre-existing attempt row first.
  select *
  into v_attempt
  from public.customer_checkout_attempts a
  where a.customer_id = p_customer_id
    and a.attempt_id = p_attempt_id
  for update;

  if found and v_attempt.status = 'committed' then
    if v_attempt.cart_version <> p_expected_version then
      raise exception 'KC_IDEMPOTENCY_CONFLICT'
        using errcode = 'P0001', detail = 'KC_IDEMPOTENCY_CONFLICT';
    end if;
    return jsonb_build_object(
      'replayed', true,
      'order', public.kc_customer_get_order(p_customer_id, v_attempt.order_id)
    );
  end if;

  -- Check if another key already converted this exact cart version for this customer.
  if exists (
    select 1
    from public.customer_checkout_attempts prev
    where prev.customer_id = p_customer_id
      and prev.cart_version = p_expected_version
      and prev.status = 'committed'
      and prev.attempt_id <> p_attempt_id
  ) then
    raise exception 'KC_CART_VERSION_CONFLICT'
      using errcode = 'P0001', detail = 'KC_CART_VERSION_CONFLICT';
  end if;

  -- Consistent lock ordering (DB-TECH-003): customer_carts -> catalog_stalls -> catalog_menu_items.
  select *
  into v_cart
  from public.customer_carts c
  where c.customer_id = p_customer_id
  for update;

  if not found or v_cart.stall_id is null
     or not exists (select 1 from public.customer_cart_items ci where ci.cart_id = p_customer_id) then
    raise exception 'KC_CART_EMPTY'
      using errcode = 'P0001', detail = 'KC_CART_EMPTY';
  end if;

  if v_cart.draft_version <> p_expected_version then
    raise exception 'KC_CART_VERSION_CONFLICT'
      using errcode = 'P0001', detail = 'KC_CART_VERSION_CONFLICT';
  end if;

  v_current_hash := public.kc_customer_cart_signature(p_customer_id);
  if v_attempt.attempt_id is not null and v_attempt.payload_hash is distinct from v_current_hash then
    raise exception 'KC_IDEMPOTENCY_CONFLICT'
      using errcode = 'P0001', detail = 'KC_IDEMPOTENCY_CONFLICT';
  end if;
  if v_attempt.attempt_id is not null and v_attempt.cart_version <> p_expected_version then
    raise exception 'KC_IDEMPOTENCY_CONFLICT'
      using errcode = 'P0001', detail = 'KC_IDEMPOTENCY_CONFLICT';
  end if;

  select
    (u.banned_until is null or u.banned_until <= now()),
    (u.email_confirmed_at is not null)
  into v_customer_active, v_customer_verified
  from auth.users u
  where u.id = p_customer_id;

  if not coalesce(v_customer_active, false) then
    raise exception 'KC_CUSTOMER_INACTIVE'
      using errcode = 'P0001', detail = 'KC_CUSTOMER_INACTIVE';
  end if;
  if not coalesce(v_customer_verified, false) then
    raise exception 'KC_EMAIL_NOT_VERIFIED'
      using errcode = 'P0001', detail = 'KC_EMAIL_NOT_VERIFIED';
  end if;

  select *
  into v_stall
  from public.catalog_stalls s
  where s.id = v_cart.stall_id
  for share;

  if not found or not v_stall.is_listed then
    raise exception 'KC_STALL_CLOSED'
      using errcode = 'P0001', detail = 'KC_STALL_CLOSED';
  end if;

  select (u.banned_until is null or u.banned_until <= now())
  into v_owner_active
  from auth.users u
  where u.id = v_stall.owner_id;

  if not coalesce(v_owner_active, false) then
    raise exception 'KC_OWNER_INACTIVE'
      using errcode = 'P0001', detail = 'KC_OWNER_INACTIVE';
  end if;

  if not v_stall.is_open then
    raise exception 'KC_STALL_CLOSED'
      using errcode = 'P0001', detail = 'KC_STALL_CLOSED';
  end if;

  -- Lock all menu rows in ascending ID order to avoid deadlocks with concurrent Owner edits.
  for v_item in
    select
      ci.id as cart_item_id,
      ci.menu_item_id,
      ci.quantity,
      ci.item_note,
      ci.seen_unit_price,
      m.stall_id as menu_stall_id,
      m.name as menu_name,
      m.price as current_price,
      m.is_available,
      m.is_archived,
      m.is_listed as menu_is_listed
    from public.customer_cart_items ci
    join public.catalog_menu_items m on m.id = ci.menu_item_id
    where ci.cart_id = p_customer_id
    order by m.id asc
    for share of m
  loop
    if v_item.menu_stall_id <> v_stall.id then
      raise exception 'KC_CART_DIFFERENT_STALL'
        using errcode = 'P0001', detail = 'KC_CART_DIFFERENT_STALL';
    end if;
    if v_item.is_archived or not v_item.menu_is_listed then
      raise exception 'KC_MENU_ARCHIVED'
        using errcode = 'P0001', detail = 'KC_MENU_ARCHIVED';
    end if;
    if not v_item.is_available then
      raise exception 'KC_MENU_UNAVAILABLE'
        using errcode = 'P0001', detail = 'KC_MENU_UNAVAILABLE';
    end if;
    if v_item.current_price <> v_item.seen_unit_price then
      raise exception 'KC_PRICE_CHANGED'
        using errcode = 'P0001', detail = 'KC_PRICE_CHANGED';
    end if;
    v_total := v_total + (v_item.current_price::bigint * v_item.quantity::bigint);
  end loop;

  if v_total < 0 or v_total > 1000000000 then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  loop
    v_seq := nextval('public.kc_order_number_seq');
    v_order_number := '0' || lpad(v_seq::text, 4, '0');
    exit when not exists (select 1 from public.orders o where o.order_number = v_order_number);
  end loop;

  insert into public.orders (
    order_number,
    stall_id,
    customer_id,
    customer_name,
    status,
    payment_status,
    general_note,
    total_amount,
    idempotency_key,
    created_at,
    updated_at
  )
  values (
    v_order_number,
    v_stall.id,
    p_customer_id,
    left(v_name, 120),
    'menunggu_konfirmasi',
    'belum_lunas',
    v_cart.general_note,
    v_total::integer,
    p_attempt_id::text,
    v_now,
    v_now
  )
  returning id into v_order_id;

  insert into public.order_items (
    order_id,
    menu_item_id,
    menu_name,
    unit_price,
    quantity,
    line_total,
    item_note
  )
  select
    v_order_id,
    m.id,
    m.name,
    m.price,
    ci.quantity,
    m.price * ci.quantity,
    ci.item_note
  from public.customer_cart_items ci
  join public.catalog_menu_items m on m.id = ci.menu_item_id
  where ci.cart_id = p_customer_id
  order by ci.created_at asc, ci.id asc;

  insert into public.order_status_events (
    order_id, from_status, to_status, actor_id, actor_role, reason, created_at
  )
  values (
    v_order_id, null, 'menunggu_konfirmasi', p_customer_id, 'customer', null, v_now
  );

  insert into public.order_notification_events (
    order_id, recipient_id, recipient_role, event_type, created_at
  )
  values (
    v_order_id, v_stall.owner_id, 'owner', 'order_created', v_now
  );

  insert into public.customer_checkout_attempts (
    customer_id, attempt_id, cart_version, payload_hash, status, order_id, created_at, committed_at
  )
  values (
    p_customer_id, p_attempt_id, p_expected_version, v_current_hash, 'committed', v_order_id, v_now, v_now
  )
  on conflict (customer_id, attempt_id) do update
  set status = 'committed',
      order_id = v_order_id,
      committed_at = v_now;

  delete from public.customer_cart_items
  where cart_id = p_customer_id;

  update public.customer_carts
  set stall_id = null,
      general_note = '',
      draft_version = draft_version + 1,
      updated_at = v_now
  where customer_id = p_customer_id;

  return jsonb_build_object(
    'replayed', false,
    'order', public.kc_customer_get_order(p_customer_id, v_order_id)
  );
end;
$$;

create function public.kc_customer_cancel_order(
  p_customer_id uuid,
  p_order_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_stall public.catalog_stalls%rowtype;
  v_now timestamptz := now();
begin
  select o.*
  into v_order
  from public.orders o
  where o.id = p_order_id
    and o.customer_id = p_customer_id
  for update of o;

  if not found then
    raise exception 'KC_ORDER_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_ORDER_NOT_FOUND';
  end if;

  if v_order.status <> 'menunggu_konfirmasi' then
    raise exception 'KC_INVALID_ORDER_TRANSITION'
      using errcode = 'P0001', detail = 'KC_INVALID_ORDER_TRANSITION';
  end if;

  select *
  into v_stall
  from public.catalog_stalls s
  where s.id = v_order.stall_id;

  update public.orders
  set status = 'dibatalkan',
      payment_status = 'belum_lunas',
      terminal_at = v_now,
      updated_at = v_now
  where id = v_order.id;

  insert into public.order_status_events (
    order_id, from_status, to_status, actor_id, actor_role, reason, created_at
  )
  values (
    v_order.id, 'menunggu_konfirmasi', 'dibatalkan', p_customer_id, 'customer', null, v_now
  );

  insert into public.order_notification_events (
    order_id, recipient_id, recipient_role, event_type, created_at
  )
  values (
    v_order.id, v_stall.owner_id, 'owner', 'order_cancelled', v_now
  );

  return public.kc_customer_get_order(p_customer_id, v_order.id);
end;
$$;

-- =============================================================================
-- 10. Customer Owner Application RPCs (CUSTOMER-006A, ADMIN-001, ADMIN-002)
-- =============================================================================
create function public.kc_customer_get_owner_application_state(p_customer_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_app public.owner_applications%rowtype;
begin
  select a.*
  into v_app
  from public.owner_applications a
  where a.customer_id = p_customer_id
  order by a.created_at desc, a.id desc
  limit 1;

  return jsonb_build_object(
    'latest_application',
    case
      when not found then null
      else jsonb_build_object(
        'id', v_app.id,
        'planned_stall_name', v_app.planned_stall_name,
        'planned_location', v_app.planned_location,
        'reason', v_app.reason,
        'status', v_app.status,
        'rejection_reason', v_app.rejection_reason,
        'created_at', v_app.created_at,
        'decided_at', v_app.decided_at
      )
    end,
    'active_order_indicator', public.kc_admin_user_active_order_indicator(p_customer_id)
  );
end;
$$;

create function public.kc_customer_submit_owner_application(
  p_customer_id uuid,
  p_planned_stall_name text,
  p_planned_location text,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_stall_name text := btrim(coalesce(p_planned_stall_name, ''));
  v_location text := btrim(coalesce(p_planned_location, ''));
  v_reason text := btrim(coalesce(p_reason, ''));
begin
  if char_length(v_stall_name) not between 1 and 120
     or char_length(v_location) not between 1 and 120
     or char_length(v_reason) not between 1 and 500 then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  if exists (
    select 1 from public.catalog_stalls s where s.owner_id = p_customer_id
  ) then
    raise exception 'KC_ALREADY_OWNER'
      using errcode = 'P0001', detail = 'KC_ALREADY_OWNER';
  end if;

  -- CUSTOMER-006A: active orders do NOT block Customer from submitting; Admin rejects on review.
  begin
    insert into public.owner_applications (
      customer_id, planned_stall_name, planned_location, reason, status
    )
    values (
      p_customer_id, v_stall_name, v_location, v_reason, 'menunggu_review'
    );
  exception
    when unique_violation then
      raise exception 'KC_APPLICATION_ALREADY_PENDING'
        using errcode = 'P0001', detail = 'KC_APPLICATION_ALREADY_PENDING';
  end;

  return public.kc_customer_get_owner_application_state(p_customer_id);
end;
$$;

-- =============================================================================
-- 11. Least-Privilege Function Grants
-- =============================================================================
revoke all on function
  public.kc_admin_user_active_order_indicator(uuid),
  public.kc_customer_get_stall_detail(uuid),
  public.kc_customer_get_menu_detail(uuid),
  public.kc_customer_get_stall_photo_path(uuid),
  public.kc_customer_get_menu_photo_path(uuid),
  public.kc_customer_cart_signature(uuid),
  public.kc_customer_get_cart(uuid),
  public.kc_customer_add_cart_item(uuid, uuid, integer, text, boolean),
  public.kc_customer_update_cart_item(uuid, uuid, integer, text),
  public.kc_customer_set_cart_note(uuid, text),
  public.kc_customer_acknowledge_cart_prices(uuid, integer),
  public.kc_customer_clear_cart(uuid),
  public.kc_customer_order_summary_json(public.orders, public.catalog_stalls),
  public.kc_customer_list_orders(uuid, text, integer, integer),
  public.kc_customer_get_order(uuid, uuid),
  public.kc_customer_create_checkout_attempt(uuid, integer),
  public.kc_customer_get_order_by_attempt(uuid, uuid),
  public.kc_customer_checkout(uuid, text, uuid, integer),
  public.kc_customer_cancel_order(uuid, uuid),
  public.kc_customer_get_owner_application_state(uuid),
  public.kc_customer_submit_owner_application(uuid, text, text, text)
from public, anon, authenticated;

grant execute on function
  public.kc_admin_user_active_order_indicator(uuid),
  public.kc_customer_get_stall_detail(uuid),
  public.kc_customer_get_menu_detail(uuid),
  public.kc_customer_get_stall_photo_path(uuid),
  public.kc_customer_get_menu_photo_path(uuid),
  public.kc_customer_cart_signature(uuid),
  public.kc_customer_get_cart(uuid),
  public.kc_customer_add_cart_item(uuid, uuid, integer, text, boolean),
  public.kc_customer_update_cart_item(uuid, uuid, integer, text),
  public.kc_customer_set_cart_note(uuid, text),
  public.kc_customer_acknowledge_cart_prices(uuid, integer),
  public.kc_customer_clear_cart(uuid),
  public.kc_customer_order_summary_json(public.orders, public.catalog_stalls),
  public.kc_customer_list_orders(uuid, text, integer, integer),
  public.kc_customer_get_order(uuid, uuid),
  public.kc_customer_create_checkout_attempt(uuid, integer),
  public.kc_customer_get_order_by_attempt(uuid, uuid),
  public.kc_customer_checkout(uuid, text, uuid, integer),
  public.kc_customer_cancel_order(uuid, uuid),
  public.kc_customer_get_owner_application_state(uuid),
  public.kc_customer_submit_owner_application(uuid, text, text, text)
to service_role;

grant usage, select on sequence public.kc_order_number_seq to service_role;

commit;
