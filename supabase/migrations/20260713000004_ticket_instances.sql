-- ════════════════════════════════════════════════════════════════
--  행운권 인스턴스화 + 확률 강화
--
--  기존: owned_tickets(user_id, ticket_id) 한 행에 copies/level 을 합산.
--        → 중복이 숫자로만 존재해 "어느 카드를 재료로 쓸지" 고를 수 없었다.
--  변경: 뽑을 때마다 ticket_instances 에 카드 한 장이 생긴다.
--        강화는 대상 카드 1장 + 같은 행운권 카드 N장(재료)을 지정해서 실행하고,
--        확률로 성공/실패한다. 재료는 성공/실패와 무관하게 소모된다.
--
--  강화 단계 표기: level 1 = 무강화, level L = +(L-1).
--  L → L+1 요구 재료 = L장. 성공 확률은 game_config.enhance_rates 로 원격 튜닝.
-- ════════════════════════════════════════════════════════════════

-- 이 파일은 몇 번을 다시 실행해도 안전하다(멱등) — 중간에 끊겨도 그냥 재실행하면 된다.

-- ---- 카드 인스턴스 ----
create table if not exists public.ticket_instances (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (user_id) on delete cascade,
  ticket_id  text not null references public.ticket_catalog (id),
  level      int  not null default 1 check (level >= 1),
  pulled_at  date not null default current_date,
  created_at timestamptz not null default now()
);

create index if not exists ticket_instances_user
  on public.ticket_instances (user_id, ticket_id);

alter table public.ticket_instances enable row level security;

drop policy if exists "read own instances" on public.ticket_instances;
create policy "read own instances" on public.ticket_instances
  for select to authenticated using (user_id = (select auth.uid()));

-- ---- 기존 owned_tickets → 인스턴스 백필 ----
-- 강화된 카드 1장(level 유지) + 아직 안 쓴 여분(copies - 1 - 누적소모)만큼의 기본 카드.
-- 구 테이블이 이미 없거나 이관이 끝났으면 건너뛴다.
do $$
begin
  if to_regclass('public.owned_tickets') is not null
     and not exists (select 1 from public.ticket_instances) then

    insert into public.ticket_instances (user_id, ticket_id, level, pulled_at)
    select o.user_id, o.ticket_id, o.level, o.first_pulled_at
      from public.owned_tickets o;

    insert into public.ticket_instances (user_id, ticket_id, level, pulled_at)
    select o.user_id, o.ticket_id, 1, o.first_pulled_at
      from public.owned_tickets o,
           generate_series(1, greatest(o.copies - 1 - (o.level * (o.level - 1) / 2), 0));
  end if;
end
$$;

-- ---- 강화 성공 확률 (도달 레벨 기준 %) ----
insert into public.game_config (key, value)
values ('enhance_rates', '{"2": 100, "3": 80, "4": 60, "5": 40}'::jsonb)
on conflict (key) do update set value = excluded.value;

-- ---- pull_gacha: 인스턴스 생성으로 교체 ----
-- 구버전은 p_free 에 기본값이 있어 create or replace 로는 바꿀 수 없다 → 먼저 드롭.
drop function if exists public.pull_gacha(boolean);

