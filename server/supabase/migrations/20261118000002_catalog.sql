begin;

create table public.catalog_stalls (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id),
  name text not null check (char_length(btrim(name)) between 1 and 120),
  block text not null check (char_length(btrim(block)) between 1 and 60),
  description text not null default '' check (char_length(description) <= 2000),
  wait_minutes smallint not null default 0 check (wait_minutes between 0 and 240),
  is_listed boolean not null default false,
  is_open boolean not null default false
);

create table public.catalog_menu_items (
  id uuid primary key default gen_random_uuid(),
  stall_id uuid not null references public.catalog_stalls(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 120),
  category text not null check (char_length(btrim(category)) between 1 and 60),
  description text not null default '' check (char_length(description) <= 2000),
  price integer not null check (price between 0 and 1000000000),
  is_available boolean not null default false,
  is_listed boolean not null default false
);

create index catalog_stalls_owner on public.catalog_stalls (owner_id);
create index catalog_stalls_listed on public.catalog_stalls (id) where is_listed;
create index catalog_menu_stall on public.catalog_menu_items (stall_id, id);
create index catalog_menu_listed on public.catalog_menu_items (id) where is_listed;

alter table public.catalog_stalls enable row level security;
alter table public.catalog_menu_items enable row level security;
revoke all on public.catalog_stalls, public.catalog_menu_items from public, anon, authenticated;
grant select, insert, update, delete on public.catalog_stalls, public.catalog_menu_items to service_role;

create function public.kc_catalog_stalls(
  p_query text, p_after uuid, p_stall_id uuid, p_limit integer
)
returns table (id uuid, item jsonb)
language sql stable security invoker set search_path = ''
as $$
  select s.id, jsonb_build_object(
    'id', s.id, 'name', s.name, 'block', s.block, 'description', s.description,
    'wait_minutes', s.wait_minutes, 'is_open', s.is_open
  )
  from public.catalog_stalls s
  where s.is_listed
    and (p_after is null or s.id > p_after)
    and (p_stall_id is null or s.id = p_stall_id)
    and (
      p_query = '' or strpos(lower(s.name), lower(p_query)) > 0
      or strpos(lower(s.block), lower(p_query)) > 0
    )
  order by s.id
  limit least(greatest(p_limit, 1), 41);
$$;

create function public.kc_catalog_menu(
  p_query text, p_after uuid, p_stall_id uuid, p_limit integer
)
returns table (id uuid, item jsonb)
language sql stable security invoker set search_path = ''
as $$
  select m.id, jsonb_build_object(
    'id', m.id, 'name', m.name, 'category', m.category, 'description', m.description,
    'price', m.price, 'is_available', m.is_available, 'stall_id', s.id,
    'stall_name', s.name, 'block', s.block, 'wait_minutes', s.wait_minutes,
    'stall_is_open', s.is_open
  )
  from public.catalog_menu_items m
  join public.catalog_stalls s on s.id = m.stall_id
  where m.is_listed and s.is_listed
    and (p_after is null or m.id > p_after)
    and (p_stall_id is null or s.id = p_stall_id)
    and (
      p_query = '' or strpos(lower(m.name), lower(p_query)) > 0
      or strpos(lower(m.category), lower(p_query)) > 0
      or strpos(lower(s.name), lower(p_query)) > 0
    )
  order by m.id
  limit least(greatest(p_limit, 1), 41);
$$;

revoke all on function public.kc_catalog_stalls(text, uuid, uuid, integer),
  public.kc_catalog_menu(text, uuid, uuid, integer) from public, anon, authenticated;
grant execute on function public.kc_catalog_stalls(text, uuid, uuid, integer),
  public.kc_catalog_menu(text, uuid, uuid, integer) to service_role;

commit;
