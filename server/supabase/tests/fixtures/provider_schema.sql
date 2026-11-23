-- Minimal managed schema for isolated PostgreSQL tests. Never apply to Supabase.
create role anon;
create role authenticated;
create role service_role bypassrls;
create schema auth;
create schema storage;

create table auth.users (
  id uuid primary key,
  email text,
  encrypted_password text,
  email_confirmed_at timestamptz,
  recovery_token text,
  recovery_sent_at timestamptz,
  banned_until timestamptz,
  raw_app_meta_data jsonb not null default '{}'::jsonb,
  raw_user_meta_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table auth.sessions (
  id uuid primary key,
  user_id uuid not null references auth.users(id),
  not_after timestamptz
);

create table auth.identities (
  id uuid primary key default gen_random_uuid(),
  provider_id text not null,
  provider text not null,
  user_id uuid not null references auth.users(id),
  identity_data jsonb not null,
  unique (provider_id, provider)
);

create table storage.buckets (
  id text primary key,
  name text not null,
  public boolean not null,
  file_size_limit bigint,
  allowed_mime_types text[]
);

create table storage.objects (bucket_id text references storage.buckets(id));
alter table storage.objects enable row level security;
