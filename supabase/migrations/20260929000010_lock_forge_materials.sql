-- ════════════════════════════════════════════════════════════════
--  강화·재조합 재료 잠금 — 동시 요청으로 카드가 복제되던 구멍 막기
--
--  기존 enhance_ticket / reforge_tickets 는 재료를 잠그지 않고
--  count → delete 순서로 처리했고, 실제로 지워진 행 수도 보지 않았다.
--  같은 재료로 두 요청이 거의 동시에 들어오면(READ COMMITTED):
--    · 둘 다 count 에서 재료 3장을 보고 통과
--    · 먼저 온 쪽이 지우고, 나중 쪽의 delete 는 0행을 지운다
--    · 그래도 나중 쪽이 새 카드를 INSERT → 재료 3장으로 카드 2장
--  강화도 대상이 다르고 재료가 같은 두 요청이면 재료가 두 번 쓰인다.
--
--  고침:
--    1) 개수를 세기 전에 재료 행을 FOR UPDATE 로 잠근다. 나중 요청은
--       먼저 요청의 커밋을 기다렸다가, 이미 지워진 행은 건너뛰고 센다.
--    2) delete 가 실제로 지운 행 수가 요구 장수와 다르면 예외로 롤백한다
--       (잠금이 어떤 이유로 빗나가도 복제는 일어나지 않는다).
--  규칙(확률·장수·보정)은 20260713000005 와 동일하다.
-- ════════════════════════════════════════════════════════════════

create or replace function public.enhance_ticket(p_target uuid, p_materials uuid[])
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
  v_deleted    int;
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

  -- 재료를 먼저 잠근다 — 동시에 같은 재료를 쓰려는 요청은 여기서 기다린다.
  perform 1
     from public.ticket_instances
    where id = any (select distinct unnest(p_materials))
      and id <> p_target
      and user_id = v_uid
    order by id
      for update;

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

  -- 재료 소모 (성공 여부와 무관). 실제로 지운 장수가 모자라면 전부 되돌린다.
  delete from public.ticket_instances
   where id = any (select distinct unnest(p_materials))
     and id <> p_target
     and user_id = v_uid;
  get diagnostics v_deleted = row_count;
  if v_deleted <> v_need then raise exception 'CANNOT_ENHANCE'; end if;

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

create or replace function public.reforge_tickets(p_materials uuid[])
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid       uuid := auth.uid();
  v_need      int;
  v_have      int;
  v_deleted   int;
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

  -- 재료를 먼저 잠근다 — 동시에 같은 재료를 쓰려는 요청은 여기서 기다린다.
  perform 1
     from public.ticket_instances
    where id = any (select distinct unnest(p_materials))
      and user_id = v_uid
    order by id
      for update;

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
  get diagnostics v_deleted = row_count;
  if v_deleted <> v_need then raise exception 'CANNOT_REFORGE'; end if;

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

-- create or replace 는 기존 권한을 유지하지만, 명시해 둔다.
revoke execute on function
  public.enhance_ticket(uuid, uuid[]),
  public.reforge_tickets(uuid[])
from public, anon;

grant execute on function
  public.enhance_ticket(uuid, uuid[]),
  public.reforge_tickets(uuid[])
to authenticated;
