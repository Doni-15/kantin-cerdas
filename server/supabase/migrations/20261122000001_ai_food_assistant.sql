-- AI Food Assistant module forward-only schema:
-- atomic Asia/Jakarta per-Customer daily quota (max 10) + project safety cap,
-- call attempt tracking (dispatched/uncertain still billed per AI-TECH-001),
-- and authoritative real-catalog recommendation/verification RPCs.
-- Zero API keys stored in DB; zero duplication of catalog or order tables.
begin;

-- =============================================================================
-- 1. Quota & Attempt Tracking Tables (service_role only)
-- =============================================================================
create table public.ai_daily_usage (
  customer_id uuid not null references auth.users(id) on delete cascade,
  jakarta_date date not null,
  used_count integer not null default 0 check (used_count between 0 and 10),
  updated_at timestamptz not null default now(),
  primary key (customer_id, jakarta_date)
);

create table public.ai_project_daily_usage (
  jakarta_date date primary key,
  used_count integer not null default 0 check (used_count >= 0),
  updated_at timestamptz not null default now()
);

create table public.ai_call_attempts (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users(id) on delete cascade,
  jakarta_date date not null,
  request_kind text not null check (request_kind in ('catalog_chat', 'general_culinary')),
  status text not null check (
    status in (
      'reserved',
      'dispatched',
      'succeeded',
      'uncertain',
      'failed_before_dispatch',
      'provider_error',
      'invalid_output'
    )
  ),
  provider_model text null check (
    provider_model is null or char_length(btrim(provider_model)) between 1 and 80
  ),
  consumed_quota boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index ai_call_attempts_customer_date
  on public.ai_call_attempts (customer_id, jakarta_date, created_at desc);

alter table public.ai_daily_usage enable row level security;
alter table public.ai_project_daily_usage enable row level security;
alter table public.ai_call_attempts enable row level security;

revoke all on public.ai_daily_usage, public.ai_project_daily_usage, public.ai_call_attempts
  from public, anon, authenticated;
grant select, insert, update, delete on public.ai_daily_usage, public.ai_project_daily_usage, public.ai_call_attempts
  to service_role;

-- =============================================================================
-- 2. Helpers: Jakarta Date & Customer/Owner Active Validation
-- =============================================================================
create function public.kc_ai_jakarta_today(p_now timestamptz default null)
returns date
language sql
stable
security invoker
set search_path = ''
as $$
  select (coalesce(p_now, now()) at time zone 'Asia/Jakarta')::date;
$$;

create function public.kc_ai_require_customer(p_customer_id uuid)
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
  select
    case coalesce(u.raw_app_meta_data->>'kantin_role', '')
      when 'owner' then 'owner'
      when 'admin' then 'admin'
      else 'customer'
    end,
    u.banned_until
  into v_role, v_banned
  from auth.users u
  where u.id = p_customer_id;

  if not found then
    raise exception 'KC_AI_CUSTOMER_REQUIRED'
      using errcode = 'P0001', detail = 'KC_AI_CUSTOMER_REQUIRED';
  end if;

  if v_banned is not null and v_banned > now() then
    raise exception 'KC_CUSTOMER_INACTIVE'
      using errcode = 'P0001', detail = 'KC_CUSTOMER_INACTIVE';
  end if;

  if v_role not in ('customer', 'owner') then
    raise exception 'KC_AI_CUSTOMER_REQUIRED'
      using errcode = 'P0001', detail = 'KC_AI_CUSTOMER_REQUIRED';
  end if;
end;
$$;

-- =============================================================================
-- 3. Quota Read, Atomic Reservation, and Attempt Finalization (AI-006B, AI-TECH-001)
-- =============================================================================
create function public.kc_ai_get_quota_status(
  p_customer_id uuid,
  p_daily_limit integer default 10,
  p_project_daily_cap integer default 0,
  p_now timestamptz default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_date date := public.kc_ai_jakarta_today(p_now);
  v_limit integer := least(greatest(coalesce(p_daily_limit, 10), 1), 10);
  v_user_used integer := 0;
  v_proj_used integer := 0;
  v_proj_cap integer := greatest(coalesce(p_project_daily_cap, 0), 0);
begin
  perform public.kc_ai_require_customer(p_customer_id);

  select coalesce(d.used_count, 0)
  into v_user_used
  from public.ai_daily_usage d
  where d.customer_id = p_customer_id
    and d.jakarta_date = v_date;

  select coalesce(p.used_count, 0)
  into v_proj_used
  from public.ai_project_daily_usage p
  where p.jakarta_date = v_date;

  return jsonb_build_object(
    'jakarta_date', to_char(v_date, 'YYYY-MM-DD'),
    'daily_limit', v_limit,
    'used_today', coalesce(v_user_used, 0),
    'remaining_today', greatest(v_limit - coalesce(v_user_used, 0), 0),
    'project_cap_configured', v_proj_cap > 0,
    'project_quota_known', v_proj_cap > 0,
    'project_daily_cap', case when v_proj_cap > 0 then v_proj_cap else null end,
    'project_remaining_today', case when v_proj_cap > 0 then greatest(v_proj_cap - coalesce(v_proj_used, 0), 0) else null end
  );
end;
$$;

create function public.kc_ai_reserve_call(
  p_customer_id uuid,
  p_request_kind text,
  p_provider_model text default null,
  p_daily_limit integer default 10,
  p_project_daily_cap integer default 0,
  p_now timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_date date := public.kc_ai_jakarta_today(p_now);
  v_limit integer := least(greatest(coalesce(p_daily_limit, 10), 1), 10);
  v_proj_cap integer := coalesce(p_project_daily_cap, 0);
  v_proj_used integer;
  v_user_used integer;
  v_attempt_id uuid;
  v_model text := nullif(btrim(coalesce(p_provider_model, '')), '');
begin
  perform public.kc_ai_require_customer(p_customer_id);

  if p_request_kind not in ('catalog_chat', 'general_culinary') then
    raise exception 'KC_AI_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_AI_INVALID_INPUT';
  end if;

  if v_proj_cap <= 0 then
    return jsonb_build_object(
      'reserved', false,
      'reason', 'project_cap_unverified',
      'attempt_id', null,
      'quota', public.kc_ai_get_quota_status(p_customer_id, v_limit, 0, p_now)
    );
  end if;

  -- Consistent lock ordering: project usage row -> user usage row.
  insert into public.ai_project_daily_usage (jakarta_date, used_count)
  values (v_date, 0)
  on conflict (jakarta_date) do nothing;

  select p.used_count
  into v_proj_used
  from public.ai_project_daily_usage p
  where p.jakarta_date = v_date
  for update;

  insert into public.ai_daily_usage (customer_id, jakarta_date, used_count)
  values (p_customer_id, v_date, 0)
  on conflict (customer_id, jakarta_date) do nothing;

  select u.used_count
  into v_user_used
  from public.ai_daily_usage u
  where u.customer_id = p_customer_id
    and u.jakarta_date = v_date
  for update;

  if v_proj_used >= v_proj_cap then
    return jsonb_build_object(
      'reserved', false,
      'reason', 'project_quota_exhausted',
      'attempt_id', null,
      'quota', jsonb_build_object(
        'jakarta_date', to_char(v_date, 'YYYY-MM-DD'),
        'daily_limit', v_limit,
        'used_today', v_user_used,
        'remaining_today', greatest(v_limit - v_user_used, 0),
        'project_cap_configured', true,
        'project_quota_known', true,
        'project_daily_cap', v_proj_cap,
        'project_remaining_today', 0
      )
    );
  end if;

  if v_user_used >= v_limit then
    return jsonb_build_object(
      'reserved', false,
      'reason', 'user_quota_exhausted',
      'attempt_id', null,
      'quota', jsonb_build_object(
        'jakarta_date', to_char(v_date, 'YYYY-MM-DD'),
        'daily_limit', v_limit,
        'used_today', v_user_used,
        'remaining_today', 0,
        'project_cap_configured', true,
        'project_quota_known', true,
        'project_daily_cap', v_proj_cap,
        'project_remaining_today', greatest(v_proj_cap - v_proj_used, 0)
      )
    );
  end if;

  update public.ai_project_daily_usage
  set used_count = used_count + 1,
      updated_at = now()
  where jakarta_date = v_date
  returning used_count into v_proj_used;

  update public.ai_daily_usage
  set used_count = used_count + 1,
      updated_at = now()
  where customer_id = p_customer_id
    and jakarta_date = v_date
  returning used_count into v_user_used;

  insert into public.ai_call_attempts (
    customer_id,
    jakarta_date,
    request_kind,
    status,
    provider_model,
    consumed_quota
  )
  values (
    p_customer_id,
    v_date,
    p_request_kind,
    'reserved',
    v_model,
    true
  )
  returning id into v_attempt_id;

  return jsonb_build_object(
    'reserved', true,
    'reason', 'reserved',
    'attempt_id', v_attempt_id,
    'quota', jsonb_build_object(
      'jakarta_date', to_char(v_date, 'YYYY-MM-DD'),
      'daily_limit', v_limit,
      'used_today', v_user_used,
      'remaining_today', greatest(v_limit - v_user_used, 0),
      'project_cap_configured', true,
      'project_quota_known', true,
      'project_daily_cap', v_proj_cap,
      'project_remaining_today', greatest(v_proj_cap - v_proj_used, 0)
    )
  );
end;
$$;

create function public.kc_ai_finalize_attempt(
  p_customer_id uuid,
  p_attempt_id uuid,
  p_status text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_attempt public.ai_call_attempts%rowtype;
begin
  perform public.kc_ai_require_customer(p_customer_id);

  if p_status not in (
    'dispatched',
    'succeeded',
    'uncertain',
    'failed_before_dispatch',
    'provider_error',
    'invalid_output'
  ) then
    raise exception 'KC_AI_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_AI_INVALID_INPUT';
  end if;

  select *
  into v_attempt
  from public.ai_call_attempts a
  where a.id = p_attempt_id
    and a.customer_id = p_customer_id
  for update;

  if not found then
    raise exception 'KC_AI_ATTEMPT_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_AI_ATTEMPT_NOT_FOUND';
  end if;

  if v_attempt.status = p_status then
    return jsonb_build_object(
      'attempt_id', v_attempt.id,
      'status', v_attempt.status,
      'consumed_quota', v_attempt.consumed_quota
    );
  end if;

  -- Once dispatched, quota cannot be refunded (AI-TECH-001).
  if v_attempt.status = 'dispatched' and p_status = 'failed_before_dispatch' then
    raise exception 'KC_AI_INVALID_TRANSITION'
      using errcode = 'P0001', detail = 'KC_AI_INVALID_TRANSITION';
  end if;

  if v_attempt.status not in ('reserved', 'dispatched') then
    raise exception 'KC_AI_INVALID_TRANSITION'
      using errcode = 'P0001', detail = 'KC_AI_INVALID_TRANSITION';
  end if;

  if v_attempt.status = 'reserved' and p_status = 'failed_before_dispatch' and v_attempt.consumed_quota then
    perform 1
    from public.ai_project_daily_usage p
    where p.jakarta_date = v_attempt.jakarta_date
    for update;

    perform 1
    from public.ai_daily_usage u
    where u.customer_id = v_attempt.customer_id
      and u.jakarta_date = v_attempt.jakarta_date
    for update;

    update public.ai_project_daily_usage
    set used_count = greatest(used_count - 1, 0),
        updated_at = now()
    where jakarta_date = v_attempt.jakarta_date;

    update public.ai_daily_usage
    set used_count = greatest(used_count - 1, 0),
        updated_at = now()
    where customer_id = v_attempt.customer_id
      and jakarta_date = v_attempt.jakarta_date;

    update public.ai_call_attempts
    set status = p_status,
        consumed_quota = false,
        updated_at = now()
    where id = v_attempt.id
    returning * into v_attempt;
  else
    update public.ai_call_attempts
    set status = p_status,
        updated_at = now()
    where id = v_attempt.id
    returning * into v_attempt;
  end if;

  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'status', v_attempt.status,
    'consumed_quota', v_attempt.consumed_quota
  );
end;
$$;

-- =============================================================================
-- 4. Authoritative Real-Catalog Grounding & Verification RPCs (AI-002, AI-004)
-- =============================================================================
create function public.kc_ai_search_catalog(
  p_query text default '',
  p_max_price integer default null,
  p_include_unavailable boolean default false,
  p_limit integer default 24
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with params as (
    select
      btrim(lower(coalesce(p_query, ''))) as q,
      coalesce(
        array(
          select tok
          from unnest(regexp_split_to_array(btrim(lower(coalesce(p_query, ''))), '\s+')) as tok
          where char_length(tok) >= 2
        ),
        array[]::text[]
      ) as tokens,
      p_max_price as max_price,
      coalesce(p_include_unavailable, false) as include_unavailable,
      least(greatest(coalesce(p_limit, 24), 1), 50) as lim
  ),
  candidates as (
    select
      m.id,
      m.name,
      m.description,
      m.category,
      m.price,
      m.is_available,
      m.is_archived,
      (m.photo_path is not null) as has_photo,
      s.id as stall_id,
      s.name as stall_name,
      s.block as stall_block,
      s.wait_minutes,
      s.is_open as stall_is_open,
      (u.banned_until is null or u.banned_until <= now()) as owner_is_active,
      (
        s.is_listed
        and s.is_open
        and (u.banned_until is null or u.banned_until <= now())
        and not m.is_archived
        and m.is_available
      ) as is_orderable,
      case
        when not (u.banned_until is null or u.banned_until <= now()) then 'owner_inactive'
        when not s.is_open then 'stall_closed'
        when not m.is_available then 'menu_unavailable'
        else null
      end as unavailable_reason,
      (
        case
          when params.q = '' then 1
          when strpos(lower(m.name), params.q) > 0 then 120
          when strpos(lower(m.category), params.q) > 0 then 80
          when strpos(lower(m.description), params.q) > 0 then 60
          when strpos(lower(s.name), params.q) > 0 then 50
          else 0
        end
        + coalesce(
          (
            select sum(
              case
                when strpos(lower(m.name), tok) > 0 then 30
                when strpos(lower(m.category), tok) > 0 then 20
                when strpos(lower(m.description), tok) > 0 then 15
                when strpos(lower(s.name), tok) > 0 then 10
                else 0
              end
            )::integer
            from unnest(params.tokens) as tok
          ),
          0
        )
      ) as match_score
    from public.catalog_menu_items m
    join public.catalog_stalls s on s.id = m.stall_id
    join auth.users u on u.id = s.owner_id
    cross join params
    where s.is_listed
      and not m.is_archived
      and (params.max_price is null or m.price <= params.max_price)
      and (
        params.include_unavailable
        or (
          s.is_open
          and m.is_available
          and (u.banned_until is null or u.banned_until <= now())
        )
      )
  ),
  filtered as (
    select c.*
    from candidates c
    cross join params
    where params.q = ''
       or cardinality(params.tokens) = 0
       or c.match_score > 0
    order by
      c.is_orderable desc,
      c.match_score desc,
      c.price asc,
      c.id asc
    limit (select lim from params)
  )
  select jsonb_build_object(
    'items',
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', f.id,
            'name', f.name,
            'description', f.description,
            'category', f.category,
            'price', f.price,
            'has_photo', f.has_photo,
            'is_available', f.is_available,
            'is_orderable', f.is_orderable,
            'unavailable_reason', f.unavailable_reason,
            'stall', jsonb_build_object(
              'id', f.stall_id,
              'name', f.stall_name,
              'block', f.stall_block,
              'wait_minutes', f.wait_minutes,
              'is_open', f.stall_is_open,
              'owner_is_active', f.owner_is_active
            )
          )
          order by f.is_orderable desc, f.match_score desc, f.price asc, f.id asc
        )
        from filtered f
      ),
      '[]'::jsonb
    )
  );
