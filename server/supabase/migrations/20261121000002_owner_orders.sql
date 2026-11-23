-- Owner Operational Orders schema, immutable item snapshots, status events,
-- notification outbox (ORDER-017A), orderability guards, and atomic Owner RPCs.
begin;

-- =============================================================================
-- 1. Orders, Immutable Snapshots, Status Events, Notification Outbox
-- =============================================================================
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique check (char_length(btrim(order_number)) between 1 and 40),
  stall_id uuid not null references public.catalog_stalls(id),
  customer_id uuid not null references auth.users(id),
  customer_name text not null check (char_length(btrim(customer_name)) between 1 and 120),
  status text not null check (
    status in (
      'menunggu_konfirmasi',
      'diproses',
      'siap_diambil',
      'selesai',
      'dibatalkan',
      'ditolak',
      'gagal_dipenuhi',
      'tidak_diambil',
      'gagal_diambil'
    )
  ),
  payment_status text not null default 'belum_lunas' check (
    payment_status in ('belum_lunas', 'lunas')
  ),
  general_note text not null default '' check (char_length(general_note) <= 500),
  total_amount integer not null check (total_amount >= 0),
  prep_estimate_minutes smallint null check (
    prep_estimate_minutes is null or prep_estimate_minutes between 0 and 240
  ),
  status_reason text null check (
    status_reason is null or char_length(btrim(status_reason)) between 1 and 500
  ),
  idempotency_key text null,
  created_at timestamptz not null default now(),
  accepted_at timestamptz null,
  ready_at timestamptz null,
  terminal_at timestamptz null,
  updated_at timestamptz not null default now(),
  constraint orders_payment_status_invariant check (
    (status = 'selesai' and payment_status = 'lunas')
    or (status <> 'selesai' and payment_status = 'belum_lunas')
  )
);

create index orders_stall_status_created
  on public.orders (stall_id, status, created_at);

create index orders_customer_created
  on public.orders (customer_id, created_at desc);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  menu_item_id uuid null references public.catalog_menu_items(id) on delete set null,
  menu_name text not null check (char_length(btrim(menu_name)) between 1 and 120),
  unit_price integer not null check (unit_price >= 0),
  quantity integer not null check (quantity >= 1),
  line_total integer not null check (line_total = unit_price * quantity),
  item_note text not null default '' check (char_length(item_note) <= 300)
);

create index order_items_order_id on public.order_items (order_id);

-- ORDER-011 / OWNER-005: snapshot rows are immutable once created.
create function public.kc_guard_order_items_immutable()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  raise exception 'KC_ORDER_SNAPSHOT_IMMUTABLE'
    using errcode = 'P0001', detail = 'KC_ORDER_SNAPSHOT_IMMUTABLE';
end;
$$;

create trigger trg_guard_order_items_immutable
  before update or delete on public.order_items
  for each row
  execute function public.kc_guard_order_items_immutable();

create table public.order_status_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  from_status text null,
  to_status text not null,
  actor_id uuid not null references auth.users(id),
  actor_role text not null check (actor_role in ('customer', 'owner')),
  reason text null,
  created_at timestamptz not null default now()
);

create index order_status_events_order_created
  on public.order_status_events (order_id, created_at asc, id asc);

-- ORDER-017A: push outbox limited strictly to the 7 agreed events.
create table public.order_notification_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  recipient_id uuid not null references auth.users(id),
  recipient_role text not null check (recipient_role in ('customer', 'owner')),
  event_type text not null check (
    event_type in (
      'order_created',
      'order_cancelled',
      'order_accepted',
      'order_rejected',
      'order_ready',
      'order_failed_fulfill',
      'order_not_picked_up'
    )
  ),
  created_at timestamptz not null default now(),
  delivered_at timestamptz null
);

create index order_notification_events_pending
  on public.order_notification_events (created_at)
  where delivered_at is null;

alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_events enable row level security;
alter table public.order_notification_events enable row level security;

revoke all on public.orders,
  public.order_items,
  public.order_status_events,
  public.order_notification_events
from public, anon, authenticated;

grant select, insert, update, delete on public.orders,
  public.order_items,
  public.order_status_events,
  public.order_notification_events
to service_role;

