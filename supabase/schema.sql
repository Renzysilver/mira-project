-- ============================================================================
-- MIRA — Supabase schema
-- ============================================================================
-- Multi-companion ready from day one. Every companion-scoped table has a
-- companion_id foreign key, so when we build the companion-switcher UI
-- the data model already supports it.
--
-- Apply this via: Supabase Dashboard → SQL Editor → paste → Run.
-- Or via the Supabase CLI:  supabase db push
-- ============================================================================

-- ── Extensions ─────────────────────────────────────────────────────────────
create extension if not exists "pgcrypto";  -- for gen_random_uuid()

-- ── users table ────────────────────────────────────────────────────────────
-- Mirrors the Firebase users/{uid} document. Auth is handled by Supabase
-- Auth (supabase.auth.users), so this table is keyed on auth.uid() and
-- stores the app-specific profile data.
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text,
  photo_url text,
  onboarding_complete boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ── companions table ───────────────────────────────────────────────────────
-- A user can have multiple companions. Each companion has its own persona,
-- voice, memory, and relationship progression.
--
-- When multi-companion UI lands:
--   1. Insert a row here for each new companion.
--   2. Set is_active = true on the currently-selected one (and false on
--      all others for the same user).
--   3. All companion-scoped reads (memories, messages, call_logs) filter
--      by companion_id.
create table if not exists public.companions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  name text not null default 'Mira',
  personality_type text not null default 'sweet'
    check (personality_type in ('sweet', 'tsundere', 'intellectual')),
  current_mood text not null default 'happy'
    check (current_mood in ('happy','shy','excited','sad','thinking','sleepy','neutral','flirty')),
  temperature real not null default 0.8,
  flirt_enabled boolean not null default false,
  friendship_mode boolean not null default false,

  -- Avatar
  custom_avatar text,
  avatar_asset_path text,

  -- Voice identity (per-companion)
  voice_provider text default 'groq',  -- 'groq' | 'elevenlabs' | 'cartesia' | 'azure'
  voice_id text default 'hannah',      -- provider-specific voice identifier
  speech_pattern text default 'casual' -- 'formal' | 'casual' | 'friendly' | 'teasing' | 'intellectual' | 'emotional',

  -- Future: companion creator fields (placeholder for Phase 4)
  background_story text,
  hair_style text,
  hair_color text,
  eye_color text,
  face_style text,
  clothing text,
  accessories text[],
  interests text[],  -- ['gaming','anime','music', ...]
  accent text default 'neutral',
  tone text default 'soft',
  energy_level text default 'medium',
  speaking_speed text default 'normal',

  -- State
  is_favorite boolean not null default false,
  is_active boolean not null default false,  -- currently-selected companion
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Ensure only one active companion per user.
create unique index if not exists one_active_companion_per_user
  on public.companions (user_id)
  where is_active = true;

-- ── relationship_stats ─────────────────────────────────────────────────────
-- Per-companion relationship progression. One row per companion.
create table if not exists public.relationship_stats (
  companion_id uuid primary key references public.companions(id) on delete cascade,
  days_together int not null default 0,
  messages_sent int not null default 0,
  calls_made int not null default 0,
  affection_level int not null default 30 check (affection_level between 0 and 100),
  streak_days int not null default 0,
  last_check_in text default '',
  start_date text default '',
  updated_at timestamptz not null default now()
);

-- ── memories ───────────────────────────────────────────────────────────────
-- Per-companion memory facts. Each companion remembers different things
-- about the user — memories do NOT transfer between companions.
create table if not exists public.memories (
  id uuid primary key default gen_random_uuid(),
  companion_id uuid not null references public.companions(id) on delete cascade,
  fact text not null,
  category text not null default 'personal',
  created_at timestamptz not null default now()
);

create index if not exists idx_memories_companion on public.memories(companion_id);

-- ── messages ───────────────────────────────────────────────────────────────
-- Per-companion chat messages. conversation_id allows multiple chat
-- threads per companion in the future (e.g. 'main', 'roleplay').
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  companion_id uuid not null references public.companions(id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  conversation_id text not null default 'main',
  created_at timestamptz not null default now()
);

create index if not exists idx_messages_companion_conv
  on public.messages(companion_id, conversation_id, created_at);

-- ── call_logs ──────────────────────────────────────────────────────────────
create table if not exists public.call_logs (
  id uuid primary key default gen_random_uuid(),
  companion_id uuid not null references public.companions(id) on delete cascade,
  persona_name text,
  duration int not null default 0,
  summary text,
  ended_at timestamptz not null default now()
);

create index if not exists idx_call_logs_companion on public.call_logs(companion_id);

