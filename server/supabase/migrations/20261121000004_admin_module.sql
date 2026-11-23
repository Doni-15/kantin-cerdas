-- Admin module schema, immutable audit logs, and concurrency-safe RPCs.
-- Covers ADMIN-001 through ADMIN-005 (including ADMIN-003A, ADMIN-003B),
-- CUSTOMER-006A, and ORDER-013B (gagal_diambil is terminal, not active).
-- Forward-only migration; does not modify applied historical migrations.
begin;

-- =============================================================================
-- 1. Immutable Admin Audit Trail (ADMIN-002, ADMIN-003, ADMIN-005)
-- =============================================================================
create table public.admin_action_logs (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references auth.users(id),
  action_type text not null check (
    action_type in (
      'application_approved',
      'application_rejected',
      'user_deactivated',
      'user_reactivated'
    )
  ),
  target_user_id uuid not null references auth.users(id),
  target_application_id uuid null references public.owner_applications(id),
  reason text null check (
    reason is null or char_length(btrim(reason)) between 1 and 500
  ),
  summary text not null check (char_length(btrim(summary)) between 1 and 240),
  created_at timestamptz not null default now()
);

create index admin_action_logs_target_created
  on public.admin_action_logs (target_user_id, created_at desc, id desc);

create index admin_action_logs_created
  on public.admin_action_logs (created_at desc, id desc);

alter table public.admin_action_logs enable row level security;
revoke all on public.admin_action_logs from public, anon, authenticated;
grant select, insert on public.admin_action_logs to service_role;

create function public.kc_guard_admin_action_logs_immutable()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  raise exception 'KC_ADMIN_AUDIT_IMMUTABLE'
    using errcode = 'P0001', detail = 'KC_ADMIN_AUDIT_IMMUTABLE';
end;
$$;

create trigger trg_guard_admin_action_logs_immutable
  before update or delete on public.admin_action_logs
  for each row
  execute function public.kc_guard_admin_action_logs_immutable();