-- =============================================================================
-- 2. Orderability & Owner Active Status Helpers (OWNER-005A, ADMIN-003B)
-- =============================================================================
create function public.kc_order_is_stall_accepting_orders(p_stall_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.catalog_stalls s
    join auth.users u on u.id = s.owner_id
    where s.id = p_stall_id
      and s.is_listed
      and s.is_open
      and (u.banned_until is null or u.banned_until <= now())
  );
$$;

create function public.kc_order_is_menu_orderable(p_menu_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.catalog_menu_items m
    join public.catalog_stalls s on s.id = m.stall_id
    join auth.users u on u.id = s.owner_id
    where m.id = p_menu_id
      and not m.is_archived
      and m.is_listed
      and m.is_available
      and s.is_listed
      and s.is_open
      and (u.banned_until is null or u.banned_until <= now())
  );
$$;

-- =============================================================================
-- 3. Owner Order Queries & Atomic State Transitions
-- =============================================================================
create function public.kc_owner_order_summary_json(p_order public.orders)
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

create function public.kc_owner_dashboard(p_owner_id uuid)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_stall_payload jsonb := public.kc_owner_get_stall(p_owner_id);
  v_stall_id uuid;
  v_pending integer := 0;
  v_processing integer := 0;
  v_ready integer := 0;
  v_attention jsonb := '[]'::jsonb;
begin
  select s.id
  into v_stall_id
  from public.catalog_stalls s
  where s.owner_id = p_owner_id;

  if v_stall_id is not null then
    select
      count(*) filter (where o.status = 'menunggu_konfirmasi')::integer,
      count(*) filter (where o.status = 'diproses')::integer,
      count(*) filter (where o.status = 'siap_diambil')::integer
    into v_pending, v_processing, v_ready
    from public.orders o
    where o.stall_id = v_stall_id;

    select coalesce(jsonb_agg(sub.summary), '[]'::jsonb)
    into v_attention
    from (
      select public.kc_owner_order_summary_json(o) as summary
      from public.orders o
      where o.stall_id = v_stall_id
        and o.status in ('menunggu_konfirmasi', 'diproses', 'siap_diambil')
      order by
        case o.status
          when 'menunggu_konfirmasi' then 1
          when 'diproses' then 2
          else 3
        end,
        o.created_at asc,
        o.id asc
      limit 10
    ) sub;
  end if;

  return jsonb_build_object(
    'stall', v_stall_payload->'stall',
    'schedules', v_stall_payload->'schedules',
    'publish_eligibility', v_stall_payload->'publish_eligibility',
    'active_counts', jsonb_build_object(
      'menunggu_konfirmasi', v_pending,
      'diproses', v_processing,
      'siap_diambil', v_ready
    ),
    'attention_orders', v_attention,
    'server_time', now()
  );
end;
$$;