-- ── user_settings ──────────────────────────────────────────────────────────
-- Global user settings (not per-companion).
create table if not exists public.user_settings (
  user_id uuid primary key references public.users(id) on delete cascade,
  dark_mode boolean not null default true,
  notifications boolean not null default true,
  sound_effects boolean not null default true,
  flirt_mode boolean not null default false,
  friendship_mode boolean not null default false,
  ai_voice boolean not null default true,
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- Row Level Security (RLS)
-- ============================================================================
-- Every table is locked down so a user can only see/modify rows that
-- belong to them. Companion-scoped tables inherit this via the
-- companion_id -> user_id join.
-- ============================================================================

alter table public.users enable row level security;
alter table public.companions enable row level security;
alter table public.relationship_stats enable row level security;
alter table public.memories enable row level security;
alter table public.messages enable row level security;
alter table public.call_logs enable row level security;
alter table public.user_settings enable row level security;

-- ── users policies ─────────────────────────────────────────────────────────
drop policy if exists "users_select_own" on public.users;
create policy "users_select_own" on public.users
  for select using (auth.uid() = id);

drop policy if exists "users_update_own" on public.users;
create policy "users_update_own" on public.users
  for update using (auth.uid() = id);

drop policy if exists "users_insert_own" on public.users;
create policy "users_insert_own" on public.users
  for insert with check (auth.uid() = id);

-- ── companions policies ────────────────────────────────────────────────────
drop policy if exists "companions_all_own" on public.companions;
create policy "companions_all_own" on public.companions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── relationship_stats policies ────────────────────────────────────────────
-- Joins to companions to verify ownership.
drop policy if exists "relationship_stats_all_own" on public.relationship_stats;
create policy "relationship_stats_all_own" on public.relationship_stats
  for all using (
    exists (select 1 from public.companions c
            where c.id = companion_id and c.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.companions c
            where c.id = companion_id and c.user_id = auth.uid())
  );

-- ── memories policies ──────────────────────────────────────────────────────
drop policy if exists "memories_all_own" on public.memories;
create policy "memories_all_own" on public.memories
  for all using (
    exists (select 1 from public.companions c
            where c.id = companion_id and c.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.companions c
            where c.id = companion_id and c.user_id = auth.uid())
  );

-- ── messages policies ──────────────────────────────────────────────────────
drop policy if exists "messages_all_own" on public.messages;
create policy "messages_all_own" on public.messages
  for all using (
    exists (select 1 from public.companions c
            where c.id = companion_id and c.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.companions c
            where c.id = companion_id and c.user_id = auth.uid())
  );

-- ── call_logs policies ─────────────────────────────────────────────────────
drop policy if exists "call_logs_all_own" on public.call_logs;
create policy "call_logs_all_own" on public.call_logs
  for all using (
    exists (select 1 from public.companions c
            where c.id = companion_id and c.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.companions c
            where c.id = companion_id and c.user_id = auth.uid())
  );

-- ── user_settings policies ─────────────────────────────────────────────────
drop policy if exists "user_settings_all_own" on public.user_settings;
create policy "user_settings_all_own" on public.user_settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================================
-- Triggers
-- ============================================================================
-- Auto-update updated_at on every row update.
-- ============================================================================
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists users_updated_at on public.users;
create trigger users_updated_at before update on public.users
  for each row execute function public.handle_updated_at();

drop trigger if exists companions_updated_at on public.companions;
create trigger companions_updated_at before update on public.companions
  for each row execute function public.handle_updated_at();

drop trigger if exists relationship_stats_updated_at on public.relationship_stats;
create trigger relationship_stats_updated_at before update on public.relationship_stats
  for each row execute function public.handle_updated_at();

drop trigger if exists user_settings_updated_at on public.user_settings;
create trigger user_settings_updated_at before update on public.user_settings
  for each row execute function public.handle_updated_at();

-- ============================================================================
-- Auto-create user profile on signup
-- ============================================================================
-- When a new user signs up via Supabase Auth, this trigger creates a
-- matching row in public.users with their email + a default companion.
-- ============================================================================
create or replace function public.handle_new_user()
returns trigger as $$
declare
  new_companion_id uuid;
begin
  -- Insert user profile
  insert into public.users (id, email, display_name, photo_url)
  values (new.id, new.email, new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'photo_url');

  -- Create the default companion (Mira)
  insert into public.companions (user_id, name, is_active)
  values (new.id, 'Mira', true)
  returning id into new_companion_id;

  -- Create relationship stats for the companion
  insert into public.relationship_stats (companion_id)
  values (new_companion_id);

  -- Create default user settings
  insert into public.user_settings (user_id)
  values (new.id);

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================================
-- Done. To verify:
--   select * from public.users;
--   select * from public.companions;
--   select * from public.relationship_stats;
-- ============================================================================
