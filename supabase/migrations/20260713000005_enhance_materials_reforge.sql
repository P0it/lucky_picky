-- ════════════════════════════════════════════════════════════════
--  강화 재료 확장 + 재조합
--
--  강화: 재료는 "아무 카드"나 쓸 수 있다(쓸모없는 중복을 태우는 용도).
--        다만 재료의 등급이 성공 확률을 좌우한다.
--          · 대상과 같은 행운권  : +15%p
--          · 상위 등급           : 한 단계당 +10%p
--          · 같은 등급           : ±0
--          · 하위 등급           : 한 단계당 -10%p
--        최종 확률 = clamp(기본확률 + 재료 보정 합, 5, 100).
--
--  재조합: 카드 3장을 갈아 새 카드 1장을 뽑는다. 등급은 재료 중 최고 등급을
--          따라가고, reforge_upgrade_rate(%) 확률로 한 단계 상승한다.
-- ════════════════════════════════════════════════════════════════

insert into public.game_config (key, value) values
  ('reforge_materials',    '3'::jsonb),
  ('reforge_upgrade_rate', '25'::jsonb),
  ('material_mods',        '{"same_ticket": 15, "per_rarity_step": 10}'::jsonb)
on conflict (key) do update set value = excluded.value;

-- 등급 → 순위(낮을수록 하위). rarity_weights.sort_order 를 그대로 쓴다.
create or replace function public.rarity_rank(p_rarity text)
returns int
language sql
stable
security definer
set search_path = ''
as $$
  select sort_order from public.rarity_weights where rarity = p_rarity;
$$;

-- ---- 강화: 대상 1장 + 재료 N장(아무 카드), 등급으로 확률 보정 ----
drop function if exists public.enhance_ticket(uuid, uuid[]);

create function public.enhance_ticket(p_target uuid, p_materials uuid[])
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid        uuid := auth.uid();
  v_max        int;
  v_level      int;
  v_ticket_id  text;
  v_rank       int;
  v_need       int;
  v_have       int;
  v_base       int;
  v_mod        int := 0;
  v_same_bonus int;
  v_step       int;
  v_rate       int;
  v_success    boolean;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  v_max := coalesce(
    (select (value #>> '{}')::int from public.game_config where key = 'max_level'), 5);
  v_same_bonus := coalesce(
    (select (value -> 'same_ticket')::int from public.game_config where key = 'material_mods'), 15);
  v_step := coalesce(
    (select (value -> 'per_rarity_step')::int from public.game_config where key = 'material_mods'), 10);

  select i.level, i.ticket_id, public.rarity_rank(c.rarity)
    into v_level, v_ticket_id, v_rank
    from public.ticket_instances i
    join public.ticket_catalog c on c.id = i.ticket_id
   where i.id = p_target and i.user_id = v_uid
   for update of i;
  if not found then raise exception 'TICKET_NOT_OWNED'; end if;
  if v_level >= v_max then raise exception 'CANNOT_ENHANCE'; end if;

  -- 재료: 본인 소유 카드면 무엇이든. 대상 자신은 제외. 요구 장수와 정확히 일치해야 한다.
  v_need := v_level;
  select count(*) into v_have
    from public.ticket_instances
   where id = any (select distinct unnest(p_materials))
     and id <> p_target
     and user_id = v_uid;
  if v_have <> v_need then raise exception 'CANNOT_ENHANCE'; end if;

  -- 등급 보정 합산 (같은 행운권이면 추가 보너스).
  select coalesce(sum(
           (public.rarity_rank(c.rarity) - v_rank) * v_step
           + case when i.ticket_id = v_ticket_id then v_same_bonus else 0 end
         ), 0)
    into v_mod
    from public.ticket_instances i
    join public.ticket_catalog c on c.id = i.ticket_id
   where i.id = any (select distinct unnest(p_materials))
     and i.id <> p_target
     and i.user_id = v_uid;

  -- 재료 소모 (성공 여부와 무관).
  delete from public.ticket_instances
   where id = any (select distinct unnest(p_materials))
     and id <> p_target
     and user_id = v_uid;

  v_base := coalesce(
    (select (value -> (v_level + 1)::text)::int from public.game_config where key = 'enhance_rates'),
    100);
  v_rate := least(greatest(v_base + v_mod, 5), 100);
  v_success := (random() * 100) < v_rate;

  if v_success then
    update public.ticket_instances set level = v_level + 1 where id = p_target;
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

-- ---- 재조합: 카드 N장 → 새 카드 1장 ----
drop function if exists public.reforge_tickets(uuid[]);

create function public.reforge_tickets(p_materials uuid[])
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid       uuid := auth.uid();
  v_need      int;
  v_have      int;
  v_top       int;    -- 재료 중 최고 등급의 sort_order
  v_up_rate   int;
  v_upgraded  boolean;
  v_rarity    text;
  v_ticket_id text;
  v_instance  uuid;
  v_is_new    boolean;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  v_need := coalesce(
    (select (value #>> '{}')::int from public.game_config where key = 'reforge_materials'), 3);
  v_up_rate := coalesce(
    (select (value #>> '{}')::int from public.game_config where key = 'reforge_upgrade_rate'), 25);

  select count(*), max(public.rarity_rank(c.rarity))
    into v_have, v_top
    from public.ticket_instances i
    join public.ticket_catalog c on c.id = i.ticket_id
   where i.id = any (select distinct unnest(p_materials))
     and i.user_id = v_uid;
  if v_have <> v_need then raise exception 'CANNOT_REFORGE'; end if;

  delete from public.ticket_instances
   where id = any (select distinct unnest(p_materials))
     and user_id = v_uid;

  -- 등급 승급 판정 — 최고 등급이 이미 최상위면 그대로.
  v_upgraded := (random() * 100) < v_up_rate
                and exists (select 1 from public.rarity_weights where sort_order = v_top + 1);
  select rarity into v_rarity
    from public.rarity_weights
   where sort_order = case when v_upgraded then v_top + 1 else v_top end;

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

  return jsonb_build_object(
    'instance_id', v_instance,
    'ticket_id', v_ticket_id,
    'is_new', v_is_new,
    'upgraded', v_upgraded
  );
end;
$$;

-- ---- 실행 권한 ----
revoke execute on function
  public.enhance_ticket(uuid, uuid[]),
  public.reforge_tickets(uuid[])
from public, anon;

grant execute on function
  public.enhance_ticket(uuid, uuid[]),
  public.reforge_tickets(uuid[])
to authenticated;
