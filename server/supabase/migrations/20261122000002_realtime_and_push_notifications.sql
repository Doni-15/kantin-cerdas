-- Kantin Cerdas Realtime & Push Notification Finalization (ORDER-017, ORDER-017A, RT-TECH-001..005)
-- Forward-only migration: reuses public.order_notification_events & public.order_status_events
-- without altering historical migrations or FINAL/LOCKED order business rules.

begin;

-- =============================================================================
-- 1. Outbox index on existing public.order_notification_events
-- =============================================================================
create index if not exists idx_order_notification_events_undelivered
  on public.order_notification_events (created_at asc, id asc)
  where delivered_at is null;

-- =============================================================================
-- 2. Role & active-account helpers (consistent with GoTrue default customer role)
-- =============================================================================
create or replace function public.kc_rt_user_role(p_raw_app_meta_data jsonb)
returns text
language sql
immutable
as $$
  select case coalesce(p_raw_app_meta_data->>'kantin_role', '')
    when 'owner' then 'owner'
    when 'admin' then 'admin'
    else 'customer'
  end;
$$;

create or replace function public.kc_rt_is_user_active(
  p_banned_until timestamptz,
  p_now timestamptz default now()
)
returns boolean
language sql
immutable
as $$
  select p_banned_until is null or p_banned_until <= p_now;
$$;

-- =============================================================================
-- 3. Private realtime channel topics with epoch rotation (RT-TECH-003, RT-TECH-005, R2)
-- =============================================================================
create table public.realtime_channel_topics (
  scope_type text not null check (scope_type in ('customer', 'stall')),
  scope_id uuid not null,
  topic_epoch integer not null default 1 check (topic_epoch >= 1),
  topic_token text not null check (char_length(topic_token) >= 16),
  rotated_at timestamptz not null default now(),
  primary key (scope_type, scope_id)
);

alter table public.realtime_channel_topics enable row level security;

revoke all on table public.realtime_channel_topics from public, anon, authenticated;
grant select, insert, update, delete on table public.realtime_channel_topics to service_role;

create or replace function public.kc_rt_format_topic(
  p_scope_type text,
  p_scope_id uuid,
  p_epoch integer,
  p_token text
)
returns text
language sql
immutable
as $$
  select 'private:' || p_scope_type || ':' || p_scope_id::text || ':v' || p_epoch::text || ':' || p_token;
$$;

create or replace function public.kc_rt_ensure_topic(
  p_scope_type text,
  p_scope_id uuid
)
returns public.realtime_channel_topics
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.realtime_channel_topics%rowtype;
begin
  insert into public.realtime_channel_topics (
    scope_type, scope_id, topic_epoch, topic_token, rotated_at
  )
  values (
    p_scope_type,
    p_scope_id,
    1,
    replace(gen_random_uuid()::text, '-', ''),
    now()
  )
  on conflict (scope_type, scope_id) do nothing;

  select *
  into v_row
  from public.realtime_channel_topics
  where scope_type = p_scope_type
    and scope_id = p_scope_id;

  return v_row;
end;
$$;

-- =============================================================================
-- 4. Minimal non-sensitive realtime signal ledger (all order transitions incl. selesai & gagal_diambil)
-- =============================================================================
create table public.order_realtime_signals (
  seq bigint generated always as identity primary key,
  event_id uuid not null unique,
  order_id uuid not null references public.orders(id) on delete cascade,
  stall_id uuid not null references public.catalog_stalls(id) on delete cascade,
  customer_id uuid not null references auth.users(id),
  owner_id uuid not null references auth.users(id),
  from_status text null,
  to_status text not null,
  customer_topic text not null,
  stall_topic text not null,
  created_at timestamptz not null default now(),
  broadcasted_at timestamptz null
);

create index idx_order_realtime_signals_customer_seq
  on public.order_realtime_signals (customer_id, seq asc);

create index idx_order_realtime_signals_owner_seq
  on public.order_realtime_signals (owner_id, seq asc);

create index idx_order_realtime_signals_unbroadcasted
  on public.order_realtime_signals (seq asc)
  where broadcasted_at is null;

alter table public.order_realtime_signals enable row level security;

revoke all on table public.order_realtime_signals from public, anon, authenticated;
grant select, insert, update, delete on table public.order_realtime_signals to service_role;
revoke all on sequence public.order_realtime_signals_seq_seq from public, anon, authenticated;
grant usage, select on sequence public.order_realtime_signals_seq_seq to service_role;

-- Automatically emit minimal realtime signals whenever any order status event is persisted.
-- Covers all transitions including selesai and gagal_diambil (ORDER-013B, ORDER-017).
create or replace function public.kc_trg_emit_order_realtime_signal()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_stall public.catalog_stalls%rowtype;
  v_customer_topic_row public.realtime_channel_topics%rowtype;
  v_stall_topic_row public.realtime_channel_topics%rowtype;
  v_customer_topic text;
  v_stall_topic text;
  v_seq bigint;