create function public.kc_owner_list_orders(
  p_owner_id uuid,
  p_scope text default 'active',
  p_status text default null,
  p_query text default '',
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
  v_stall_id uuid;
  v_query text := lower(btrim(coalesce(p_query, '')));
  v_limit integer := least(greatest(coalesce(p_limit, 30), 1), 100);
  v_offset integer := greatest(coalesce(p_offset, 0), 0);
  v_items jsonb;
begin
  if p_scope not in ('active', 'history') then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  select s.id
  into v_stall_id
  from public.catalog_stalls s
  where s.owner_id = p_owner_id;

  if not found then
    return jsonb_build_object('items', '[]'::jsonb, 'has_more', false);
  end if;

  select coalesce(jsonb_agg(sub.summary), '[]'::jsonb)
  into v_items
  from (
    select public.kc_owner_order_summary_json(o) as summary
    from public.orders o
    where o.stall_id = v_stall_id
      and (
        (p_scope = 'active' and o.status in ('menunggu_konfirmasi', 'diproses', 'siap_diambil'))
        or (p_scope = 'history' and o.status in ('selesai', 'dibatalkan', 'ditolak', 'gagal_dipenuhi', 'tidak_diambil', 'gagal_diambil'))
      )
      and (p_status is null or o.status = p_status)
      and (
        v_query = ''
        or strpos(lower(o.order_number), v_query) > 0
        or strpos(lower(o.customer_name), v_query) > 0
      )
    order by
      case when p_scope = 'active' then
        case o.status
          when 'menunggu_konfirmasi' then 1
          when 'diproses' then 2
          else 3
        end
      else 0
      end asc,
      case when p_scope = 'active' then o.created_at end asc,
      case when p_scope = 'history' then coalesce(o.terminal_at, o.updated_at) end desc,
      o.id asc
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

create function public.kc_owner_get_order(
  p_owner_id uuid,
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
  v_items jsonb;
  v_events jsonb;
begin
  select o.*
  into v_order
  from public.orders o
  join public.catalog_stalls s on s.id = o.stall_id
  where o.id = p_order_id and s.owner_id = p_owner_id;

  if not found then
    return null;
  end if;

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

  return public.kc_owner_order_summary_json(v_order) || jsonb_build_object(
    'items', v_items,
    'events', v_events
  );
end;
$$;

create function public.kc_owner_lookup_order(
  p_owner_id uuid,
  p_order_number text
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_code text := btrim(coalesce(p_order_number, ''));
  v_order_id uuid;
begin
  if v_code = '' then
    return null;
  end if;

  -- ORDER-015: lookup strictly within Owner's own stall; preserves leading zeros as text.
  select o.id
  into v_order_id
  from public.orders o
  join public.catalog_stalls s on s.id = o.stall_id
  where s.owner_id = p_owner_id
    and lower(o.order_number) = lower(v_code)
  limit 1;

  if not found then
    return null;
  end if;

  return public.kc_owner_get_order(p_owner_id, v_order_id);
end;
$$;

create function public.kc_owner_transition_order(
  p_owner_id uuid,
  p_order_id uuid,
  p_action text,
  p_reason text default null,
  p_cash_received boolean default false,
  p_food_handed_over boolean default false
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_stall public.catalog_stalls%rowtype;
  v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
  v_next_status text;
  v_next_payment text := 'belum_lunas';
  v_notif_event text := null;
  v_now timestamptz := now();
begin
  select o.*
  into v_order
  from public.orders o
  join public.catalog_stalls s on s.id = o.stall_id
  where o.id = p_order_id and s.owner_id = p_owner_id
  for update of o;

  if not found then
    raise exception 'KC_ORDER_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_ORDER_NOT_FOUND';
  end if;

  select *
  into v_stall
  from public.catalog_stalls s
  where s.id = v_order.stall_id;

  case p_action
    when 'accept' then
      if v_order.status <> 'menunggu_konfirmasi' then
        raise exception 'KC_INVALID_ORDER_TRANSITION'
          using errcode = 'P0001', detail = 'KC_INVALID_ORDER_TRANSITION';
      end if;
      v_next_status := 'diproses';
      v_notif_event := 'order_accepted';
      update public.orders
      set status = v_next_status,
          prep_estimate_minutes = v_stall.wait_minutes,
          accepted_at = v_now,
          updated_at = v_now
      where id = v_order.id;

    when 'reject' then
      if v_order.status <> 'menunggu_konfirmasi' then
        raise exception 'KC_INVALID_ORDER_TRANSITION'
          using errcode = 'P0001', detail = 'KC_INVALID_ORDER_TRANSITION';
      end if;
      if v_reason is null or char_length(v_reason) > 500 then
        raise exception 'KC_REASON_REQUIRED'
          using errcode = 'P0001', detail = 'KC_REASON_REQUIRED';
      end if;
      v_next_status := 'ditolak';
      v_notif_event := 'order_rejected';
      update public.orders
      set status = v_next_status,
          payment_status = 'belum_lunas',
          status_reason = v_reason,
          terminal_at = v_now,
          updated_at = v_now
      where id = v_order.id;

    when 'ready' then
      if v_order.status <> 'diproses' then
        raise exception 'KC_INVALID_ORDER_TRANSITION'
          using errcode = 'P0001', detail = 'KC_INVALID_ORDER_TRANSITION';
      end if;
      v_next_status := 'siap_diambil';
      v_notif_event := 'order_ready';
      update public.orders
      set status = v_next_status,
          ready_at = v_now,
          updated_at = v_now
      where id = v_order.id;

    when 'fail_fulfillment' then
      -- ORDER-013A: strictly from diproses only, never from siap_diambil.
      if v_order.status <> 'diproses' then
        raise exception 'KC_INVALID_ORDER_TRANSITION'
          using errcode = 'P0001', detail = 'KC_INVALID_ORDER_TRANSITION';
      end if;
      if v_reason is null or char_length(v_reason) > 500 then
        raise exception 'KC_REASON_REQUIRED'
          using errcode = 'P0001', detail = 'KC_REASON_REQUIRED';
      end if;
      v_next_status := 'gagal_dipenuhi';
      v_notif_event := 'order_failed_fulfill';
      update public.orders
      set status = v_next_status,
          payment_status = 'belum_lunas',
          status_reason = v_reason,
          terminal_at = v_now,
          updated_at = v_now
      where id = v_order.id;

    when 'complete' then
      -- ORDER-004: cash received and food handed over confirmed together atomically.
      if v_order.status <> 'siap_diambil' then
        raise exception 'KC_INVALID_ORDER_TRANSITION'
          using errcode = 'P0001', detail = 'KC_INVALID_ORDER_TRANSITION';
      end if;
      if p_cash_received is not true or p_food_handed_over is not true then
        raise exception 'KC_COMPLETE_CONFIRMATION_REQUIRED'
          using errcode = 'P0001', detail = 'KC_COMPLETE_CONFIRMATION_REQUIRED';
      end if;
      v_next_status := 'selesai';
      v_next_payment := 'lunas';
      -- ORDER-017A: selesai has no push notification event.
      update public.orders
      set status = v_next_status,
          payment_status = v_next_payment,
          terminal_at = v_now,
          updated_at = v_now
      where id = v_order.id;

    when 'not_picked_up' then
      if v_order.status <> 'siap_diambil' then
        raise exception 'KC_INVALID_ORDER_TRANSITION'
          using errcode = 'P0001', detail = 'KC_INVALID_ORDER_TRANSITION';
      end if;
      v_next_status := 'tidak_diambil';
      v_notif_event := 'order_not_picked_up';
      update public.orders
      set status = v_next_status,
          payment_status = 'belum_lunas',
          terminal_at = v_now,
          updated_at = v_now
      where id = v_order.id;

    when 'fail_pickup' then
      -- ORDER-013B: strictly from siap_diambil with mandatory reason; remains belum_lunas.
      if v_order.status <> 'siap_diambil' then
        raise exception 'KC_INVALID_ORDER_TRANSITION'
          using errcode = 'P0001', detail = 'KC_INVALID_ORDER_TRANSITION';
      end if;
      if v_reason is null or char_length(v_reason) > 500 then
        raise exception 'KC_REASON_REQUIRED'
          using errcode = 'P0001', detail = 'KC_REASON_REQUIRED';
      end if;
      v_next_status := 'gagal_diambil';
      -- ORDER-017A: gagal_diambil has no push notification event.
      update public.orders
      set status = v_next_status,
          payment_status = 'belum_lunas',
          status_reason = v_reason,
          terminal_at = v_now,
          updated_at = v_now
      where id = v_order.id;

    else
      raise exception 'KC_INVALID_INPUT'
        using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end case;

  insert into public.order_status_events (
    order_id, from_status, to_status, actor_id, actor_role, reason, created_at
  )
  values (
    v_order.id, v_order.status, v_next_status, p_owner_id, 'owner', v_reason, v_now
  );

  if v_notif_event is not null then
    insert into public.order_notification_events (
      order_id, recipient_id, recipient_role, event_type, created_at
    )
    values (
      v_order.id, v_order.customer_id, 'customer', v_notif_event, v_now
    );
  end if;

  return public.kc_owner_get_order(p_owner_id, v_order.id);
end;
$$;

revoke all on function
  public.kc_guard_order_items_immutable(),
  public.kc_order_is_stall_accepting_orders(uuid),
  public.kc_order_is_menu_orderable(uuid),
  public.kc_owner_order_summary_json(public.orders),
  public.kc_owner_dashboard(uuid),
  public.kc_owner_list_orders(uuid, text, text, text, integer, integer),
  public.kc_owner_get_order(uuid, uuid),
  public.kc_owner_lookup_order(uuid, text),
  public.kc_owner_transition_order(uuid, uuid, text, text, boolean, boolean)
from public, anon, authenticated;

grant execute on function
  public.kc_guard_order_items_immutable(),
  public.kc_order_is_stall_accepting_orders(uuid),
  public.kc_order_is_menu_orderable(uuid),
  public.kc_owner_order_summary_json(public.orders),
  public.kc_owner_dashboard(uuid),
  public.kc_owner_list_orders(uuid, text, text, text, integer, integer),
  public.kc_owner_get_order(uuid, uuid),
  public.kc_owner_lookup_order(uuid, text),
  public.kc_owner_transition_order(uuid, uuid, text, text, boolean, boolean)
to service_role;

commit;