create function public.pull_gacha(p_free boolean default false)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid        uuid := auth.uid();
  v_profile    public.profiles;
  v_free_limit int;
  v_free_used  int;
  v_total      int;
  v_roll       int;
  v_rarity     text;
  v_ticket_id  text;
  v_instance   uuid;
  v_copies     int;
  v_is_new     boolean;
  rec          record;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  select * into v_profile from public.profiles where user_id = v_uid for update;
  if not found then raise exception 'AUTH_REQUIRED'; end if;

  if p_free then
    v_free_limit := coalesce(
      (select (value #>> '{}')::int from public.game_config where key = 'free_pulls_per_day'), 3);
    v_free_used := case
      when v_profile.last_free_pull_date = current_date then v_profile.free_pulls_used_today
      else 0
    end;
    if v_free_used >= v_free_limit then raise exception 'NO_FREE_PULLS'; end if;
  else
    if v_profile.clovers < 1 then raise exception 'NO_CLOVERS'; end if;
  end if;

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
     set clovers = clovers - (case when p_free then 0 else 1 end),
         stat_pulls = stat_pulls + 1,
         free_pulls_used_today = case when p_free then v_free_used + 1 else free_pulls_used_today end,
         last_free_pull_date = case when p_free then current_date else last_free_pull_date end,
         updated_at = now()
   where user_id = v_uid;

  insert into public.history (user_id, kind, text, amount)
  values (v_uid, 'pull', v_ticket_id, case when p_free then 0 else 1 end);

  return jsonb_build_object(
    'instance_id', v_instance,
    'ticket_id', v_ticket_id,
    'is_new', v_is_new,
    'copies', v_copies,
    'level', 1,
    'free', p_free
  );
end;
$$;

-- ---- enhance_ticket: 대상 1장 + 재료 N장 지정, 확률 강화 ----
-- 재료는 대상과 같은 행운권의 다른 인스턴스여야 한다. 성공/실패 모두 재료는 소모.
drop function if exists public.enhance_ticket(text);
drop function if exists public.enhance_ticket(uuid, uuid[]);

create function public.enhance_ticket(p_target uuid, p_materials uuid[])
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid       uuid := auth.uid();
  v_max       int;
  v_level     int;
  v_ticket_id text;
  v_need      int;
  v_have      int;
  v_rate      int;
  v_success   boolean;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  v_max := coalesce(
    (select (value #>> '{}')::int from public.game_config where key = 'max_level'), 5);

  select level, ticket_id into v_level, v_ticket_id
    from public.ticket_instances
   where id = p_target and user_id = v_uid
   for update;
  if not found then raise exception 'TICKET_NOT_OWNED'; end if;
  if v_level >= v_max then raise exception 'CANNOT_ENHANCE'; end if;

  -- 재료 검증: 본인 소유 · 같은 행운권 · 대상 제외 · 중복 제거 후 개수 일치.
  v_need := v_level;
  select count(*) into v_have
    from public.ticket_instances
   where id = any (select distinct unnest(p_materials))
     and id <> p_target
     and user_id = v_uid
     and ticket_id = v_ticket_id;
  if v_have <> v_need then raise exception 'CANNOT_ENHANCE'; end if;

  -- 재료 소모 (성공 여부와 무관).
  delete from public.ticket_instances
   where id = any (select distinct unnest(p_materials))
     and id <> p_target
     and user_id = v_uid
     and ticket_id = v_ticket_id;

  -- 확률 판정은 서버에서만 — 클라이언트는 결과만 받는다.
  v_rate := coalesce(
    (select (value -> (v_level + 1)::text)::int from public.game_config where key = 'enhance_rates'),
    100);
  v_success := (random() * 100) < v_rate;

  if v_success then
    update public.ticket_instances
       set level = v_level + 1
     where id = p_target;
  end if;

  return jsonb_build_object(
    'instance_id', p_target,
    'ticket_id', v_ticket_id,
    'success', v_success,
    'level', case when v_success then v_level + 1 else v_level end,
    'rate', v_rate
  );
end;
$$;

-- ---- import_local_state: 도감 부분만 인스턴스로 ----
create or replace function public.import_local_state(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid   uuid := auth.uid();
  v_max   int;
  v_entry jsonb;
  v_date  date;
  v_ticket_id text;
  v_copies int;
  v_level  int;
  v_spare  int;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  v_max := coalesce(
    (select (value #>> '{}')::int from public.game_config where key = 'max_level'), 5);

  perform 1 from public.profiles where user_id = v_uid for update;
  if not found then raise exception 'AUTH_REQUIRED'; end if;
  if (select imported_local from public.profiles where user_id = v_uid) then
    raise exception 'ALREADY_IMPORTED';
  end if;

  update public.profiles
     set leaves       = least(greatest(coalesce((p_payload ->> 'leaves')::int, 0), 0), 10),
         clovers      = least(greatest(coalesce((p_payload ->> 'clovers')::int, 0), 0), 999),
         stat_leaves  = least(greatest(coalesce((p_payload ->> 'statLeaves')::int, 0), 0), 100000),
         stat_clovers = least(greatest(coalesce((p_payload ->> 'statClovers')::int, 0), 0), 100000),
         stat_pulls   = least(greatest(coalesce((p_payload ->> 'statPulls')::int, 0), 0), 100000),
         imported_local = true,
         updated_at   = now()
   where user_id = v_uid;

  -- 구버전 payload 는 {ticketId, copies, level} 합산 형태다 — 인스턴스로 펼친다.
  for v_entry in select * from jsonb_array_elements(coalesce(p_payload -> 'tickets', '[]'::jsonb))
  loop
    v_ticket_id := v_entry ->> 'ticketId';
    if not exists (select 1 from public.ticket_catalog where id = v_ticket_id) then
      continue;
    end if;
    v_copies := least(greatest(coalesce((v_entry ->> 'copies')::int, 1), 1), 999);
    v_level  := least(greatest(coalesce((v_entry ->> 'level')::int, 1), 1), v_max);
    while v_level > 1 and (v_level * (v_level - 1) / 2) > (v_copies - 1) loop
      v_level := v_level - 1;
    end loop;

    begin
      v_date := to_date(coalesce(v_entry ->> 'firstPulledAt', ''), 'YYYY.MM.DD');
    exception when others then
      v_date := current_date;
    end;

    insert into public.ticket_instances (user_id, ticket_id, level, pulled_at)
    values (v_uid, v_ticket_id, v_level, coalesce(v_date, current_date));

    v_spare := greatest(v_copies - 1 - (v_level * (v_level - 1) / 2), 0);
    insert into public.ticket_instances (user_id, ticket_id, level, pulled_at)
    select v_uid, v_ticket_id, 1, coalesce(v_date, current_date)
      from generate_series(1, v_spare);
  end loop;

  insert into public.history (user_id, kind, text, amount, happened_on)
  select v_uid,
         case when e ->> 'kind' = 'deed' then 'deed' else 'pull' end,
         left(coalesce(e ->> 'text', ''), 200),
         least(greatest(coalesce((e ->> 'amount')::int, 0), 0), 99),
         coalesce(public.try_parse_dot_date(e ->> 'date'), current_date)
    from (
      select e, row_number() over () as rn
        from jsonb_array_elements(coalesce(p_payload -> 'history', '[]'::jsonb)) e
    ) s
   where rn <= 500;

  return jsonb_build_object('imported', true);
end;
$$;

-- ---- 구 테이블 정리 ----
drop table if exists public.owned_tickets;

-- ---- 실행 권한 ----
revoke execute on function public.enhance_ticket(uuid, uuid[]) from public, anon;
grant  execute on function public.enhance_ticket(uuid, uuid[]) to authenticated;
