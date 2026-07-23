-- ════════════════════════════════════════════════════════════════
--  재화 분리: 코인(뽑기) · 클로버(커스텀 행운권)
--
--  이전: 20260713000006 이 "클로버 = 뽑기 코인"으로 화폐를 일원화했다.
--        선행으로 만든 클로버를 그대로 뽑기에 썼다.
--
--  이제: 재화를 둘로 가른다.
--        · 클로버 — 선행 4건으로 1개. 커스텀 행운권 제작·강화에만 쓴다.
--        · 코인   — 리워드 광고 1회로 1개(하루 ad_coins_per_day 회). 뽑기에만 쓴다.
--        환전은 없다. 선행이 향하는 곳이 뽑기가 아니라 "내가 만든 행운권"이 된다.
--
--  기존 유저의 보유 클로버는 그대로 남고 용도만 바뀐다. 코인은 0에서 시작한다.
-- ════════════════════════════════════════════════════════════════

-- ---- 프로필: 코인 추가, 광고 카운터 재정의 ----
alter table public.profiles
  add column if not exists coins int not null default 0 check (coins >= 0);
alter table public.profiles
  rename column ad_clovers_today to ad_coins_today;
alter table public.profiles
  rename column last_ad_clover_date to last_ad_coin_date;

-- ---- 기록 종류에 '커스텀 제작' 추가 ----
alter table public.history
  drop constraint if exists history_kind_check;
alter table public.history
  add constraint history_kind_check check (kind in ('deed', 'pull', 'custom'));

-- ---- 커스텀 행운권 ----
--  ticket_instances 에 섞지 않는다. 카탈로그 FK 가 깨지고, 무엇보다
--  enhance_ticket 의 재료 개수 검사가 카탈로그 조인 없이 ticket_instances 만
--  세기 때문에 커스텀 카드가 재료로 태워질 수 있다. 테이블을 나누면
--  "커스텀은 재료가 되지 않는다"가 규칙이 아니라 구조로 보장된다.
create table if not exists public.custom_tickets (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  text       text not null check (char_length(text) between 1 and 40),
  level      int  not null default 1 check (level >= 1),
  created_at timestamptz not null default now()
);

create index if not exists custom_tickets_user_idx
  on public.custom_tickets (user_id, created_at desc);

alter table public.custom_tickets enable row level security;

drop policy if exists custom_tickets_own on public.custom_tickets;
create policy custom_tickets_own on public.custom_tickets
  for select using (auth.uid() = user_id);

-- ---- 설정값 ----
insert into public.game_config (key, value) values
  ('ad_coins_per_day', '5'::jsonb),
  ('custom_ticket_cost', '1'::jsonb)
on conflict (key) do update set value = excluded.value;

delete from public.game_config where key = 'ad_clovers_per_day';

-- ---- 뽑기: 코인 1개 ----
drop function if exists public.pull_gacha();

create function public.pull_gacha()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid       uuid := auth.uid();
  v_profile   public.profiles;
  v_total     int;
  v_roll      int;
  v_rarity    text;
  v_ticket_id text;
  v_instance  uuid;
  v_copies    int;
  v_is_new    boolean;
  rec         record;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  select * into v_profile from public.profiles where user_id = v_uid for update;
  if not found then raise exception 'AUTH_REQUIRED'; end if;
  if v_profile.coins < 1 then raise exception 'NO_COINS'; end if;

  -- 등급 추첨 (가중치) → 등급 내 균등 추첨.
  select sum(weight) into v_total from public.rarity_weights;
  v_roll := floor(random() * v_total)::int;
  for rec in select rarity, weight from public.rarity_weights order by sort_order
  loop
    if v_roll < rec.weight then
      v_rarity := rec.rarity;
      exit;
    end if;
    v_roll := v_roll - rec.weight;
  end loop;

  select id into v_ticket_id
    from public.ticket_catalog
   where rarity = v_rarity and active
   order by random()
   limit 1;

  select not exists (
    select 1 from public.ticket_instances
     where user_id = v_uid and ticket_id = v_ticket_id
  ) into v_is_new;

  insert into public.ticket_instances (user_id, ticket_id)
  values (v_uid, v_ticket_id)
  returning id into v_instance;

  select count(*) into v_copies
    from public.ticket_instances
   where user_id = v_uid and ticket_id = v_ticket_id;

  update public.profiles
     set coins = coins - 1,
         stat_pulls = stat_pulls + 1,
         updated_at = now()
   where user_id = v_uid;

  insert into public.history (user_id, kind, text, amount)
  values (v_uid, 'pull', v_ticket_id, 1);

  return jsonb_build_object(
    'instance_id', v_instance,
    'ticket_id', v_ticket_id,
    'is_new', v_is_new,
    'copies', v_copies,
    'level', 1
  );