begin
  select *
  into v_order
  from public.orders
  where id = new.order_id;

  if not found then
    return new;
  end if;

  select *
  into v_stall
  from public.catalog_stalls
  where id = v_order.stall_id;

  if not found then
    return new;
  end if;

  v_customer_topic_row := public.kc_rt_ensure_topic('customer', v_order.customer_id);
  v_stall_topic_row := public.kc_rt_ensure_topic('stall', v_order.stall_id);

  v_customer_topic := public.kc_rt_format_topic(
    'customer',
    v_order.customer_id,
    v_customer_topic_row.topic_epoch,
    v_customer_topic_row.topic_token
  );
  v_stall_topic := public.kc_rt_format_topic(
    'stall',
    v_order.stall_id,
    v_stall_topic_row.topic_epoch,
    v_stall_topic_row.topic_token
  );

  insert into public.order_realtime_signals (
    event_id,
    order_id,
    stall_id,
    customer_id,
    owner_id,
    from_status,
    to_status,
    customer_topic,
    stall_topic,
    created_at
  )
  values (
    new.id,
    v_order.id,
    v_order.stall_id,
    v_order.customer_id,
    v_stall.owner_id,
    new.from_status,
    new.to_status,
    v_customer_topic,
    v_stall_topic,
    coalesce(new.created_at, now())
  )
  on conflict (event_id) do nothing
  returning seq into v_seq;

  if v_seq is not null then
    perform pg_notify(
      'kc_order_realtime',
      jsonb_build_object(
        'seq', v_seq,
        'event_id', new.id,
        'order_id', v_order.id,
        'to_status', new.to_status
      )::text
    );
  end if;

  return new;
end;
$$;

create trigger trg_order_status_events_realtime_signal
  after insert on public.order_status_events
  for each row
  execute function public.kc_trg_emit_order_realtime_signal();

-- =============================================================================
-- 5. Android push device tokens (RT-TECH-002, RT-TECH-004, R2)
-- =============================================================================
create table public.user_push_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null check (char_length(btrim(device_id)) between 1 and 128),
  fcm_token text not null check (char_length(btrim(fcm_token)) between 16 and 512),
  platform text not null default 'android' check (platform in ('android')),
  is_active boolean not null default true,
  revoked_at timestamptz null,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, device_id)
);

create index idx_user_push_devices_active_user
  on public.user_push_devices (user_id)
  where is_active = true and revoked_at is null;

create index idx_user_push_devices_fcm_token
  on public.user_push_devices (fcm_token)
  where is_active = true;

alter table public.user_push_devices enable row level security;

revoke all on table public.user_push_devices from public, anon, authenticated;
grant select, insert, update, delete on table public.user_push_devices to service_role;

-- =============================================================================
-- 6. Deduplicated FCM push delivery tracking (ORDER-017A, RT-TECH-002, R1)
-- =============================================================================
create table public.order_push_deliveries (
  id uuid primary key default gen_random_uuid(),
  notification_event_id uuid not null references public.order_notification_events(id) on delete cascade,
  device_id uuid not null references public.user_push_devices(id) on delete cascade,
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
  status text not null default 'pending' check (
    status in ('pending', 'in_flight', 'sent', 'retry_scheduled', 'failed_permanent', 'skipped')
  ),
  attempt_count integer not null default 0 check (attempt_count >= 0),
  max_attempts integer not null default 5 check (max_attempts between 1 and 10),
  next_retry_at timestamptz not null default now(),
  locked_until timestamptz null,
  last_error_code text null,
  provider_message_id text null,
  sent_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (notification_event_id, device_id)
);

create index idx_order_push_deliveries_due
  on public.order_push_deliveries (next_retry_at asc, created_at asc)
  where status in ('pending', 'retry_scheduled');

create index idx_order_push_deliveries_inflight
  on public.order_push_deliveries (locked_until asc)
  where status = 'in_flight';

create index idx_order_push_deliveries_event
  on public.order_push_deliveries (notification_event_id);

alter table public.order_push_deliveries enable row level security;

revoke all on table public.order_push_deliveries from public, anon, authenticated;
grant select, insert, update, delete on table public.order_push_deliveries to service_role;