-- =============================================================================
-- 2. Internal Helpers for Active Admin Verification & Safe Profile Summary
-- =============================================================================
create function public.kc_admin_require_active(p_admin_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_role text;
  v_banned timestamptz;
begin
  if p_admin_id is null then
    raise exception 'KC_ADMIN_REQUIRED'
      using errcode = 'P0001', detail = 'KC_ADMIN_REQUIRED';
  end if;

  select
    coalesce(u.raw_app_meta_data ->> 'kantin_role', ''),
    u.banned_until
  into v_role, v_banned
  from auth.users u
  where u.id = p_admin_id;

  if not found or v_role <> 'admin' then
    raise exception 'KC_ADMIN_REQUIRED'
      using errcode = 'P0001', detail = 'KC_ADMIN_REQUIRED';
  end if;

  if v_banned is not null and v_banned > now() then
    raise exception 'KC_ADMIN_INACTIVE'
      using errcode = 'P0001', detail = 'KC_ADMIN_INACTIVE';
  end if;
end;
$$;

create function public.kc_admin_user_display_name(
  p_email text,
  p_raw_user_meta_data jsonb
)
returns text
language sql
immutable
security definer
set search_path = ''
as $$
  select coalesce(
    nullif(btrim(coalesce(p_raw_user_meta_data ->> 'display_name', '')), ''),
    nullif(btrim(coalesce(p_raw_user_meta_data ->> 'registration_name', '')), ''),
    nullif(split_part(coalesce(p_email, ''), '@', 1), ''),
    'Pengguna'
  );
$$;

create function public.kc_admin_user_role(p_raw_app_meta_data jsonb)
returns text
language sql
immutable
security definer
set search_path = ''
as $$
  select case coalesce(p_raw_app_meta_data ->> 'kantin_role', '')
    when 'owner' then 'owner'
    when 'admin' then 'admin'
    else 'customer'
  end;
$$;

create function public.kc_admin_application_json(p_app public.owner_applications)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_applicant auth.users%rowtype;
  v_decider_name text;
begin
  select u.*
  into v_applicant
  from auth.users u
  where u.id = p_app.customer_id;

  if p_app.decided_by is not null then
    select public.kc_admin_user_display_name(d.email, d.raw_user_meta_data)
    into v_decider_name
    from auth.users d
    where d.id = p_app.decided_by;
  end if;

  return jsonb_build_object(
    'id', p_app.id,
    'customer_id', p_app.customer_id,
    'applicant_name', public.kc_admin_user_display_name(
      v_applicant.email,
      v_applicant.raw_user_meta_data
    ),
    'applicant_email', coalesce(v_applicant.email, ''),
    'applicant_role', public.kc_admin_user_role(v_applicant.raw_app_meta_data),
    'applicant_is_active', (
      v_applicant.id is not null and
      (v_applicant.banned_until is null or v_applicant.banned_until <= now())
    ),
    'planned_stall_name', p_app.planned_stall_name,
    'planned_location', p_app.planned_location,
    'reason', p_app.reason,
    'status', p_app.status,
    'rejection_reason', p_app.rejection_reason,
    'decided_by', p_app.decided_by,
    'decided_by_name', v_decider_name,
    'decided_at', p_app.decided_at,
    'created_at', p_app.created_at,
    'active_order_indicator', public.kc_admin_user_active_order_indicator(p_app.customer_id)
  );
end;
$$;

-- =============================================================================
-- 3. Dashboard Summary RPC (ADMIN-005, UI-ADMIN-001)
-- =============================================================================
-- Strictly administrative counts + pending application previews.
-- Zero transaction totals, income/expense analytics, or order contents.
create function public.kc_admin_dashboard(p_admin_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_total_users integer := 0;
  v_active_users integer := 0;
  v_inactive_users integer := 0;
  v_pending_applications integer := 0;
  v_total_stalls integer := 0;
  v_published_stalls integer := 0;
  v_open_stalls integer := 0;
  v_recent_pending jsonb;
begin
  perform public.kc_admin_require_active(p_admin_id);

  select
    count(*)::integer,
    count(*) filter (where u.banned_until is null or u.banned_until <= now())::integer,
    count(*) filter (where u.banned_until is not null and u.banned_until > now())::integer
  into v_total_users, v_active_users, v_inactive_users
  from auth.users u;

  select count(*)::integer
  into v_pending_applications
  from public.owner_applications a
  where a.status = 'menunggu_review';

  select
    count(*)::integer,
    count(*) filter (where s.is_listed)::integer,
    count(*) filter (where s.is_listed and s.is_open)::integer
  into v_total_stalls, v_published_stalls, v_open_stalls
  from public.catalog_stalls s;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', row_data.id,
        'customer_id', row_data.customer_id,
        'applicant_name', row_data.applicant_name,
        'applicant_email', row_data.applicant_email,
        'planned_stall_name', row_data.planned_stall_name,
        'planned_location', row_data.planned_location,
        'status', row_data.status,
        'created_at', row_data.created_at
      )
      order by row_data.created_at desc, row_data.id desc
    ),
    '[]'::jsonb
  )
  into v_recent_pending
  from (
    select
      a.id,
      a.customer_id,
      public.kc_admin_user_display_name(u.email, u.raw_user_meta_data) as applicant_name,
      coalesce(u.email, '') as applicant_email,
      a.planned_stall_name,
      a.planned_location,
      a.status,
      a.created_at
    from public.owner_applications a
    join auth.users u on u.id = a.customer_id
    where a.status = 'menunggu_review'
    order by a.created_at desc, a.id desc
    limit 5
  ) row_data;

  return jsonb_build_object(
    'total_users', v_total_users,
    'active_users', v_active_users,
    'inactive_users', v_inactive_users,
    'pending_applications', v_pending_applications,
    'total_stalls', v_total_stalls,
    'published_stalls', v_published_stalls,
    'open_stalls', v_open_stalls,
    'recent_pending_applications', v_recent_pending
  );
end;
$$;

