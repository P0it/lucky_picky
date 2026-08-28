-- ════════════════════════════════════════════════════════════════
--  하루 무료 코인 1개
--
--  문제: 코인은 광고로만 얻는다. 그래서 신규 이용자가 뽑기 탭에 처음 들어오면
--        카드를 한 장이라도 보기 전에 광고부터 봐야 했다. 수집의 재미를 알기도
--        전에 톨게이트가 서 있는 셈이고, 첫인상과 D1 리텐션에 그대로 걸린다.
--
--  바꾼 것: 하루 한 번 코인 1개를 그냥 준다. 순서가 뒤집힌다 —
--        먼저 뽑아보고 → 카드가 나오고 → 도감에 빈칸이 보이고 → 그때
--        "한 번 더?"가 뜬다. 벽이 아니라 초대가 된다.
--
--  뽑기 로직(pull_gacha)은 건드리지 않는다. 코인만 주면 기존 경제가 그대로
--  처리한다 — 무료분이든 광고분이든 코인은 코인이다.
--
--  참고: 초기 스키마에 free_pulls_used_today / last_free_pull_date 가 있었으나
--  마이그레이션 6·8 을 거치며 광고 카운터로 이름이 바뀌어 사라졌다. 되살리는
--  셈이지만, 같은 이름을 다시 쓰면 그 히스토리와 헷갈려 새 이름을 쓴다.
-- ════════════════════════════════════════════════════════════════

alter table public.profiles
  add column if not exists last_free_coin_date date;

insert into public.game_config (key, value) values
  ('free_coins_per_day', '1'::jsonb)
on conflict (key) do update set value = excluded.value;

-- ---- 오늘 몫의 무료 코인을 받는다 (이미 받았으면 조용히 아무 일도 안 한다) ----
--  앱 시작마다 불린다. 예외로 실패시키지 않는 이유: 이건 사용자가 요청한
--  동작이 아니라 부트스트랩의 곁가지라, 여기서 던지면 이미 받은 날에는 매번
--  부트스트랩이 실패한다. '받았는지'를 반환값으로 알려준다.
create or replace function public.claim_daily_coin()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := auth.uid();
  v_profile public.profiles;
  v_amount  int;
  v_coins   int;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  select * into v_profile from public.profiles where user_id = v_uid for update;
  if not found then raise exception 'AUTH_REQUIRED'; end if;

  if v_profile.last_free_coin_date = current_date then
    return jsonb_build_object('claimed', false, 'coins', v_profile.coins);
  end if;

  v_amount := coalesce(
    (select (value #>> '{}')::int from public.game_config
      where key = 'free_coins_per_day'), 1);

  update public.profiles
     set coins = coins + v_amount,
         last_free_coin_date = current_date,
         updated_at = now()
   where user_id = v_uid
   returning coins into v_coins;

  return jsonb_build_object('claimed', true, 'coins', v_coins);
end;
$$;

-- ---- 실행 권한 — 로그인(익명 포함) 유저만 ----
revoke execute on function public.claim_daily_coin() from public, anon;
grant  execute on function public.claim_daily_coin() to authenticated;
