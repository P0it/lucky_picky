-- ════════════════════════════════════════════════════════════════
--  복구 코드 — 기기가 바뀌어도 자산을 이어간다
--
--  익명 로그인은 세션 토큰을 기기(웹은 localStorage)에 둔다. 다른 브라우저·
--  기기·시크릿탭에서 열면 새 익명 계정이 되어 자산이 날아간 것처럼 보인다.
--
--  해결: 계정마다 외우기 쉬운 "복구 코드"를 발급해 둔다. 새 환경에서 그 코드를
--        넣으면 옛 계정의 자산(프로필 재화·카드·커스텀·기록)을 지금 세션으로
--        옮긴다. 로그인/세션은 건드리지 않는다 — 순수 서버 권위 RPC 이관이다.
--
--  코드는 "형용사 + 뜬금없는 개념" 조합이다(예: "명란한 참치마요 오붓한 스파게티").
--  외우기 쉽고 브랜드 톤에도 맞는다. 검증은 해시로만, 표시는 원문으로 한다.
-- ════════════════════════════════════════════════════════════════

-- ---- 코드 저장 (해시로 검증, 원문은 재표시용) ----
create table if not exists public.recovery_codes (
  code_hash  text primary key,
  user_id    uuid not null unique references auth.users (id) on delete cascade,
  code_words text not null,
  created_at timestamptz not null default now()
);

alter table public.recovery_codes enable row level security;

drop policy if exists "read own recovery code" on public.recovery_codes;
create policy "read own recovery code" on public.recovery_codes
  for select to authenticated using (user_id = (select auth.uid()));

-- ---- 코드 정규화 — 공백·구분자·대소문자를 지우고 글자만 남긴다 ----
--  발급과 입력이 같은 해시로 떨어지게 하는 유일한 규칙. 앱의 정규화와 일치해야 한다.
create or replace function public.normalize_recovery_code(p_code text)
returns text
language sql
immutable
set search_path = ''
as $$
  select lower(regexp_replace(coalesce(p_code, ''), '[^[:alnum:]가-힣]', '', 'g'));
$$;

-- ---- 복구 코드 발급 (계정당 1개, 재사용) ----
create or replace function public.issue_recovery_code()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid  uuid := auth.uid();
  v_adj  text[] := array[
    '느긋한','억울한','수줍은','우아한','엉뚱한','새침한','도도한','나른한','씩씩한','얼큰한',
    '담백한','촉촉한','바삭한','소심한','대담한','은은한','발랄한','몽글한','뾰족한','폭신한',
    '매콤한','달콤한','시원한','뜨끈한','차분한','화끈한','늠름한','깜찍한','진지한','태연한',
    '느슨한','무던한','푸근한','개운한','촐랑한','진득한','명란한','오붓한','시큰둥한','수상한',
    '멀쩡한','괴상한','천진한','아득한'];
  v_noun text[] := array[
    '참치마요','스파게티','형광등','소화전','고등어','세탁기','코뿔소','우체통','볼링공','지하철',
    '다시마','붕어빵','계산기','손톱깎이','두루마리','청국장','물티슈','콘센트','냉장고','고무장갑',
    '주전자','낙타','해파리','도토리','실내화','국자','빗자루','프라이팬','옷걸이','자물쇠',
    '컵라면','목도리','선풍기','가로등','방석','젓가락','반창고','삼각김밥','두더지','나침반',
    '멸치','손수레','확성기','도장'];
  v_words text;
  v_hash  text;
  v_try   int := 0;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  -- 이미 발급했으면 같은 코드를 그대로 돌려준다 (고정·재사용).
  select code_words into v_words from public.recovery_codes where user_id = v_uid;
  if v_words is not null then
    return jsonb_build_object('code', v_words);
  end if;

  loop
    v_try := v_try + 1;
    v_words :=
      v_adj[1 + floor(random() * array_length(v_adj, 1))::int]  || ' ' ||
      v_noun[1 + floor(random() * array_length(v_noun, 1))::int] || ' ' ||
      v_adj[1 + floor(random() * array_length(v_adj, 1))::int]  || ' ' ||
      v_noun[1 + floor(random() * array_length(v_noun, 1))::int];
    v_hash := md5(public.normalize_recovery_code(v_words));
    exit when not exists (select 1 from public.recovery_codes where code_hash = v_hash);
    if v_try >= 20 then raise exception 'RECOVERY_GEN_FAILED'; end if;
  end loop;

  insert into public.recovery_codes (code_hash, user_id, code_words)
  values (v_hash, v_uid, v_words);

  return jsonb_build_object('code', v_words);
end;
$$;

-- ---- 복구 코드 사용 — 코드가 가리키는 계정(T)의 자산을 현재 계정(C)으로 이관 ----
create or replace function public.redeem_recovery_code(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_c    uuid := auth.uid();
  v_hash text;
  v_t    uuid;
begin
  if v_c is null then raise exception 'AUTH_REQUIRED'; end if;
  v_hash := md5(public.normalize_recovery_code(p_code));

  select user_id into v_t from public.recovery_codes where code_hash = v_hash;
  if v_t is null then raise exception 'RECOVERY_NOT_FOUND'; end if;
  if v_t = v_c then return jsonb_build_object('moved', false); end if;

  -- 대상(T)의 프로필 재화·통계를 현재(C)로 덮어쓴다.
  update public.profiles c set
      leaves            = t.leaves,
      clovers           = t.clovers,
      coins             = t.coins,
      stat_leaves       = t.stat_leaves,
      stat_clovers      = t.stat_clovers,
      stat_pulls        = t.stat_pulls,
      ad_coins_today    = t.ad_coins_today,
      last_ad_coin_date = t.last_ad_coin_date,
      updated_at        = now()
    from public.profiles t
   where c.user_id = v_c and t.user_id = v_t;

  -- 카드·커스텀·기록의 소유권을 C로 옮긴다.
  update public.ticket_instances set user_id = v_c where user_id = v_t;
  update public.custom_tickets    set user_id = v_c where user_id = v_t;
  update public.history           set user_id = v_c where user_id = v_t;

  -- 비워진 원본(T)은 초기화한다 — 옛 기기로 다시 들어와도 빈 계정으로 보이게.
  update public.profiles set
      leaves = 0, clovers = 0, coins = 0,
      stat_leaves = 0, stat_clovers = 0, stat_pulls = 0,
      ad_coins_today = 0, last_ad_coin_date = null,
      updated_at = now()
    where user_id = v_t;

  -- 코드는 늘 "자산이 있는 곳"을 가리킨다: C 자신의 코드가 있었다면 버리고,
  -- 입력한 코드를 C로 재지정한다. 그래서 다음엔 이 코드로 지금 기기를 되찾는다.
  delete from public.recovery_codes where user_id = v_c;
  update public.recovery_codes set user_id = v_c where code_hash = v_hash;

  return jsonb_build_object('moved', true);
end;
$$;

-- ---- 실행 권한 — 로그인(익명 포함) 유저만 ----
revoke execute on function public.issue_recovery_code()        from public, anon;
grant  execute on function public.issue_recovery_code()        to authenticated;
revoke execute on function public.redeem_recovery_code(text)   from public, anon;
grant  execute on function public.redeem_recovery_code(text)   to authenticated;
revoke execute on function public.normalize_recovery_code(text) from public;