-- =============================================================================
-- 7. Topic rotation & automatic revocation on auth role/status change (R2)
-- =============================================================================
create or replace function public.kc_rt_rotate_topics_for_user(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := now();
  v_customer_row public.realtime_channel_topics%rowtype;
  v_stall_id uuid;
  v_stall_row public.realtime_channel_topics%rowtype;
  v_has_stall boolean := false;
begin
  if p_user_id is null then
    raise exception 'KC_RT_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_RT_INVALID_INPUT';
  end if;

  insert into public.realtime_channel_topics (
    scope_type, scope_id, topic_epoch, topic_token, rotated_at
  )
  values (
    'customer',
    p_user_id,
    1,
    replace(gen_random_uuid()::text, '-', ''),
    v_now
  )
  on conflict (scope_type, scope_id) do update
  set topic_epoch = public.realtime_channel_topics.topic_epoch + 1,
      topic_token = replace(gen_random_uuid()::text, '-', ''),
      rotated_at = v_now
  returning * into v_customer_row;

  select s.id
  into v_stall_id
  from public.catalog_stalls s
  where s.owner_id = p_user_id
  limit 1;

  if found then
    v_has_stall := true;
    insert into public.realtime_channel_topics (
      scope_type, scope_id, topic_epoch, topic_token, rotated_at
    )
    values (
      'stall',
      v_stall_id,
      1,
      replace(gen_random_uuid()::text, '-', ''),
      v_now
    )
    on conflict (scope_type, scope_id) do update
    set topic_epoch = public.realtime_channel_topics.topic_epoch + 1,
        topic_token = replace(gen_random_uuid()::text, '-', ''),
        rotated_at = v_now
    returning * into v_stall_row;
  end if;

  return jsonb_build_object(
    'customer_topic', public.kc_rt_format_topic(
      'customer', p_user_id, v_customer_row.topic_epoch, v_customer_row.topic_token
    ),
    'customer_epoch', v_customer_row.topic_epoch,
    'stall_id', case when v_has_stall then v_stall_id else null end,
    'stall_topic', case when v_has_stall then public.kc_rt_format_topic(
      'stall', v_stall_id, v_stall_row.topic_epoch, v_stall_row.topic_token
    ) else null end,
    'stall_epoch', case when v_has_stall then v_stall_row.topic_epoch else null end
  );
end;
$$;

create or replace function public.kc_trg_auth_user_realtime_security()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old_role text := public.kc_rt_user_role(old.raw_app_meta_data);
  v_new_role text := public.kc_rt_user_role(new.raw_app_meta_data);
  v_now timestamptz := now();
begin
  if old.banned_until is distinct from new.banned_until
     or v_old_role is distinct from v_new_role then
    perform public.kc_rt_rotate_topics_for_user(new.id);

    if not public.kc_rt_is_user_active(new.banned_until, v_now)
       or v_new_role = 'admin' then
      update public.user_push_devices
      set is_active = false,
          revoked_at = v_now,
          updated_at = v_now
      where user_id = new.id
        and is_active = true;
    end if;
  end if;

  return new;
end;
$$;

create trigger trg_auth_users_realtime_security
  after update of banned_until, raw_app_meta_data on auth.users
  for each row
  execute function public.kc_trg_auth_user_realtime_security();

-- =============================================================================
-- 8. Device push token registration & logout revocation RPCs
-- =============================================================================
create or replace function public.kc_rt_register_push_device(
  p_user_id uuid,
  p_device_id text,
  p_fcm_token text,
  p_platform text default 'android'
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user record;
  v_role text;
  v_device_id text := btrim(coalesce(p_device_id, ''));
  v_fcm_token text := btrim(coalesce(p_fcm_token, ''));
  v_platform text := lower(btrim(coalesce(p_platform, 'android')));
  v_now timestamptz := now();
  v_row public.user_push_devices%rowtype;
begin
  if p_user_id is null
     or char_length(v_device_id) < 1
     or char_length(v_device_id) > 128
     or char_length(v_fcm_token) < 16
     or char_length(v_fcm_token) > 512
     or v_platform <> 'android' then
    raise exception 'KC_RT_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_RT_INVALID_INPUT';
  end if;

  select u.id, u.banned_until, u.raw_app_meta_data
  into v_user
  from auth.users u
  where u.id = p_user_id;

  if not found or not public.kc_rt_is_user_active(v_user.banned_until, v_now) then
    raise exception 'KC_RT_ACCOUNT_INACTIVE'
      using errcode = 'P0001', detail = 'KC_RT_ACCOUNT_INACTIVE';
  end if;

  v_role := public.kc_rt_user_role(v_user.raw_app_meta_data);
  if v_role not in ('customer', 'owner') then
    raise exception 'KC_PUSH_ROLE_NOT_ALLOWED'
      using errcode = 'P0001', detail = 'KC_PUSH_ROLE_NOT_ALLOWED';
  end if;

  -- Account-switch protection: detach this device or FCM token from any previous account.
  update public.user_push_devices
  set is_active = false,
      revoked_at = v_now,
      updated_at = v_now
  where user_id <> p_user_id
    and is_active = true
    and (fcm_token = v_fcm_token or device_id = v_device_id);

  insert into public.user_push_devices (
    user_id,
    device_id,
    fcm_token,
    platform,
    is_active,
    revoked_at,
    last_seen_at,
    created_at,
    updated_at
  )
  values (
    p_user_id,
    v_device_id,
    v_fcm_token,
    v_platform,
    true,
    null,
    v_now,
    v_now,
    v_now
  )
  on conflict (user_id, device_id) do update
  set fcm_token = excluded.fcm_token,
      platform = excluded.platform,
      is_active = true,
      revoked_at = null,
      last_seen_at = v_now,
      updated_at = v_now
  returning * into v_row;

  return jsonb_build_object(
    'id', v_row.id,
    'user_id', v_row.user_id,
    'device_id', v_row.device_id,
    'platform', v_row.platform,
    'is_active', v_row.is_active,
    'updated_at', v_row.updated_at
  );
end;
$$;

create or replace function public.kc_rt_revoke_push_device(
  p_user_id uuid,
  p_device_id text,
  p_rotate_topics boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_device_id text := btrim(coalesce(p_device_id, ''));
  v_now timestamptz := now();
  v_revoked_count integer := 0;
  v_topics jsonb := null;
begin
  if p_user_id is null
     or char_length(v_device_id) < 1
     or char_length(v_device_id) > 128 then
    raise exception 'KC_RT_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_RT_INVALID_INPUT';
  end if;

  update public.user_push_devices
  set is_active = false,
      revoked_at = v_now,
      updated_at = v_now
  where user_id = p_user_id
    and device_id = v_device_id
    and is_active = true;

  get diagnostics v_revoked_count = row_count;

  -- Cancel any queued/retry push deliveries targeting the revoked device (R2).
  update public.order_push_deliveries d
  set status = 'skipped',
      last_error_code = 'DEVICE_REVOKED',
      locked_until = null,
      updated_at = v_now
  from public.user_push_devices dev
  where d.device_id = dev.id
    and dev.user_id = p_user_id
    and dev.device_id = v_device_id
    and d.status in ('pending', 'retry_scheduled');

  if p_rotate_topics is true then
    v_topics := public.kc_rt_rotate_topics_for_user(p_user_id);
  end if;

  return jsonb_build_object(
    'device_id', v_device_id,
    'revoked', v_revoked_count > 0,
    'rotated_topics', v_topics
  );
end;
$$;

-- =============================================================================
-- 9. Authorized realtime channel grant & strictly scoped signal polling (RT-TECH-003)
-- =============================================================================
create or replace function public.kc_rt_get_channel_grant(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user record;
  v_role text;
  v_now timestamptz := now();
  v_customer_topic_row public.realtime_channel_topics%rowtype;
  v_stall_id uuid := null;
  v_stall_topic_row public.realtime_channel_topics%rowtype;
  v_has_stall boolean := false;
  v_last_seq bigint := 0;
begin
  if p_user_id is null then
    raise exception 'KC_RT_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_RT_INVALID_INPUT';
  end if;

  select u.id, u.banned_until, u.raw_app_meta_data
  into v_user
  from auth.users u
  where u.id = p_user_id;

  if not found or not public.kc_rt_is_user_active(v_user.banned_until, v_now) then
    raise exception 'KC_RT_ACCOUNT_INACTIVE'
      using errcode = 'P0001', detail = 'KC_RT_ACCOUNT_INACTIVE';
  end if;

  v_role := public.kc_rt_user_role(v_user.raw_app_meta_data);
  if v_role not in ('customer', 'owner') then
    raise exception 'KC_PUSH_ROLE_NOT_ALLOWED'
      using errcode = 'P0001', detail = 'KC_PUSH_ROLE_NOT_ALLOWED';
  end if;

  v_customer_topic_row := public.kc_rt_ensure_topic('customer', p_user_id);

  if v_role = 'owner' then
    select s.id
    into v_stall_id
    from public.catalog_stalls s
    where s.owner_id = p_user_id
    limit 1;

    if found then
      v_has_stall := true;
      v_stall_topic_row := public.kc_rt_ensure_topic('stall', v_stall_id);
    end if;
  end if;

  select coalesce(max(s.seq), 0)
  into v_last_seq
  from public.order_realtime_signals s
  where s.customer_id = p_user_id
     or (v_role = 'owner' and s.owner_id = p_user_id);

  return jsonb_build_object(
    'user_id', p_user_id,
    'role', v_role,
    'customer_topic', public.kc_rt_format_topic(
      'customer', p_user_id, v_customer_topic_row.topic_epoch, v_customer_topic_row.topic_token
    ),
    'customer_epoch', v_customer_topic_row.topic_epoch,
    'stall_id', case when v_has_stall then v_stall_id else null end,
    'stall_topic', case when v_has_stall then public.kc_rt_format_topic(
      'stall', v_stall_id, v_stall_topic_row.topic_epoch, v_stall_topic_row.topic_token
    ) else null end,
    'stall_epoch', case when v_has_stall then v_stall_topic_row.topic_epoch else null end,
    'last_seq', v_last_seq
  );
end;
$$;

create or replace function public.kc_rt_poll_signals(
  p_user_id uuid,
  p_after_seq bigint default 0,
  p_limit integer default 50
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user record;
  v_role text;
  v_now timestamptz := now();
  v_after_seq bigint := greatest(coalesce(p_after_seq, 0), 0);
  v_limit integer := least(greatest(coalesce(p_limit, 50), 1), 100);
  v_customer_epoch integer := 1;
  v_stall_epoch integer := null;
  v_stall_id uuid := null;
  v_items jsonb := '[]'::jsonb;
  v_last_seq bigint := v_after_seq;
begin
  if p_user_id is null then
    raise exception 'KC_RT_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_RT_INVALID_INPUT';
  end if;

  select u.id, u.banned_until, u.raw_app_meta_data
  into v_user
  from auth.users u
  where u.id = p_user_id;

  if not found or not public.kc_rt_is_user_active(v_user.banned_until, v_now) then
    raise exception 'KC_RT_ACCOUNT_INACTIVE'
      using errcode = 'P0001', detail = 'KC_RT_ACCOUNT_INACTIVE';
  end if;

  v_role := public.kc_rt_user_role(v_user.raw_app_meta_data);
  if v_role not in ('customer', 'owner') then
    raise exception 'KC_PUSH_ROLE_NOT_ALLOWED'
      using errcode = 'P0001', detail = 'KC_PUSH_ROLE_NOT_ALLOWED';
  end if;

  select t.topic_epoch
  into v_customer_epoch
  from public.realtime_channel_topics t
  where t.scope_type = 'customer' and t.scope_id = p_user_id;
  v_customer_epoch := coalesce(v_customer_epoch, 1);

  if v_role = 'owner' then
    select s.id
    into v_stall_id
    from public.catalog_stalls s
    where s.owner_id = p_user_id
    limit 1;

    if found then
      select t.topic_epoch
      into v_stall_epoch
      from public.realtime_channel_topics t
      where t.scope_type = 'stall' and t.scope_id = v_stall_id;
      v_stall_epoch := coalesce(v_stall_epoch, 1);
    end if;
  end if;

  -- Strictly scoped to actor's own customer orders or (when active owner) own stall orders.
  -- Minimal non-sensitive fields only: details are fetched via authorized Shelf REST endpoints.
  with scoped as (
    select
      s.seq,
      s.event_id,
      s.order_id,
      s.stall_id,
      s.to_status,
      s.created_at,
      case
        when v_role = 'owner' and s.owner_id = p_user_id and s.customer_id = p_user_id then 'both'
        when v_role = 'owner' and s.owner_id = p_user_id then 'owner'
        else 'customer'
      end as audience_scope
    from public.order_realtime_signals s
    where s.seq > v_after_seq
      and (
        s.customer_id = p_user_id
        or (v_role = 'owner' and s.owner_id = p_user_id)
      )
    order by s.seq asc
    limit v_limit
  )
  select
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'seq', scoped.seq,
          'event_id', scoped.event_id,
          'order_id', scoped.order_id,
          'stall_id', scoped.stall_id,
          'to_status', scoped.to_status,
          'audience_scope', scoped.audience_scope,
          'created_at', scoped.created_at
        )
        order by scoped.seq asc
      ),
      '[]'::jsonb
    ),
    coalesce(max(scoped.seq), v_after_seq)
  into v_items, v_last_seq
  from scoped;

  return jsonb_build_object(
    'items', v_items,
    'last_seq', v_last_seq,
    'customer_epoch', v_customer_epoch,
    'stall_epoch', v_stall_epoch
  );
end;
$$;

-- =============================================================================
-- 10. Server-side Realtime broadcast claim RPC (for Supabase Realtime Broadcast + SSE broker)
-- =============================================================================
create or replace function public.kc_rt_claim_unbroadcasted_signals(
  p_limit integer default 50,
  p_now timestamptz default now()
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_limit integer := least(greatest(coalesce(p_limit, 50), 1), 100);
  v_now timestamptz := coalesce(p_now, now());
  v_items jsonb := '[]'::jsonb;
begin
  with claimed as (
    select s.seq
    from public.order_realtime_signals s
    where s.broadcasted_at is null
    order by s.seq asc
    limit v_limit
    for update skip locked
  ),
  updated as (
    update public.order_realtime_signals s
    set broadcasted_at = v_now
    from claimed c
    where s.seq = c.seq
    returning s.*
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'seq', u.seq,
        'event_id', u.event_id,
        'order_id', u.order_id,
        'stall_id', u.stall_id,
        'customer_id', u.customer_id,
        'owner_id', u.owner_id,
        'to_status', u.to_status,
        'customer_topic', u.customer_topic,
        'stall_topic', u.stall_topic,
        'created_at', u.created_at
      )
      order by u.seq asc
    ),
    '[]'::jsonb
  )
  into v_items
  from updated u;

  return jsonb_build_object('items', v_items);
end;
$$;

-- =============================================================================
-- 11. Push worker atomic claim & completion RPCs (ORDER-017A, RT-TECH-002, R1, R2)
-- =============================================================================
create or replace function public.kc_push_claim_pending_deliveries(
  p_batch_size integer default 25,
  p_max_attempts integer default 5,
  p_lock_seconds integer default 60,
  p_now timestamptz default now()
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_batch integer := least(greatest(coalesce(p_batch_size, 25), 1), 100);
  v_max_attempts integer := least(greatest(coalesce(p_max_attempts, 5), 1), 10);
  v_lock_seconds integer := least(greatest(coalesce(p_lock_seconds, 60), 10), 600);
  v_now timestamptz := coalesce(p_now, now());
  v_event record;
  v_user record;
  v_order record;
  v_role text;
  v_eligible boolean;
  v_device_count integer;
  v_delivery record;
  v_items jsonb := '[]'::jsonb;
begin
  -- Step 1: Fan out newly created order_notification_events into deduplicated device deliveries.
  for v_event in
    select e.*
    from public.order_notification_events e
    where e.delivered_at is null
      and not exists (
        select 1
        from public.order_push_deliveries d
        where d.notification_event_id = e.id
      )
    order by e.created_at asc, e.id asc
    limit v_batch
    for update of e skip locked
  loop
    -- Strict ORDER-017A allowlist defense-in-depth (never admin, never selesai/gagal_diambil).
    v_eligible := (
      (v_event.recipient_role = 'owner'
        and v_event.event_type in ('order_created', 'order_cancelled'))
      or
      (v_event.recipient_role = 'customer'
        and v_event.event_type in (
          'order_accepted', 'order_rejected', 'order_ready',
          'order_failed_fulfill', 'order_not_picked_up'
        ))
    );

    if v_eligible then
      select u.id, u.banned_until, u.email_confirmed_at, u.raw_app_meta_data
      into v_user
      from auth.users u
      where u.id = v_event.recipient_id;

      if not found
         or not public.kc_rt_is_user_active(v_user.banned_until, v_now)
         or v_user.email_confirmed_at is null then
        v_eligible := false;
      else
        v_role := public.kc_rt_user_role(v_user.raw_app_meta_data);
        if v_role = 'admin' then
          v_eligible := false;
        elsif v_event.recipient_role = 'owner' and v_role <> 'owner' then
          v_eligible := false;
        end if;
      end if;
    end if;

    if v_eligible then
      select o.id, o.customer_id, s.owner_id
      into v_order
      from public.orders o
      join public.catalog_stalls s on s.id = o.stall_id
      where o.id = v_event.order_id;

      if not found then
        v_eligible := false;
      elsif v_event.recipient_role = 'customer' and v_order.customer_id <> v_event.recipient_id then
        v_eligible := false;
      elsif v_event.recipient_role = 'owner' and v_order.owner_id <> v_event.recipient_id then
        v_eligible := false;
      end if;
    end if;

    if not v_eligible then
      update public.order_notification_events
      set delivered_at = v_now
      where id = v_event.id;
      continue;
    end if;

    insert into public.order_push_deliveries (
      notification_event_id,
      device_id,
      recipient_id,
      recipient_role,
      event_type,
      status,
      attempt_count,
      max_attempts,
      next_retry_at,
      created_at,
      updated_at
    )
    select
      v_event.id,
      dev.id,
      v_event.recipient_id,
      v_event.recipient_role,
      v_event.event_type,
      'pending',
      0,
      v_max_attempts,
      v_now,
      v_now,
      v_now
    from public.user_push_devices dev
    where dev.user_id = v_event.recipient_id
      and dev.is_active = true
      and dev.revoked_at is null
    on conflict (notification_event_id, device_id) do nothing;

    get diagnostics v_device_count = row_count;

    -- Best-effort when recipient has no registered/active push device (e.g. notification permission denied).
    if v_device_count = 0 then
      update public.order_notification_events
      set delivered_at = v_now
      where id = v_event.id;
    end if;
  end loop;

  -- Step 2: Claim due pending, retry-scheduled, or crash-recovered deliveries atomically.
  for v_delivery in
    select
      d.id as delivery_id,
      d.notification_event_id,
      d.device_id,
      d.recipient_id,
      d.recipient_role,
      d.event_type,
      d.attempt_count,
      d.max_attempts,
      dev.device_id as client_device_id,
      dev.fcm_token,
      dev.is_active as device_is_active,
      dev.revoked_at as device_revoked_at,
      u.banned_until,
      u.raw_app_meta_data,
      e.order_id,
      o.order_number,
      s.name as stall_name
    from public.order_push_deliveries d
    join public.order_notification_events e on e.id = d.notification_event_id
    join public.user_push_devices dev on dev.id = d.device_id
    join auth.users u on u.id = d.recipient_id
    join public.orders o on o.id = e.order_id
    join public.catalog_stalls s on s.id = o.stall_id
    where (
      (d.status in ('pending', 'retry_scheduled') and d.next_retry_at <= v_now)
      or
      (d.status = 'in_flight' and d.locked_until is not null and d.locked_until <= v_now)
    )
    order by d.next_retry_at asc, d.created_at asc, d.id asc
    limit v_batch
    for update of d skip locked
  loop
    v_role := public.kc_rt_user_role(v_delivery.raw_app_meta_data);

    -- Re-verify authorization before dispatching any queued/retried push (R2).
    if not v_delivery.device_is_active
       or v_delivery.device_revoked_at is not null
       or not public.kc_rt_is_user_active(v_delivery.banned_until, v_now)
       or v_role = 'admin'
       or (v_delivery.recipient_role = 'owner' and v_role <> 'owner') then
      update public.order_push_deliveries
      set status = 'skipped',
          last_error_code = 'DEVICE_OR_ACCOUNT_REVOKED',
          locked_until = null,
          updated_at = v_now
      where id = v_delivery.delivery_id;

      if not exists (
        select 1
        from public.order_push_deliveries rem
        where rem.notification_event_id = v_delivery.notification_event_id
          and rem.status not in ('sent', 'failed_permanent', 'skipped')
      ) then
        update public.order_notification_events
        set delivered_at = coalesce(delivered_at, v_now)
        where id = v_delivery.notification_event_id;
      end if;
      continue;
    end if;

    if v_delivery.attempt_count >= v_delivery.max_attempts then
      update public.order_push_deliveries
      set status = 'failed_permanent',
          last_error_code = coalesce(last_error_code, 'MAX_ATTEMPTS_EXCEEDED'),
          locked_until = null,
          updated_at = v_now
      where id = v_delivery.delivery_id;

      if not exists (
        select 1
        from public.order_push_deliveries rem
        where rem.notification_event_id = v_delivery.notification_event_id
          and rem.status not in ('sent', 'failed_permanent', 'skipped')
      ) then
        update public.order_notification_events
        set delivered_at = coalesce(delivered_at, v_now)
        where id = v_delivery.notification_event_id;
      end if;
      continue;
    end if;

    update public.order_push_deliveries
    set status = 'in_flight',
        attempt_count = attempt_count + 1,
        locked_until = v_now + make_interval(secs => v_lock_seconds),
        updated_at = v_now
    where id = v_delivery.delivery_id;

    v_items := v_items || jsonb_build_array(
      jsonb_build_object(
        'delivery_id', v_delivery.delivery_id,
        'notification_event_id', v_delivery.notification_event_id,
        'order_id', v_delivery.order_id,
        'order_number', v_delivery.order_number,
        'stall_name', v_delivery.stall_name,
        'recipient_id', v_delivery.recipient_id,
        'recipient_role', v_delivery.recipient_role,
        'event_type', v_delivery.event_type,
        'device_id', v_delivery.client_device_id,
        'fcm_token', v_delivery.fcm_token,
        'attempt_count', v_delivery.attempt_count + 1,
        'max_attempts', v_delivery.max_attempts
      )
    );
  end loop;

  return jsonb_build_object('items', v_items);
end;
$$;

create or replace function public.kc_push_complete_delivery(
  p_delivery_id uuid,
  p_outcome text,
  p_error_code text default null,
  p_provider_message_id text default null,
  p_retry_delay_seconds integer default 30,
  p_deactivate_device boolean default false,
  p_now timestamptz default now()
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_delivery public.order_push_deliveries%rowtype;
  v_now timestamptz := coalesce(p_now, now());
  v_outcome text := lower(btrim(coalesce(p_outcome, '')));
  v_retry_delay integer := least(greatest(coalesce(p_retry_delay_seconds, 30), 1), 3600);
  v_next_status text;
  v_event_completed boolean := false;
begin
  if p_delivery_id is null or v_outcome not in ('sent', 'retry', 'failed_permanent', 'skipped') then
    raise exception 'KC_RT_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_RT_INVALID_INPUT';
  end if;

  select *
  into v_delivery
  from public.order_push_deliveries
  where id = p_delivery_id
  for update;

  if not found then
    raise exception 'KC_RT_DELIVERY_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_RT_DELIVERY_NOT_FOUND';
  end if;

  if v_outcome = 'sent' then
    v_next_status := 'sent';
    update public.order_push_deliveries
    set status = 'sent',
        provider_message_id = left(nullif(btrim(coalesce(p_provider_message_id, '')), ''), 256),
        last_error_code = null,
        sent_at = v_now,
        locked_until = null,
        updated_at = v_now
    where id = v_delivery.id;

  elsif v_outcome = 'retry' then
    if v_delivery.attempt_count >= v_delivery.max_attempts then
      v_next_status := 'failed_permanent';
      update public.order_push_deliveries
      set status = 'failed_permanent',
          last_error_code = left(coalesce(nullif(btrim(coalesce(p_error_code, '')), ''), 'MAX_ATTEMPTS_EXCEEDED'), 128),
          locked_until = null,
          updated_at = v_now
      where id = v_delivery.id;
    else
      v_next_status := 'retry_scheduled';
      update public.order_push_deliveries
      set status = 'retry_scheduled',
          last_error_code = left(nullif(btrim(coalesce(p_error_code, '')), ''), 128),
          next_retry_at = v_now + make_interval(secs => v_retry_delay),
          locked_until = null,
          updated_at = v_now
      where id = v_delivery.id;
    end if;

  elsif v_outcome = 'skipped' then
    v_next_status := 'skipped';
    update public.order_push_deliveries
    set status = 'skipped',
        last_error_code = left(nullif(btrim(coalesce(p_error_code, '')), ''), 128),
        locked_until = null,
        updated_at = v_now
    where id = v_delivery.id;

  else
    v_next_status := 'failed_permanent';
    update public.order_push_deliveries
    set status = 'failed_permanent',
        last_error_code = left(nullif(btrim(coalesce(p_error_code, '')), ''), 128),
        locked_until = null,
        updated_at = v_now
    where id = v_delivery.id;

    if p_deactivate_device is true then
      update public.user_push_devices
      set is_active = false,
          revoked_at = v_now,
          updated_at = v_now
      where id = v_delivery.device_id;
    end if;
  end if;

  if not exists (
    select 1
    from public.order_push_deliveries rem
    where rem.notification_event_id = v_delivery.notification_event_id
      and rem.status not in ('sent', 'failed_permanent', 'skipped')
  ) then
    update public.order_notification_events
    set delivered_at = coalesce(delivered_at, v_now)
    where id = v_delivery.notification_event_id;
    v_event_completed := true;
  end if;

  return jsonb_build_object(
    'delivery_id', v_delivery.id,
    'status', v_next_status,
    'event_completed', v_event_completed
  );
end;
$$;

-- =============================================================================
-- 12. Strict function permissions (service_role only)
-- =============================================================================
revoke all on function
  public.kc_rt_user_role(jsonb),
  public.kc_rt_is_user_active(timestamptz, timestamptz),
  public.kc_rt_format_topic(text, uuid, integer, text),
  public.kc_rt_ensure_topic(text, uuid),
  public.kc_trg_emit_order_realtime_signal(),
  public.kc_rt_rotate_topics_for_user(uuid),
  public.kc_trg_auth_user_realtime_security(),
  public.kc_rt_register_push_device(uuid, text, text, text),
  public.kc_rt_revoke_push_device(uuid, text, boolean),
  public.kc_rt_get_channel_grant(uuid),
  public.kc_rt_poll_signals(uuid, bigint, integer),
  public.kc_rt_claim_unbroadcasted_signals(integer, timestamptz),
  public.kc_push_claim_pending_deliveries(integer, integer, integer, timestamptz),
  public.kc_push_complete_delivery(uuid, text, text, text, integer, boolean, timestamptz)
from public, anon, authenticated;

grant execute on function
  public.kc_rt_user_role(jsonb),
  public.kc_rt_is_user_active(timestamptz, timestamptz),
  public.kc_rt_format_topic(text, uuid, integer, text),
  public.kc_rt_ensure_topic(text, uuid),
  public.kc_trg_emit_order_realtime_signal(),
  public.kc_rt_rotate_topics_for_user(uuid),
  public.kc_trg_auth_user_realtime_security(),
  public.kc_rt_register_push_device(uuid, text, text, text),
  public.kc_rt_revoke_push_device(uuid, text, boolean),
  public.kc_rt_get_channel_grant(uuid),
  public.kc_rt_poll_signals(uuid, bigint, integer),
  public.kc_rt_claim_unbroadcasted_signals(integer, timestamptz),
  public.kc_push_claim_pending_deliveries(integer, integer, integer, timestamptz),
  public.kc_push_complete_delivery(uuid, text, text, text, integer, boolean, timestamptz)
to service_role;

commit;
