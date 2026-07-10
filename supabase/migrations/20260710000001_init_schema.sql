-- ════════════════════════════════════════════════════════════════
--  LuckyPicky 초기 스키마
--  서버 권위 모델: 유저 테이블은 SELECT(본인 행)만 허용하고,
--  모든 쓰기는 SECURITY DEFINER RPC(20260710000003)를 통해서만 일어난다.
-- ════════════════════════════════════════════════════════════════

-- ---- 유저 프로필 (재화/통계/무료뽑기 카운터) ----
create table public.profiles (
  user_id              uuid primary key references auth.users (id) on delete cascade,
  leaves               int  not null default 0 check (leaves >= 0),
  clovers              int  not null default 0 check (clovers >= 0),
  stat_leaves          int  not null default 0,
  stat_clovers         int  not null default 0,
  stat_pulls           int  not null default 0,
  free_pulls_used_today int not null default 0,
  last_free_pull_date  date,
  imported_local       boolean not null default false,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

-- 회원가입(익명 포함) 시 프로필 자동 생성.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---- 행운권 카탈로그 (id/등급만 — 문구는 앱에서 3개 국어로 보유) ----
create table public.ticket_catalog (
  id     text primary key,
  rarity text not null check (rarity in ('common', 'rare', 'epic', 'legendary', 'mythic')),
  active boolean not null default true
);

-- 등급별 추첨 가중치 — 값을 바꾸면 앱 업데이트 없이 확률이 바뀐다.
create table public.rarity_weights (
  rarity     text primary key check (rarity in ('common', 'rare', 'epic', 'legendary', 'mythic')),
  weight     int  not null check (weight >= 0),
  sort_order int  not null unique
);

-- 게임 상수 (원격 튜닝 가능).
create table public.game_config (
  key   text primary key,
  value jsonb not null
);

-- ---- 도감 (유저별 보유 행운권) ----
create table public.owned_tickets (
  user_id        uuid not null references public.profiles (user_id) on delete cascade,
  ticket_id      text not null references public.ticket_catalog (id),
  copies         int  not null default 1 check (copies >= 1),
  level          int  not null default 1 check (level >= 1),
  first_pulled_at date not null default current_date,
  primary key (user_id, ticket_id)
);

-- ---- 기록 (선행/뽑기 타임라인) ----
create table public.history (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references public.profiles (user_id) on delete cascade,
  kind        text not null check (kind in ('deed', 'pull')),
  text        text not null,
  amount      int  not null default 0,
  happened_on date not null default current_date,
  created_at  timestamptz not null default now()
);

create index history_user_recent on public.history (user_id, created_at desc);

-- ---- RLS: 본인 행 읽기만, 쓰기는 전부 RPC ----
alter table public.profiles       enable row level security;
alter table public.owned_tickets  enable row level security;
alter table public.history        enable row level security;
alter table public.ticket_catalog enable row level security;
alter table public.rarity_weights enable row level security;
alter table public.game_config    enable row level security;

create policy "read own profile" on public.profiles
  for select to authenticated using (user_id = (select auth.uid()));

create policy "read own tickets" on public.owned_tickets
  for select to authenticated using (user_id = (select auth.uid()));

create policy "read own history" on public.history
  for select to authenticated using (user_id = (select auth.uid()));

create policy "read catalog" on public.ticket_catalog
  for select to authenticated using (true);

create policy "read weights" on public.rarity_weights
  for select to authenticated using (true);

create policy "read config" on public.game_config
  for select to authenticated using (true);
