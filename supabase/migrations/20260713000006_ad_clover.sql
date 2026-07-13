-- ════════════════════════════════════════════════════════════════
--  클로버 = 뽑기 코인 (화폐 일원화)
--
--  이전: 뽑기에 두 경로가 있었다.
--        · 클로버 1개 소모
--        · "무료 뽑기" — 광고를 보면 클로버 없이 하루 3회 그냥 돌아감
--        광고를 보면 뽑기가 곧장 실행돼, 클로버가 코인이라는 모델과 어긋났다.
--
--  이제: 뽑기는 언제나 클로버 1개를 쓴다. 광고는 뽑기를 실행하는 대신
--        클로버를 1개 지급한다(하루 ad_clovers_per_day 회). 사용자는 채워진
--        클로버로 직접 머신을 돌린다.
--
--  선행으로 만든 클로버(stat_clovers)와 구분하려고 광고 클로버는 통계에
--  적립하지 않는다 — "선행으로 운을 만든다"는 정체성은 통계에 남는다.
-- ════════════════════════════════════════════════════════════════

-- 하루 무료 뽑기 카운터 → 하루 광고 클로버 카운터로 재정의.
alter table public.profiles
  rename column free_pulls_used_today to ad_clovers_today;
alter table public.profiles
  rename column last_free_pull_date to last_ad_clover_date;

insert into public.game_config (key, value) values
  ('ad_clovers_per_day', '3'::jsonb)
on conflict (key) do update set value = excluded.value;

delete from public.game_config where key = 'free_pulls_per_day';

-- ---- 뽑기: 언제나 클로버 1개 ----
drop function if exists public.pull_gacha(boolean);
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
  if v_profile.clovers < 1 then raise exception 'NO_CLOVERS'; end if;

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
     set clovers = clovers - 1,
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

-- ---- 광고 보상: 클로버 1개 지급 (하루 한도) ----
create or replace function public.grant_ad_clover()
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
  v_clovers int;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  select * into v_profile from public.profiles where user_id = v_uid for update;
  if not found then raise exception 'AUTH_REQUIRED'; end if;

  v_limit := coalesce(
    (select (value #>> '{}')::int from public.game_config where key = 'ad_clovers_per_day'), 3);
  v_used := case
    when v_profile.last_ad_clover_date = current_date then v_profile.ad_clovers_today
    else 0
  end;
  if v_used >= v_limit then raise exception 'NO_AD_CLOVERS'; end if;

  update public.profiles
     set clovers = clovers + 1,
         ad_clovers_today = v_used + 1,
         last_ad_clover_date = current_date,
         updated_at = now()
   where user_id = v_uid
   returning clovers into v_clovers;

  return jsonb_build_object(
    'clovers', v_clovers,
    'ad_clovers_today', v_used + 1
  );
end;
$$;

-- ---- 실행 권한 ----
revoke execute on function
  public.pull_gacha(),
  public.grant_ad_clover()
from public, anon;

grant execute on function
  public.pull_gacha(),
  public.grant_ad_clover()
to authenticated;
