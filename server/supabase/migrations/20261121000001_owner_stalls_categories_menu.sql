-- Owner module schema: storage bucket, stall profile & ownership constraints,
-- informative weekly schedules, menu categories, and menu archive/photo support.
-- Forward-only migration; does not modify applied historical migrations.
begin;

-- =============================================================================
-- 1. Private media storage bucket for stall & menu photos
-- =============================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('kantin-media', 'kantin-media', false, 2097152, array['image/jpeg'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy kantin_media_require_backend
on storage.objects
as restrictive
for all
to anon, authenticated
using (bucket_id <> 'kantin-media')
with check (bucket_id <> 'kantin-media');

-- =============================================================================
-- 2. Extend public.catalog_stalls for OWNER-001, OWNER-002, OWNER-002B
-- =============================================================================
alter table public.catalog_stalls
  add column campus text not null default '' check (char_length(btrim(campus)) <= 120),
  add column photo_path text null check (
    photo_path is null or char_length(btrim(photo_path)) between 1 and 255
  ),
  add column created_at timestamptz not null default now(),
  add column updated_at timestamptz not null default now();

-- OWNER-002: maximum one stall per Owner account.
create unique index catalog_stalls_one_per_owner
  on public.catalog_stalls (owner_id);

-- OWNER-002B: prevent unpublishing a published stall or reassigning ownership.
create function public.kc_guard_catalog_stall_update()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.owner_id is distinct from old.owner_id then
    raise exception 'KC_STALL_OWNER_IMMUTABLE'
      using errcode = 'P0001', detail = 'KC_STALL_OWNER_IMMUTABLE';
  end if;

  if old.is_listed and not new.is_listed then
    raise exception 'KC_UNPUBLISH_NOT_ALLOWED'
      using errcode = 'P0001', detail = 'KC_UNPUBLISH_NOT_ALLOWED';
  end if;

  new.updated_at := now();
  return new;
end;
$$;

create trigger trg_guard_catalog_stall_update
  before update on public.catalog_stalls
  for each row
  execute function public.kc_guard_catalog_stall_update();

-- =============================================================================
-- 3. Informative weekly operating hours (OWNER-003)
-- =============================================================================
create table public.owner_stall_schedules (
  stall_id uuid not null references public.catalog_stalls(id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 1 and 7),
  is_open_day boolean not null default false,
  open_time time null,
  close_time time null,
  primary key (stall_id, day_of_week),
  constraint owner_stall_schedules_time_valid check (
    (not is_open_day and open_time is null and close_time is null)
    or (
      is_open_day
      and open_time is not null
      and close_time is not null
      and close_time > open_time
    )
  )
);

alter table public.owner_stall_schedules enable row level security;
revoke all on public.owner_stall_schedules from public, anon, authenticated;
grant select, insert, update, delete on public.owner_stall_schedules to service_role;

-- =============================================================================
-- 4. Stall menu categories (OWNER-004, OWNER-004A)
-- =============================================================================
create table public.owner_menu_categories (
  id uuid primary key default gen_random_uuid(),
  stall_id uuid not null references public.catalog_stalls(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 60),
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create unique index owner_menu_categories_unique_name
  on public.owner_menu_categories (stall_id, lower(btrim(name)));

create index owner_menu_categories_stall_sort
  on public.owner_menu_categories (stall_id, sort_order, name);

alter table public.owner_menu_categories enable row level security;
revoke all on public.owner_menu_categories from public, anon, authenticated;
grant select, insert, update, delete on public.owner_menu_categories to service_role;

-- =============================================================================
-- 5. Extend public.catalog_menu_items for OWNER-004A, OWNER-005
-- =============================================================================
alter table public.catalog_menu_items
  add column category_id uuid null
    references public.owner_menu_categories(id) on delete restrict,
  add column is_archived boolean not null default false,
  add column photo_path text null check (
    photo_path is null or char_length(btrim(photo_path)) between 1 and 255
  ),
  add column updated_at timestamptz not null default now();

update public.catalog_menu_items
set is_archived = not is_listed
where is_archived = is_listed;

alter table public.catalog_menu_items
  add constraint catalog_menu_items_listed_sync
    check (is_listed = not is_archived);

create index catalog_menu_items_category
  on public.catalog_menu_items (category_id);

-- =============================================================================
-- 6. Owner Stall, Schedule, Category, and Menu RPCs (service_role only)
-- =============================================================================
create function public.kc_owner_get_stall(p_owner_id uuid)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_stall public.catalog_stalls%rowtype;
  v_schedules jsonb;
  v_missing text[];
  v_available_count integer;
begin
  select *
  into v_stall
  from public.catalog_stalls s
  where s.owner_id = p_owner_id;

  if not found then
    return jsonb_build_object(
      'stall', null,
      'schedules', '[]'::jsonb,
      'publish_eligibility', jsonb_build_object(
        'can_publish', false,
        'missing_profile_fields', jsonb_build_array('name', 'campus', 'block'),
        'available_menu_count', 0
      )
    );
  end if;

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

  v_missing := array[]::text[];
  if char_length(btrim(v_stall.name)) = 0 then
    v_missing := array_append(v_missing, 'name');
  end if;
  if char_length(btrim(v_stall.campus)) = 0 then
    v_missing := array_append(v_missing, 'campus');
  end if;
  if char_length(btrim(v_stall.block)) = 0 then
    v_missing := array_append(v_missing, 'block');
  end if;

  select count(*)::integer
  into v_available_count
  from public.catalog_menu_items m
  where m.stall_id = v_stall.id
    and not m.is_archived
    and m.is_available;

  return jsonb_build_object(
    'stall', jsonb_build_object(
      'id', v_stall.id,
      'owner_id', v_stall.owner_id,
      'name', v_stall.name,
      'campus', v_stall.campus,
      'block', v_stall.block,
      'description', v_stall.description,
      'wait_minutes', v_stall.wait_minutes,
      'is_listed', v_stall.is_listed,
      'is_open', v_stall.is_open,
      'has_photo', v_stall.photo_path is not null,
      'created_at', v_stall.created_at,
      'updated_at', v_stall.updated_at
    ),
    'schedules', v_schedules,
    'publish_eligibility', jsonb_build_object(
      'can_publish',
      (not v_stall.is_listed)
        and coalesce(array_length(v_missing, 1), 0) = 0
        and v_available_count >= 1,
      'missing_profile_fields', to_jsonb(v_missing),
      'available_menu_count', v_available_count
    )
  );
end;
$$;

create function public.kc_owner_create_stall(
  p_owner_id uuid,
  p_name text,
  p_campus text,
  p_block text,
  p_description text default '',
  p_wait_minutes integer default 0
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_name text := btrim(coalesce(p_name, ''));
  v_campus text := btrim(coalesce(p_campus, ''));
  v_block text := btrim(coalesce(p_block, ''));
  v_description text := btrim(coalesce(p_description, ''));
  v_wait integer := coalesce(p_wait_minutes, 0);
  v_stall_id uuid;
  v_day integer;
begin
  if char_length(v_name) not between 1 and 120
     or char_length(v_campus) not between 1 and 120
     or char_length(v_block) not between 1 and 60
     or char_length(v_description) > 2000
     or v_wait not between 0 and 240 then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  begin
    insert into public.catalog_stalls (
      owner_id, name, campus, block, description, wait_minutes, is_listed, is_open
    )
    values (
      p_owner_id, v_name, v_campus, v_block, v_description, v_wait, false, false
    )
    returning id into v_stall_id;
  exception
    when unique_violation then
      raise exception 'KC_STALL_ALREADY_EXISTS'
        using errcode = 'P0001', detail = 'KC_STALL_ALREADY_EXISTS';
  end;

  insert into public.owner_menu_categories (stall_id, name, sort_order) values
    (v_stall_id, 'Makanan', 1),
    (v_stall_id, 'Minuman', 2),
    (v_stall_id, 'Camilan', 3);

  for v_day in 1..7 loop
    insert into public.owner_stall_schedules (stall_id, day_of_week, is_open_day)
    values (v_stall_id, v_day, false);
  end loop;

  return public.kc_owner_get_stall(p_owner_id);
end;
$$;

create function public.kc_owner_update_stall(
  p_owner_id uuid,
  p_name text,
  p_campus text,
  p_block text,
  p_description text default '',
  p_wait_minutes integer default 0
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_name text := btrim(coalesce(p_name, ''));
  v_campus text := btrim(coalesce(p_campus, ''));
  v_block text := btrim(coalesce(p_block, ''));
  v_description text := btrim(coalesce(p_description, ''));
  v_wait integer := coalesce(p_wait_minutes, 0);
  v_stall_id uuid;
begin
  if char_length(v_name) not between 1 and 120
     or char_length(v_campus) not between 1 and 120
     or char_length(v_block) not between 1 and 60
     or char_length(v_description) > 2000
     or v_wait not between 0 and 240 then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  select s.id
  into v_stall_id
  from public.catalog_stalls s
  where s.owner_id = p_owner_id
  for update;

  if not found then
    raise exception 'KC_STALL_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_STALL_NOT_FOUND';
  end if;

  update public.catalog_stalls
  set name = v_name,
      campus = v_campus,
      block = v_block,
      description = v_description,
      wait_minutes = v_wait
  where id = v_stall_id;

  return public.kc_owner_get_stall(p_owner_id);
end;
$$;

create function public.kc_owner_set_stall_photo(
  p_owner_id uuid,
  p_photo_path text
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_stall_id uuid;
begin
  select s.id
  into v_stall_id
  from public.catalog_stalls s
  where s.owner_id = p_owner_id
  for update;

  if not found then
    raise exception 'KC_STALL_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_STALL_NOT_FOUND';
  end if;

  update public.catalog_stalls
  set photo_path = nullif(btrim(coalesce(p_photo_path, '')), '')
  where id = v_stall_id;

  return public.kc_owner_get_stall(p_owner_id);
end;
$$;

create function public.kc_owner_set_stall_schedule(
  p_owner_id uuid,
  p_schedules jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_stall_id uuid;
  v_entry jsonb;
  v_day integer;
  v_is_open boolean;
  v_open time;
  v_close time;
  v_seen integer[] := array[]::integer[];
begin
  if p_schedules is null
     or jsonb_typeof(p_schedules) <> 'array'
     or jsonb_array_length(p_schedules) <> 7 then
    raise exception 'KC_INVALID_SCHEDULE'
      using errcode = 'P0001', detail = 'KC_INVALID_SCHEDULE';
  end if;

  select s.id
  into v_stall_id
  from public.catalog_stalls s
  where s.owner_id = p_owner_id
  for update;

  if not found then
    raise exception 'KC_STALL_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_STALL_NOT_FOUND';
  end if;

  for v_entry in select value from jsonb_array_elements(p_schedules) loop
    if jsonb_typeof(v_entry) <> 'object' then
      raise exception 'KC_INVALID_SCHEDULE'
        using errcode = 'P0001', detail = 'KC_INVALID_SCHEDULE';
    end if;

    v_day := (v_entry->>'day_of_week')::integer;
    v_is_open := (v_entry->>'is_open_day')::boolean;

    if v_day is null or v_day not between 1 and 7 or v_day = any(v_seen) or v_is_open is null then
      raise exception 'KC_INVALID_SCHEDULE'
        using errcode = 'P0001', detail = 'KC_INVALID_SCHEDULE';
    end if;

    v_seen := array_append(v_seen, v_day);

    if v_is_open then
      v_open := (v_entry->>'open_time')::time;
      v_close := (v_entry->>'close_time')::time;
      if v_open is null or v_close is null or v_close <= v_open then
        raise exception 'KC_INVALID_SCHEDULE'
          using errcode = 'P0001', detail = 'KC_INVALID_SCHEDULE';
      end if;
    else
      v_open := null;
      v_close := null;
    end if;

    insert into public.owner_stall_schedules (
      stall_id, day_of_week, is_open_day, open_time, close_time
    )
    values (v_stall_id, v_day, v_is_open, v_open, v_close)
    on conflict (stall_id, day_of_week) do update
    set is_open_day = excluded.is_open_day,
        open_time = excluded.open_time,
        close_time = excluded.close_time;
  end loop;

  return public.kc_owner_get_stall(p_owner_id);
end;
$$;

create function public.kc_owner_publish_stall(p_owner_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_stall public.catalog_stalls%rowtype;
  v_has_available_menu boolean;
begin
  select *
  into v_stall
  from public.catalog_stalls s
  where s.owner_id = p_owner_id
  for update;

  if not found then
    raise exception 'KC_STALL_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_STALL_NOT_FOUND';
  end if;

  if v_stall.is_listed then
    raise exception 'KC_STALL_ALREADY_PUBLISHED'
      using errcode = 'P0001', detail = 'KC_STALL_ALREADY_PUBLISHED';
  end if;

  if char_length(btrim(v_stall.name)) = 0
     or char_length(btrim(v_stall.campus)) = 0
     or char_length(btrim(v_stall.block)) = 0 then
    raise exception 'KC_PUBLISH_PROFILE_INCOMPLETE'
      using errcode = 'P0001', detail = 'KC_PUBLISH_PROFILE_INCOMPLETE';
  end if;

  select exists (
    select 1
    from public.catalog_menu_items m
    where m.stall_id = v_stall.id
      and not m.is_archived
      and m.is_available
  )
  into v_has_available_menu;

  if not v_has_available_menu then
    raise exception 'KC_PUBLISH_MENU_REQUIRED'
      using errcode = 'P0001', detail = 'KC_PUBLISH_MENU_REQUIRED';
  end if;

  -- OWNER-002: first publish starts closed (Tutup).
  update public.catalog_stalls
  set is_listed = true,
      is_open = false
  where id = v_stall.id;

  return public.kc_owner_get_stall(p_owner_id);
end;
$$;

create function public.kc_owner_set_stall_open(
  p_owner_id uuid,
  p_is_open boolean
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_stall public.catalog_stalls%rowtype;
begin
  select *
  into v_stall
  from public.catalog_stalls s
  where s.owner_id = p_owner_id
  for update;

  if not found then
    raise exception 'KC_STALL_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_STALL_NOT_FOUND';
  end if;

  if not v_stall.is_listed then
    raise exception 'KC_STALL_NOT_PUBLISHED'
      using errcode = 'P0001', detail = 'KC_STALL_NOT_PUBLISHED';
  end if;

  update public.catalog_stalls
  set is_open = p_is_open
  where id = v_stall.id;

  return public.kc_owner_get_stall(p_owner_id);
end;
$$;

create function public.kc_owner_list_categories(p_owner_id uuid)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_stall_id uuid;
  v_categories jsonb;
begin
  select s.id
  into v_stall_id
  from public.catalog_stalls s
  where s.owner_id = p_owner_id;

  if not found then
    raise exception 'KC_STALL_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_STALL_NOT_FOUND';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', c.id,
        'stall_id', c.stall_id,
        'name', c.name,
        'sort_order', c.sort_order,
        'active_menu_count', coalesce(stats.active_count, 0),
        'archived_menu_count', coalesce(stats.archived_count, 0),
        'total_menu_count', coalesce(stats.total_count, 0),
        'can_delete', coalesce(stats.total_count, 0) = 0
      )
      order by c.sort_order, lower(c.name), c.id
    ),
    '[]'::jsonb
  )
  into v_categories
  from public.owner_menu_categories c
  left join lateral (
    select
      count(*) filter (where not m.is_archived)::integer as active_count,
      count(*) filter (where m.is_archived)::integer as archived_count,
      count(*)::integer as total_count
    from public.catalog_menu_items m
    where m.category_id = c.id
  ) stats on true
  where c.stall_id = v_stall_id;

  return v_categories;
end;
$$;

create function public.kc_owner_create_category(
  p_owner_id uuid,
  p_name text
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_stall_id uuid;
  v_name text := btrim(coalesce(p_name, ''));
  v_sort integer;
  v_cat public.owner_menu_categories%rowtype;
begin
  if char_length(v_name) not between 1 and 60 then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  select s.id
  into v_stall_id
  from public.catalog_stalls s
  where s.owner_id = p_owner_id
  for update;

  if not found then
    raise exception 'KC_STALL_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_STALL_NOT_FOUND';
  end if;

  select coalesce(max(c.sort_order), 0) + 1
  into v_sort
  from public.owner_menu_categories c
  where c.stall_id = v_stall_id;

  begin
    insert into public.owner_menu_categories (stall_id, name, sort_order)
    values (v_stall_id, v_name, v_sort)
    returning * into v_cat;
  exception
    when unique_violation then
      raise exception 'KC_CATEGORY_NAME_EXISTS'
        using errcode = 'P0001', detail = 'KC_CATEGORY_NAME_EXISTS';
  end;

  return jsonb_build_object(
    'id', v_cat.id,
    'stall_id', v_cat.stall_id,
    'name', v_cat.name,
    'sort_order', v_cat.sort_order,
    'active_menu_count', 0,
    'archived_menu_count', 0,
    'total_menu_count', 0,
    'can_delete', true
  );
end;
$$;

create function public.kc_owner_rename_category(
  p_owner_id uuid,
  p_category_id uuid,
  p_name text
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_stall_id uuid;
  v_name text := btrim(coalesce(p_name, ''));
  v_cat public.owner_menu_categories%rowtype;
  v_active integer;
  v_archived integer;
begin
  if char_length(v_name) not between 1 and 60 then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  select s.id
  into v_stall_id
  from public.catalog_stalls s
  where s.owner_id = p_owner_id
  for update;

  if not found then
    raise exception 'KC_STALL_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_STALL_NOT_FOUND';
  end if;

  select *
  into v_cat
  from public.owner_menu_categories c
  where c.id = p_category_id and c.stall_id = v_stall_id
  for update;

  if not found then
    raise exception 'KC_CATEGORY_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_CATEGORY_NOT_FOUND';
  end if;

  begin
    update public.owner_menu_categories
    set name = v_name
    where id = v_cat.id
    returning * into v_cat;
  exception
    when unique_violation then
      raise exception 'KC_CATEGORY_NAME_EXISTS'
        using errcode = 'P0001', detail = 'KC_CATEGORY_NAME_EXISTS';
  end;

  update public.catalog_menu_items
  set category = v_name,
      updated_at = now()
  where category_id = v_cat.id;

  select
    count(*) filter (where not m.is_archived)::integer,
    count(*) filter (where m.is_archived)::integer
  into v_active, v_archived
  from public.catalog_menu_items m
  where m.category_id = v_cat.id;

  return jsonb_build_object(
    'id', v_cat.id,
    'stall_id', v_cat.stall_id,
    'name', v_cat.name,
    'sort_order', v_cat.sort_order,
    'active_menu_count', v_active,
    'archived_menu_count', v_archived,
    'total_menu_count', v_active + v_archived,
    'can_delete', (v_active + v_archived) = 0
  );
end;
$$;

create function public.kc_owner_delete_category(
  p_owner_id uuid,
  p_category_id uuid
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_stall_id uuid;
  v_has_menus boolean;
begin
  select s.id
  into v_stall_id
  from public.catalog_stalls s
  where s.owner_id = p_owner_id
  for update;

  if not found then
    raise exception 'KC_STALL_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_STALL_NOT_FOUND';
  end if;

  perform 1
  from public.owner_menu_categories c
  where c.id = p_category_id and c.stall_id = v_stall_id
  for update;

  if not found then
    raise exception 'KC_CATEGORY_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_CATEGORY_NOT_FOUND';
  end if;

  -- OWNER-004A: reject deletion if any active OR archived menu references this category.
  select exists (
    select 1
    from public.catalog_menu_items m
    where m.category_id = p_category_id
  )
  into v_has_menus;

  if v_has_menus then
    raise exception 'KC_CATEGORY_NOT_EMPTY'
      using errcode = 'P0001', detail = 'KC_CATEGORY_NOT_EMPTY';
  end if;

  delete from public.owner_menu_categories
  where id = p_category_id;
end;
$$;

create function public.kc_owner_menu_row_json(p_menu public.catalog_menu_items)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'id', p_menu.id,
    'stall_id', p_menu.stall_id,
    'category_id', p_menu.category_id,
    'category_name', p_menu.category,
    'name', p_menu.name,
    'description', p_menu.description,
    'price', p_menu.price,
    'is_available', p_menu.is_available,
    'is_archived', p_menu.is_archived,
    'has_photo', p_menu.photo_path is not null,
    'updated_at', p_menu.updated_at
  );
$$;

create function public.kc_owner_list_menus(
  p_owner_id uuid,
  p_archived boolean default null,
  p_query text default ''
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
  v_items jsonb;
begin
  select s.id
  into v_stall_id
  from public.catalog_stalls s
  where s.owner_id = p_owner_id;

  if not found then
    raise exception 'KC_STALL_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_STALL_NOT_FOUND';
  end if;

  select coalesce(
    jsonb_agg(
      public.kc_owner_menu_row_json(m)
      order by lower(m.name), m.id
    ),
    '[]'::jsonb
  )
  into v_items
  from public.catalog_menu_items m
  where m.stall_id = v_stall_id
    and (p_archived is null or m.is_archived = p_archived)
    and (
      v_query = ''
      or strpos(lower(m.name), v_query) > 0
      or strpos(lower(m.category), v_query) > 0
    );

  return v_items;
end;
$$;

create function public.kc_owner_create_menu(
  p_owner_id uuid,
  p_name text,
  p_category_id uuid,
  p_price integer,
  p_is_available boolean,
  p_description text default ''
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_stall_id uuid;
  v_cat_name text;
  v_name text := btrim(coalesce(p_name, ''));
  v_description text := btrim(coalesce(p_description, ''));
  v_menu public.catalog_menu_items%rowtype;
begin
  if char_length(v_name) not between 1 and 120
     or char_length(v_description) > 2000
     or p_price is null
     or p_price not between 1 and 100000000
     or p_is_available is null then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  select s.id
  into v_stall_id
  from public.catalog_stalls s
  where s.owner_id = p_owner_id
  for update;

  if not found then
    raise exception 'KC_STALL_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_STALL_NOT_FOUND';
  end if;

  select c.name
  into v_cat_name
  from public.owner_menu_categories c
  where c.id = p_category_id and c.stall_id = v_stall_id;

  if not found then
    raise exception 'KC_CATEGORY_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_CATEGORY_NOT_FOUND';
  end if;

  insert into public.catalog_menu_items (
    stall_id, category_id, category, name, description, price, is_available, is_archived, is_listed
  )
  values (
    v_stall_id, p_category_id, v_cat_name, v_name, v_description, p_price, p_is_available, false, true
  )
  returning * into v_menu;

  return public.kc_owner_menu_row_json(v_menu);
end;
$$;

create function public.kc_owner_update_menu(
  p_owner_id uuid,
  p_menu_id uuid,
  p_name text,
  p_category_id uuid,
  p_price integer,
  p_is_available boolean,
  p_description text default ''
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_stall_id uuid;
  v_cat_name text;
  v_name text := btrim(coalesce(p_name, ''));
  v_description text := btrim(coalesce(p_description, ''));
  v_menu public.catalog_menu_items%rowtype;
begin
  if char_length(v_name) not between 1 and 120
     or char_length(v_description) > 2000
     or p_price is null
     or p_price not between 1 and 100000000
     or p_is_available is null then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  select s.id
  into v_stall_id
  from public.catalog_stalls s
  where s.owner_id = p_owner_id;

  if not found then
    raise exception 'KC_STALL_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_STALL_NOT_FOUND';
  end if;

  select *
  into v_menu
  from public.catalog_menu_items m
  where m.id = p_menu_id and m.stall_id = v_stall_id
  for update;

  if not found then
    raise exception 'KC_MENU_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_MENU_NOT_FOUND';
  end if;

  select c.name
  into v_cat_name
  from public.owner_menu_categories c
  where c.id = p_category_id and c.stall_id = v_stall_id;

  if not found then
    raise exception 'KC_CATEGORY_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_CATEGORY_NOT_FOUND';
  end if;

  update public.catalog_menu_items
  set name = v_name,
      category_id = p_category_id,
      category = v_cat_name,
      price = p_price,
      is_available = p_is_available,
      description = v_description,
      updated_at = now()
  where id = v_menu.id
  returning * into v_menu;

  return public.kc_owner_menu_row_json(v_menu);
end;
$$;

create function public.kc_owner_set_menu_availability(
  p_owner_id uuid,
  p_menu_id uuid,
  p_is_available boolean
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_menu public.catalog_menu_items%rowtype;
begin
  if p_is_available is null then
    raise exception 'KC_INVALID_INPUT'
      using errcode = 'P0001', detail = 'KC_INVALID_INPUT';
  end if;

  select m.*
  into v_menu
  from public.catalog_menu_items m
  join public.catalog_stalls s on s.id = m.stall_id
  where m.id = p_menu_id and s.owner_id = p_owner_id
  for update of m;

  if not found then
    raise exception 'KC_MENU_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_MENU_NOT_FOUND';
  end if;

  update public.catalog_menu_items
  set is_available = p_is_available,
      updated_at = now()
  where id = v_menu.id
  returning * into v_menu;

  return public.kc_owner_menu_row_json(v_menu);
end;
$$;

create function public.kc_owner_archive_menu(
  p_owner_id uuid,
  p_menu_id uuid
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_menu public.catalog_menu_items%rowtype;
begin
  select m.*
  into v_menu
  from public.catalog_menu_items m
  join public.catalog_stalls s on s.id = m.stall_id
  where m.id = p_menu_id and s.owner_id = p_owner_id
  for update of m;

  if not found then
    raise exception 'KC_MENU_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_MENU_NOT_FOUND';
  end if;

  update public.catalog_menu_items
  set is_archived = true,
      is_listed = false,
      updated_at = now()
  where id = v_menu.id
  returning * into v_menu;

  return public.kc_owner_menu_row_json(v_menu);
end;
$$;

create function public.kc_owner_restore_menu(
  p_owner_id uuid,
  p_menu_id uuid
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_menu public.catalog_menu_items%rowtype;
begin
  select m.*
  into v_menu
  from public.catalog_menu_items m
  join public.catalog_stalls s on s.id = m.stall_id
  where m.id = p_menu_id and s.owner_id = p_owner_id
  for update of m;

  if not found then
    raise exception 'KC_MENU_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_MENU_NOT_FOUND';
  end if;

  update public.catalog_menu_items
  set is_archived = false,
      is_listed = true,
      updated_at = now()
  where id = v_menu.id
  returning * into v_menu;

  return public.kc_owner_menu_row_json(v_menu);
end;
$$;

create function public.kc_owner_set_menu_photo(
  p_owner_id uuid,
  p_menu_id uuid,
  p_photo_path text
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_menu public.catalog_menu_items%rowtype;
begin
  select m.*
  into v_menu
  from public.catalog_menu_items m
  join public.catalog_stalls s on s.id = m.stall_id
  where m.id = p_menu_id and s.owner_id = p_owner_id
  for update of m;

  if not found then
    raise exception 'KC_MENU_NOT_FOUND'
      using errcode = 'P0001', detail = 'KC_MENU_NOT_FOUND';
  end if;

  update public.catalog_menu_items
  set photo_path = nullif(btrim(coalesce(p_photo_path, '')), ''),
      updated_at = now()
  where id = v_menu.id
  returning * into v_menu;

  return public.kc_owner_menu_row_json(v_menu);
end;
$$;

revoke all on function
  public.kc_guard_catalog_stall_update(),
  public.kc_owner_get_stall(uuid),
  public.kc_owner_create_stall(uuid, text, text, text, text, integer),
  public.kc_owner_update_stall(uuid, text, text, text, text, integer),
  public.kc_owner_set_stall_photo(uuid, text),
  public.kc_owner_set_stall_schedule(uuid, jsonb),
  public.kc_owner_publish_stall(uuid),
  public.kc_owner_set_stall_open(uuid, boolean),
  public.kc_owner_list_categories(uuid),
  public.kc_owner_create_category(uuid, text),
  public.kc_owner_rename_category(uuid, uuid, text),
  public.kc_owner_delete_category(uuid, uuid),
  public.kc_owner_menu_row_json(public.catalog_menu_items),
  public.kc_owner_list_menus(uuid, boolean, text),
  public.kc_owner_create_menu(uuid, text, uuid, integer, boolean, text),
  public.kc_owner_update_menu(uuid, uuid, text, uuid, integer, boolean, text),
  public.kc_owner_set_menu_availability(uuid, uuid, boolean),
  public.kc_owner_archive_menu(uuid, uuid),
  public.kc_owner_restore_menu(uuid, uuid),
  public.kc_owner_set_menu_photo(uuid, uuid, text)
from public, anon, authenticated;

grant execute on function
  public.kc_guard_catalog_stall_update(),
  public.kc_owner_get_stall(uuid),
  public.kc_owner_create_stall(uuid, text, text, text, text, integer),
  public.kc_owner_update_stall(uuid, text, text, text, text, integer),
  public.kc_owner_set_stall_photo(uuid, text),
  public.kc_owner_set_stall_schedule(uuid, jsonb),
  public.kc_owner_publish_stall(uuid),
  public.kc_owner_set_stall_open(uuid, boolean),
  public.kc_owner_list_categories(uuid),
  public.kc_owner_create_category(uuid, text),
  public.kc_owner_rename_category(uuid, uuid, text),
  public.kc_owner_delete_category(uuid, uuid),
  public.kc_owner_menu_row_json(public.catalog_menu_items),
  public.kc_owner_list_menus(uuid, boolean, text),
  public.kc_owner_create_menu(uuid, text, uuid, integer, boolean, text),
  public.kc_owner_update_menu(uuid, uuid, text, uuid, integer, boolean, text),
  public.kc_owner_set_menu_availability(uuid, uuid, boolean),
  public.kc_owner_archive_menu(uuid, uuid),
  public.kc_owner_restore_menu(uuid, uuid),
  public.kc_owner_set_menu_photo(uuid, uuid, text)
to service_role;

commit;