$$;

create function public.kc_ai_verify_menu_candidates(
  p_menu_ids uuid[],
  p_max_price integer default null,
  p_include_unavailable boolean default false
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with ordered_rows as (
    select
      m.id,
      m.name,
      m.description,
      m.category,
      m.price,
      m.is_available,
      (m.photo_path is not null) as has_photo,
      s.id as stall_id,
      s.name as stall_name,
      s.block as stall_block,
      s.wait_minutes,
      s.is_open as stall_is_open,
      (u.banned_until is null or u.banned_until <= now()) as owner_is_active,
      (
        s.is_listed
        and s.is_open
        and (u.banned_until is null or u.banned_until <= now())
        and not m.is_archived
        and m.is_available
      ) as is_orderable,
      case
        when not (u.banned_until is null or u.banned_until <= now()) then 'owner_inactive'
        when not s.is_open then 'stall_closed'
        when not m.is_available then 'menu_unavailable'
        else null
      end as unavailable_reason,
      coalesce(array_position(p_menu_ids, m.id), 999999) as rank_pos
    from public.catalog_menu_items m
    join public.catalog_stalls s on s.id = m.stall_id
    join auth.users u on u.id = s.owner_id
    where p_menu_ids is not null
      and cardinality(p_menu_ids) > 0
      and m.id = any(p_menu_ids)
      and s.is_listed
      and not m.is_archived
      and (p_max_price is null or m.price <= p_max_price)
      and (
        coalesce(p_include_unavailable, false)
        or (
          s.is_open
          and m.is_available
          and (u.banned_until is null or u.banned_until <= now())
        )
      )
  )
  select jsonb_build_object(
    'items',
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', r.id,
            'name', r.name,
            'description', r.description,
            'category', r.category,
            'price', r.price,
            'has_photo', r.has_photo,
            'is_available', r.is_available,
            'is_orderable', r.is_orderable,
            'unavailable_reason', r.unavailable_reason,
            'stall', jsonb_build_object(
              'id', r.stall_id,
              'name', r.stall_name,
              'block', r.stall_block,
              'wait_minutes', r.wait_minutes,
              'is_open', r.stall_is_open,
              'owner_is_active', r.owner_is_active
            )
          )
          order by r.is_orderable desc, r.rank_pos asc
        )
        from ordered_rows r
      ),
      '[]'::jsonb
    )
  );
$$;

-- =============================================================================
-- 5. Strict service_role-only function privileges
-- =============================================================================
revoke all on function
  public.kc_ai_jakarta_today(timestamptz),
  public.kc_ai_require_customer(uuid),
  public.kc_ai_get_quota_status(uuid, integer, integer, timestamptz),
  public.kc_ai_reserve_call(uuid, text, text, integer, integer, timestamptz),
  public.kc_ai_finalize_attempt(uuid, uuid, text),
  public.kc_ai_search_catalog(text, integer, boolean, integer),
  public.kc_ai_verify_menu_candidates(uuid[], integer, boolean)
from public, anon, authenticated;

grant execute on function
  public.kc_ai_jakarta_today(timestamptz),
  public.kc_ai_require_customer(uuid),
  public.kc_ai_get_quota_status(uuid, integer, integer, timestamptz),
  public.kc_ai_reserve_call(uuid, text, text, integer, integer, timestamptz),
  public.kc_ai_finalize_attempt(uuid, uuid, text),
  public.kc_ai_search_catalog(text, integer, boolean, integer),
  public.kc_ai_verify_menu_candidates(uuid[], integer, boolean)
to service_role;

commit;