-- =============================================================================
-- 4. Owner Applications List, Detail & Atomic Review (ADMIN-001, ADMIN-002, CUSTOMER-006A)
-- =============================================================================
create function public.kc_admin_list_applications(
  p_admin_id uuid,
  p_scope text default 'pending',
  p_limit integer default 30,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_scope text := coalesce(nullif(btrim(p_scope), ''), 'pending');
  v_limit integer := greatest(1, least(coalesce(p_limit, 30), 100));
  v_offset integer := greatest(0, coalesce(p_offset, 0));
  v_items jsonb;
begin
  perform public.kc_admin_require_active(p_admin_id);

  if v_scope not in ('pending', 'history', 'all') then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  select coalesce(jsonb_agg(sub.item order by sub.ord_ts desc, sub.id desc), '[]'::jsonb)
  into v_items
  from (
    select
      a.id,
      case
        when v_scope = 'history' then coalesce(a.decided_at, a.created_at)
        else a.created_at
      end as ord_ts,
      public.kc_admin_application_json(a) as item
    from public.owner_applications a
    where (
      v_scope = 'all'
      or (v_scope = 'pending' and a.status = 'menunggu_review')
      or (v_scope = 'history' and a.status in ('disetujui', 'ditolak'))
    )
    order by
      case
        when v_scope = 'history' then coalesce(a.decided_at, a.created_at)
        else a.created_at
      end desc,
      a.id desc
    limit v_limit offset v_offset
  ) sub;

  return jsonb_build_object(
    'items', v_items,
    'scope', v_scope,
    'limit', v_limit,
    'offset', v_offset
  );
end;
$$;

create function public.kc_admin_get_application(
  p_admin_id uuid,
  p_application_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_app public.owner_applications%rowtype;
begin
  perform public.kc_admin_require_active(p_admin_id);

  select a.*
  into v_app
  from public.owner_applications a
  where a.id = p_application_id;

  if not found then
    raise exception 'KC_APPLICATION_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_APPLICATION_NOT_FOUND';
  end if;

  return public.kc_admin_application_json(v_app);
end;
$$;

create function public.kc_admin_review_application(
  p_admin_id uuid,
  p_application_id uuid,
  p_decision text,
  p_rejection_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_decision text := lower(btrim(coalesce(p_decision, '')));
  v_reason text := btrim(coalesce(p_rejection_reason, ''));
  v_app public.owner_applications%rowtype;
  v_target auth.users%rowtype;
  v_target_role text;
  v_has_active_orders boolean := false;
begin
  perform public.kc_admin_require_active(p_admin_id);

  if v_decision not in ('disetujui', 'ditolak') then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  if v_decision = 'ditolak' then
    if char_length(v_reason) = 0 then
      raise exception 'KC_REASON_REQUIRED'
        using errcode = 'P0001', detail = 'KC_REASON_REQUIRED';
    end if;
    if char_length(v_reason) > 500 then
      raise exception 'KC_INVALID_INPUT'
        using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
    end if;
  end if;

  -- Lock the application row first to serialize concurrent Admin reviews.
  select a.*
  into v_app
  from public.owner_applications a
  where a.id = p_application_id
  for update;

  if not found then
    raise exception 'KC_APPLICATION_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_APPLICATION_NOT_FOUND';
  end if;

  if v_app.status <> 'menunggu_review' then
    raise exception 'KC_APPLICATION_ALREADY_DECIDED'
      using errcode = 'P0001', detail = 'KC_APPLICATION_ALREADY_DECIDED';
  end if;

  -- Re-check active admin state in case another Admin deactivated caller.
  perform public.kc_admin_require_active(p_admin_id);

  -- Canonical lock order matching kc_customer_checkout:
  -- customer_carts -> catalog_stalls -> auth.users (prevents 40P01 deadlock).
  perform 1
  from public.customer_carts c
  where c.customer_id = v_app.customer_id
  for update;

  select u.*
  into v_target
  from auth.users u
  where u.id = v_app.customer_id
  for update;

  if not found then
    raise exception 'KC_USER_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_USER_NOT_FOUND';
  end if;

  if v_decision = 'disetujui' then
    if v_target.banned_until is not null and v_target.banned_until > now() then
      raise exception 'KC_USER_INACTIVE'
        using errcode = 'P0001', detail = 'KC_USER_INACTIVE';
    end if;

    v_target_role := public.kc_admin_user_role(v_target.raw_app_meta_data);
    if v_target_role = 'owner' then
      raise exception 'KC_ALREADY_OWNER'
        using errcode = 'P0001', detail = 'KC_ALREADY_OWNER';
    end if;
    if v_target_role <> 'customer' then
      raise exception 'KC_TARGET_NOT_CUSTOMER'
        using errcode = 'P0001', detail = 'KC_TARGET_NOT_CUSTOMER';
    end if;

    -- CUSTOMER-006A & ADMIN-002: applicant with active orders cannot be approved;
    -- terminal statuses including gagal_diambil (ORDER-013B) do NOT block.
    select exists (
      select 1
      from public.orders o
      join public.catalog_stalls s on s.id = o.stall_id
      where (o.customer_id = v_app.customer_id or s.owner_id = v_app.customer_id)
        and o.status in ('menunggu_konfirmasi', 'diproses', 'siap_diambil')
    )
    into v_has_active_orders;

    if v_has_active_orders then
      raise exception 'KC_ACTIVE_ORDERS_PRESENT'
        using errcode = 'P0001', detail = 'KC_ACTIVE_ORDERS_PRESENT';
    end if;

    update public.owner_applications
    set
      status = 'disetujui',
      rejection_reason = null,
      decided_by = p_admin_id,
      decided_at = now(),
      updated_at = now()
    where id = v_app.id
    returning * into v_app;

    -- Promote role to Owner only; ADMIN-001 never auto-creates a stall.
    update auth.users
    set
      raw_app_meta_data = jsonb_set(
        coalesce(raw_app_meta_data, '{}'::jsonb),
        '{kantin_role}',
        '"owner"'::jsonb,
        true
      ),
      updated_at = now()
    where id = v_app.customer_id;

    insert into public.admin_action_logs (
      admin_id,
      action_type,
      target_user_id,
      target_application_id,
      reason,
      summary
    )
    values (
      p_admin_id,
      'application_approved',
      v_app.customer_id,
      v_app.id,
      null,
      'Pengajuan Owner disetujui'
    );
  else
    update public.owner_applications
    set
      status = 'ditolak',
      rejection_reason = v_reason,
      decided_by = p_admin_id,
      decided_at = now(),
      updated_at = now()
    where id = v_app.id
    returning * into v_app;

    insert into public.admin_action_logs (
      admin_id,
      action_type,
      target_user_id,
      target_application_id,
      reason,
      summary
    )
    values (
      p_admin_id,
      'application_rejected',
      v_app.customer_id,
      v_app.id,
      v_reason,
      'Pengajuan Owner ditolak'
    );
  end if;

  return public.kc_admin_application_json(v_app);
end;
$$;

-- =============================================================================
-- 5. User Oversight, Deactivate/Reactivate & Last-Admin Protection (ADMIN-003/A/B, ADMIN-005)
-- =============================================================================
create function public.kc_admin_list_users(
  p_admin_id uuid,
  p_role text default null,
  p_status text default null,
  p_query text default null,
  p_limit integer default 30,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_role text := nullif(lower(btrim(coalesce(p_role, ''))), '');
  v_status text := nullif(lower(btrim(coalesce(p_status, ''))), '');
  v_query text := nullif(btrim(coalesce(p_query, '')), '');
  v_limit integer := greatest(1, least(coalesce(p_limit, 30), 100));
  v_offset integer := greatest(0, coalesce(p_offset, 0));
  v_items jsonb;
begin
  perform public.kc_admin_require_active(p_admin_id);

  if v_role is not null and v_role not in ('customer', 'owner', 'admin') then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;
  if v_status is not null and v_status not in ('active', 'inactive') then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;
  if v_query is not null and char_length(v_query) > 120 then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  select coalesce(jsonb_agg(row_json order by created_at desc, id desc), '[]'::jsonb)
  into v_items
  from (
    select
      u.id,
      u.created_at,
      jsonb_build_object(
        'id', u.id,
        'email', coalesce(u.email, ''),
        'display_name', public.kc_admin_user_display_name(u.email, u.raw_user_meta_data),
        'role', public.kc_admin_user_role(u.raw_app_meta_data),
        'is_active', (u.banned_until is null or u.banned_until <= now()),
        'email_verified', (u.email_confirmed_at is not null),
        'created_at', u.created_at,
        'active_order_indicator', public.kc_admin_user_active_order_indicator(u.id)
      ) as row_json
    from auth.users u
    where (v_role is null or public.kc_admin_user_role(u.raw_app_meta_data) = v_role)
      and (
        v_status is null
        or (v_status = 'active' and (u.banned_until is null or u.banned_until <= now()))
        or (v_status = 'inactive' and u.banned_until is not null and u.banned_until > now())
      )
      and (
        v_query is null
        or strpos(lower(coalesce(u.email, '')), lower(v_query)) > 0
        or strpos(
          lower(public.kc_admin_user_display_name(u.email, u.raw_user_meta_data)),
          lower(v_query)
        ) > 0
      )
    order by u.created_at desc, u.id desc
    limit v_limit offset v_offset
  ) rows;

  return jsonb_build_object(
    'items', v_items,
    'limit', v_limit,
    'offset', v_offset
  );
end;
$$;

create function public.kc_admin_get_user(
  p_admin_id uuid,
  p_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user auth.users%rowtype;
  v_logs jsonb;
begin
  perform public.kc_admin_require_active(p_admin_id);

  select u.*
  into v_user
  from auth.users u
  where u.id = p_user_id;

  if not found then
    raise exception 'KC_USER_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_USER_NOT_FOUND';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', l.id,
        'admin_id', l.admin_id,
        'admin_name', public.kc_admin_user_display_name(a.email, a.raw_user_meta_data),
        'action_type', l.action_type,
        'target_user_id', l.target_user_id,
        'target_application_id', l.target_application_id,
        'reason', l.reason,
        'summary', l.summary,
        'created_at', l.created_at
      )
      order by l.created_at desc, l.id desc
    ),
    '[]'::jsonb
  )
  into v_logs
  from (
    select *
    from public.admin_action_logs
    where target_user_id = p_user_id
    order by created_at desc, id desc
    limit 10
  ) l
  join auth.users a on a.id = l.admin_id;

  return jsonb_build_object(
    'id', v_user.id,
    'email', coalesce(v_user.email, ''),
    'display_name', public.kc_admin_user_display_name(
      v_user.email,
      v_user.raw_user_meta_data
    ),
    'role', public.kc_admin_user_role(v_user.raw_app_meta_data),
    'is_active', (v_user.banned_until is null or v_user.banned_until <= now()),
    'email_verified', (v_user.email_confirmed_at is not null),
    'created_at', v_user.created_at,
    'active_order_indicator', public.kc_admin_user_active_order_indicator(v_user.id),
    'recent_logs', v_logs
  );
end;
$$;

create function public.kc_admin_set_user_active_status(
  p_admin_id uuid,
  p_target_user_id uuid,
  p_is_active boolean,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reason text := btrim(coalesce(p_reason, ''));
  v_target auth.users%rowtype;
  v_target_role text;
  v_currently_active boolean;
  v_remaining_admins integer;
  v_has_active_orders boolean := false;
begin
  perform public.kc_admin_require_active(p_admin_id);

  if p_target_user_id is null or p_is_active is null then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  if not p_is_active then
    if char_length(v_reason) = 0 then
      raise exception 'KC_REASON_REQUIRED'
        using errcode = 'P0001', detail = 'KC_REASON_REQUIRED';
    end if;
    if char_length(v_reason) > 500 then
      raise exception 'KC_INVALID_INPUT'
        using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
    end if;
    if p_admin_id = p_target_user_id then
      raise exception 'KC_SELF_DEACTIVATION_NOT_ALLOWED'
        using errcode = 'P0001', detail = 'KC_SELF_DEACTIVATION_NOT_ALLOWED';
    end if;
  elsif char_length(v_reason) > 500 then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  -- Canonical lock order matching kc_customer_checkout:
  -- customer_carts -> catalog_stalls -> auth.users (prevents 40P01 deadlock
  -- when checkout inserts into orders FK referencing auth.users).
  if not p_is_active then
    perform 1
    from public.customer_carts c
    where c.customer_id = p_target_user_id
    for update;

    perform 1
    from public.catalog_stalls s
    where s.owner_id = p_target_user_id
    for update;
  end if;

  -- Lock caller, target, and all admins in deterministic id order so concurrent
  -- cross-deactivation races serialize deadlock-free (ADMIN-005).
  perform 1
  from auth.users u
  where u.id in (p_admin_id, p_target_user_id)
     or public.kc_admin_user_role(u.raw_app_meta_data) = 'admin'
  order by u.id asc
  for update;

  -- Re-check caller after lock acquisition in case another Admin deactivated them first.
  perform public.kc_admin_require_active(p_admin_id);

  select u.*
  into v_target
  from auth.users u
  where u.id = p_target_user_id;

  if not found then
    raise exception 'KC_USER_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_USER_NOT_FOUND';
  end if;

  v_target_role := public.kc_admin_user_role(v_target.raw_app_meta_data);
  v_currently_active := (v_target.banned_until is null or v_target.banned_until <= now());

  if not p_is_active then
    if not v_currently_active then
      raise exception 'KC_USER_ALREADY_INACTIVE'
        using errcode = 'P0001', detail = 'KC_USER_ALREADY_INACTIVE';
    end if;

    -- ADMIN-005: never leave the system without an active Admin.
    if v_target_role = 'admin' then
      select count(*)::integer
      into v_remaining_admins
      from auth.users u
      where u.id <> p_target_user_id
        and public.kc_admin_user_role(u.raw_app_meta_data) = 'admin'
        and (u.banned_until is null or u.banned_until <= now());

      if v_remaining_admins < 1 then
        raise exception 'KC_LAST_ADMIN_PROTECTED'
          using errcode = 'P0001', detail = 'KC_LAST_ADMIN_PROTECTED';
      end if;
    end if;

    -- ADMIN-003A & ORDER-013B: block deactivation when active orders exist;
    -- gagal_diambil and other terminal states are excluded.
    select exists (
      select 1
      from public.orders o
      join public.catalog_stalls s on s.id = o.stall_id
      where (o.customer_id = p_target_user_id or s.owner_id = p_target_user_id)
        and o.status in ('menunggu_konfirmasi', 'diproses', 'siap_diambil')
    )
    into v_has_active_orders;

    if v_has_active_orders then
      raise exception 'KC_ACTIVE_ORDERS_PRESENT'
        using errcode = 'P0001', detail = 'KC_ACTIVE_ORDERS_PRESENT';
    end if;

    -- ADMIN-003B: deactivate account without modifying catalog_stalls.is_open / is_listed.
    -- Use finite far-future timestamptz (GoTrue cannot scan PostgreSQL 'infinity' into Go time.Time).
    update auth.users
    set
      banned_until = '2999-12-31T23:59:59Z'::timestamptz,
      updated_at = now()
    where id = p_target_user_id;

    -- Revoke active auth sessions immediately.
    delete from auth.sessions where user_id = p_target_user_id;

    insert into public.admin_action_logs (
      admin_id,
      action_type,
      target_user_id,
      target_application_id,
      reason,
      summary
    )
    values (
      p_admin_id,
      'user_deactivated',
      p_target_user_id,
      null,
      v_reason,
      'Akun dinonaktifkan Admin'
    );
  else
    if v_currently_active then
      raise exception 'KC_USER_ALREADY_ACTIVE'
        using errcode = 'P0001', detail = 'KC_USER_ALREADY_ACTIVE';
    end if;

    update auth.users
    set
      banned_until = null,
      updated_at = now()
    where id = p_target_user_id;

    insert into public.admin_action_logs (
      admin_id,
      action_type,
      target_user_id,
      target_application_id,
      reason,
      summary
    )
    values (
      p_admin_id,
      'user_reactivated',
      p_target_user_id,
      null,
      nullif(v_reason, ''),
      'Akun diaktifkan kembali Admin'
    );
  end if;

  return public.kc_admin_get_user(p_admin_id, p_target_user_id);
end;
$$;

-- =============================================================================
-- 6. Read-Only Stall Monitoring & Audit Log Queries (ADMIN-004, UI-ADMIN-004)
-- =============================================================================
create function public.kc_admin_list_stalls(
  p_admin_id uuid,
  p_query text default null,
  p_limit integer default 30,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_query text := nullif(btrim(coalesce(p_query, '')), '');
  v_limit integer := greatest(1, least(coalesce(p_limit, 30), 100));
  v_offset integer := greatest(0, coalesce(p_offset, 0));
  v_items jsonb;
begin
  perform public.kc_admin_require_active(p_admin_id);

  if v_query is not null and char_length(v_query) > 120 then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  select coalesce(jsonb_agg(row_json order by updated_at desc, id desc), '[]'::jsonb)
  into v_items
  from (
    select
      s.id,
      s.updated_at,
      jsonb_build_object(
        'id', s.id,
        'name', s.name,
        'campus', s.campus,
        'block', s.block,
        'wait_minutes', s.wait_minutes,
        'is_listed', s.is_listed,
        'is_open', s.is_open,
        'has_photo', (s.photo_path is not null),
        'owner_id', s.owner_id,
        'owner_name', public.kc_admin_user_display_name(u.email, u.raw_user_meta_data),
        'owner_email', coalesce(u.email, ''),
        'owner_is_active', (u.banned_until is null or u.banned_until <= now()),
        'updated_at', s.updated_at
      ) as row_json
    from public.catalog_stalls s
    join auth.users u on u.id = s.owner_id
    where v_query is null
       or strpos(lower(s.name), lower(v_query)) > 0
       or strpos(lower(s.campus), lower(v_query)) > 0
       or strpos(lower(s.block), lower(v_query)) > 0
       or strpos(
            lower(public.kc_admin_user_display_name(u.email, u.raw_user_meta_data)),
            lower(v_query)
          ) > 0
    order by s.updated_at desc, s.id desc
    limit v_limit offset v_offset
  ) rows;

  return jsonb_build_object(
    'items', v_items,
    'limit', v_limit,
    'offset', v_offset
  );
end;
$$;

create function public.kc_admin_get_stall(
  p_admin_id uuid,
  p_stall_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_stall public.catalog_stalls%rowtype;
  v_owner auth.users%rowtype;
  v_schedules jsonb;
begin
  perform public.kc_admin_require_active(p_admin_id);

  select s.*
  into v_stall
  from public.catalog_stalls s
  where s.id = p_stall_id;

  if not found then
    raise exception 'KC_STALL_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_STALL_NOT_FOUND';
  end if;

  select u.*
  into v_owner
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
      order by sch.day_of_week asc
    ),
    '[]'::jsonb
  )
  into v_schedules
  from public.owner_stall_schedules sch
  where sch.stall_id = v_stall.id;

  return jsonb_build_object(
    'id', v_stall.id,
    'name', v_stall.name,
    'campus', v_stall.campus,
    'block', v_stall.block,
    'description', v_stall.description,
    'wait_minutes', v_stall.wait_minutes,
    'is_listed', v_stall.is_listed,
    'is_open', v_stall.is_open,
    'has_photo', (v_stall.photo_path is not null),
    'owner_id', v_stall.owner_id,
    'owner_name', public.kc_admin_user_display_name(
      v_owner.email,
      v_owner.raw_user_meta_data
    ),
    'owner_email', coalesce(v_owner.email, ''),
    'owner_is_active', (
      v_owner.id is not null and
      (v_owner.banned_until is null or v_owner.banned_until <= now())
    ),
    'schedules', v_schedules,
    'updated_at', v_stall.updated_at
  );
end;
$$;

create function public.kc_admin_get_stall_photo_path(
  p_admin_id uuid,
  p_stall_id uuid
)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_photo_path text;
begin
  perform public.kc_admin_require_active(p_admin_id);

  select s.photo_path
  into v_photo_path
  from public.catalog_stalls s
  where s.id = p_stall_id;

  if not found then
    raise exception 'KC_STALL_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_STALL_NOT_FOUND';
  end if;

  return v_photo_path;
end;
$$;

create function public.kc_admin_list_action_logs(
  p_admin_id uuid,
  p_target_user_id uuid default null,
  p_limit integer default 30,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_limit integer := greatest(1, least(coalesce(p_limit, 30), 100));
  v_offset integer := greatest(0, coalesce(p_offset, 0));
  v_items jsonb;
begin
  perform public.kc_admin_require_active(p_admin_id);

  select coalesce(jsonb_agg(row_json order by created_at desc, id desc), '[]'::jsonb)
  into v_items
  from (
    select
      l.id,
      l.created_at,
      jsonb_build_object(
        'id', l.id,
        'admin_id', l.admin_id,
        'admin_name', public.kc_admin_user_display_name(a.email, a.raw_user_meta_data),
        'action_type', l.action_type,
        'target_user_id', l.target_user_id,
        'target_user_name', public.kc_admin_user_display_name(t.email, t.raw_user_meta_data),
        'target_application_id', l.target_application_id,
        'reason', l.reason,
        'summary', l.summary,
        'created_at', l.created_at
      ) as row_json
    from public.admin_action_logs l
    join auth.users a on a.id = l.admin_id
    join auth.users t on t.id = l.target_user_id
    where p_target_user_id is null or l.target_user_id = p_target_user_id
    order by l.created_at desc, l.id desc
    limit v_limit offset v_offset
  ) rows;

  return jsonb_build_object(
    'items', v_items,
    'limit', v_limit,
    'offset', v_offset
  );
end;
$$;

-- =============================================================================
-- 7. Least-Privilege Function Grants
-- =============================================================================
revoke all on function
  public.kc_guard_admin_action_logs_immutable(),
  public.kc_admin_require_active(uuid),
  public.kc_admin_user_display_name(text, jsonb),
  public.kc_admin_user_role(jsonb),
  public.kc_admin_application_json(public.owner_applications),
  public.kc_admin_dashboard(uuid),
  public.kc_admin_list_applications(uuid, text, integer, integer),
  public.kc_admin_get_application(uuid, uuid),
  public.kc_admin_review_application(uuid, uuid, text, text),
  public.kc_admin_list_users(uuid, text, text, text, integer, integer),
  public.kc_admin_get_user(uuid, uuid),
  public.kc_admin_set_user_active_status(uuid, uuid, boolean, text),
  public.kc_admin_list_stalls(uuid, text, integer, integer),
  public.kc_admin_get_stall(uuid, uuid),
  public.kc_admin_get_stall_photo_path(uuid, uuid),
  public.kc_admin_list_action_logs(uuid, uuid, integer, integer)
from public, anon, authenticated;

grant execute on function
  public.kc_admin_dashboard(uuid),
  public.kc_admin_list_applications(uuid, text, integer, integer),
  public.kc_admin_get_application(uuid, uuid),
  public.kc_admin_review_application(uuid, uuid, text, text),
  public.kc_admin_list_users(uuid, text, text, text, integer, integer),
  public.kc_admin_get_user(uuid, uuid),
  public.kc_admin_set_user_active_status(uuid, uuid, boolean, text),
  public.kc_admin_list_stalls(uuid, text, integer, integer),
  public.kc_admin_get_stall(uuid, uuid),
  public.kc_admin_get_stall_photo_path(uuid, uuid),
  public.kc_admin_list_action_logs(uuid, uuid, integer, integer)
to service_role;

commit;