end;
$$;

-- ---- 광고 보상: 코인 1개 지급 (하루 한도) ----
drop function if exists public.grant_ad_clover();

create function public.grant_ad_coin()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := auth.uid();
  v_profile public.profiles;
  v_limit   int;
  v_used    int;
  v_coins   int;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  select * into v_profile from public.profiles where user_id = v_uid for update;
  if not found then raise exception 'AUTH_REQUIRED'; end if;

  v_limit := coalesce(
    (select (value #>> '{}')::int from public.game_config where key = 'ad_coins_per_day'), 5);
  v_used := case
    when v_profile.last_ad_coin_date = current_date then v_profile.ad_coins_today
    else 0
  end;
  if v_used >= v_limit then raise exception 'NO_AD_COINS'; end if;

  update public.profiles
     set coins = coins + 1,
         ad_coins_today = v_used + 1,
         last_ad_coin_date = current_date,
         updated_at = now()
   where user_id = v_uid
   returning coins into v_coins;

  return jsonb_build_object(
    'coins', v_coins,
    'ad_coins_today', v_used + 1
  );
end;
$$;

-- ---- 커스텀 행운권 제작: 클로버 1개 ----
create or replace function public.create_custom_ticket(p_text text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := auth.uid();
  v_profile public.profiles;
  v_text    text;
  v_cost    int;
  v_clovers int;
  v_id      uuid;
  v_at      timestamptz;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  v_text := btrim(coalesce(p_text, ''));
  if char_length(v_text) < 1 or char_length(v_text) > 40 then
    raise exception 'INVALID_TEXT';
  end if;

  v_cost := coalesce(
    (select (value #>> '{}')::int from public.game_config where key = 'custom_ticket_cost'), 1);

  select * into v_profile from public.profiles where user_id = v_uid for update;
  if not found then raise exception 'AUTH_REQUIRED'; end if;
  if v_profile.clovers < v_cost then raise exception 'NO_CLOVERS'; end if;

  insert into public.custom_tickets (user_id, text)
  values (v_uid, v_text)
  returning id, created_at into v_id, v_at;

  update public.profiles
     set clovers = clovers - v_cost,
         updated_at = now()
   where user_id = v_uid
   returning clovers into v_clovers;

  insert into public.history (user_id, kind, text, amount)
  values (v_uid, 'custom', v_text, v_cost);

  return jsonb_build_object(
    'id', v_id,
    'text', v_text,
    'level', 1,
    'created_at', v_at,
    'clovers', v_clovers
  );
end;
$$;

-- ---- 커스텀 행운권 강화: 클로버 L개, 실패 없음 ----
--  등급이 없는 카드라 확률 실패를 붙일 근거가 없다. +N 의 무게는 실패
--  리스크가 아니라 "선행 몇 건이 들어갔는가"라는 시간이 만든다.
create or replace function public.enhance_custom_ticket(p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := auth.uid();
  v_level   int;
  v_max     int;
  v_clovers int;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  v_max := coalesce(
    (select (value #>> '{}')::int from public.game_config where key = 'max_level'), 5);

  select level into v_level
    from public.custom_tickets
   where id = p_id and user_id = v_uid
   for update;
  if not found then raise exception 'TICKET_NOT_OWNED'; end if;
  if v_level >= v_max then raise exception 'CANNOT_ENHANCE'; end if;

  -- 비용 = 현재 레벨. Lv.1→2 는 1개, Lv.4→5 는 4개. Lv.5 까지 합계 10개.
  update public.profiles
     set clovers = clovers - v_level,
         updated_at = now()
   where user_id = auth.uid() and clovers >= v_level
   returning clovers into v_clovers;
  if not found then raise exception 'NO_CLOVERS'; end if;

  update public.custom_tickets set level = v_level + 1 where id = p_id;

  return jsonb_build_object(
    'id', p_id,
    'level', v_level + 1,
    'clovers', v_clovers
  );
end;
$$;

-- ---- 실행 권한 ----
revoke execute on function
  public.pull_gacha(),
  public.grant_ad_coin(),
  public.create_custom_ticket(text),
  public.enhance_custom_ticket(uuid)
from public, anon;

grant execute on function
  public.pull_gacha(),
  public.grant_ad_coin(),
  public.create_custom_ticket(text),
  public.enhance_custom_ticket(uuid)
to authenticated;
