-- ════════════════════════════════════════════════════════════════
--  복구 코드 무차별 대입 방어
--
--  문제: redeem_recovery_code 에 시도 제한이 없었다. 익명 가입은 무료·무제한이라
--        공격자가 코드를 계속 찍어볼 수 있다. 특정 1명을 노리긴 어려워도
--        "아무 계정이나 하나 털기"는 발급된 코드 수 U 에 대해 기대 시도 = 공간/U 다.
--        2쌍(형용사+명사 ×2) 공간은 44^4 ≈ 375만이라 유저 1,000명이면 평균
--        3,700번이면 남의 지갑이 넘어왔다. 넘어가면 원본은 0으로 초기화되므로
--        피해자는 되찾을 방법도 없다.
--
--  대응 세 가지:
--   1) 공간 확대 — 코드를 3쌍으로. 44^6 ≈ 72.6억 (약 2,000배).
--   2) 시도 제한 — 계정당 시간당 10회, IP당 시간당 50회 실패까지.
--      계정 제한만으로는 못 막는다(새 익명 계정을 무한히 만들 수 있다).
--      실질 방어선은 IP 쪽이고, 계정 쪽은 정상 이용자의 오타를 안 막을 만큼 넉넉하다.
--   3) 해시를 md5 → sha256 으로. 기존 행은 code_words 로 재계산해 이관한다.
--
--  구현 주의: raise exception 은 함수 트랜잭션을 통째로 롤백하므로 실패 카운터
--  기록도 같이 사라진다. 그래서 실패는 예외가 아니라 반환값(jsonb.error)으로
--  내보내고, 예외 변환은 앱(SupabaseGameBackend)에서 한다.
-- ════════════════════════════════════════════════════════════════

-- ---- 시도 기록 ----
create table if not exists public.recovery_attempts (
  scope        text        not null,  -- 'user' | 'ip'
  subject      text        not null,  -- user_id 또는 IP
  fails        int         not null default 0,
  window_start timestamptz not null default now(),
  primary key (scope, subject)
);

-- 정책을 두지 않는다 — security definer 함수만 이 테이블에 닿는다.
alter table public.recovery_attempts enable row level security;

-- ---- 코드 해시 (sha256) ----
create or replace function public.hash_recovery_code(p_code text)
returns text
language sql
immutable
set search_path = ''
as $$
  select encode(
    pg_catalog.sha256(pg_catalog.convert_to(public.normalize_recovery_code(p_code), 'UTF8')),
    'hex');
$$;

-- 기존 md5 행(32자)을 sha256(64자)으로 이관. 원문 code_words 가 있어 재계산 가능.
update public.recovery_codes
   set code_hash = public.hash_recovery_code(code_words)
 where length(code_hash) = 32;

-- ---- 실패 카운터 ----
create or replace function public.note_recovery_failure(p_scope text, p_subject text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.recovery_attempts (scope, subject, fails, window_start)
  values (p_scope, p_subject, 1, now())
  on conflict (scope, subject) do update set
    -- 한 시간이 지났으면 창을 새로 연다.
    fails = case when recovery_attempts.window_start > now() - interval '1 hour'
                 then recovery_attempts.fails + 1 else 1 end,
    window_start = case when recovery_attempts.window_start > now() - interval '1 hour'
                 then recovery_attempts.window_start else now() end;
end;
$$;

create or replace function public.recovery_blocked(p_scope text, p_subject text, p_limit int)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select a.fails >= p_limit and a.window_start > now() - interval '1 hour'
       from public.recovery_attempts a
      where a.scope = p_scope and a.subject = p_subject),
    false);
$$;

-- ---- 발급 — 3쌍으로 확대 ----
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
    -- 3쌍 = 44^6 ≈ 72.6억. 외우기는 아직 할 만하고 대입은 사실상 불가능하다.
    v_words :=
      v_adj[1 + floor(random() * array_length(v_adj, 1))::int]  || ' ' ||
      v_noun[1 + floor(random() * array_length(v_noun, 1))::int] || ' ' ||
      v_adj[1 + floor(random() * array_length(v_adj, 1))::int]  || ' ' ||
      v_noun[1 + floor(random() * array_length(v_noun, 1))::int] || ' ' ||
      v_adj[1 + floor(random() * array_length(v_adj, 1))::int]  || ' ' ||
      v_noun[1 + floor(random() * array_length(v_noun, 1))::int];
    v_hash := public.hash_recovery_code(v_words);
    exit when not exists (select 1 from public.recovery_codes where code_hash = v_hash);
    if v_try >= 20 then raise exception 'RECOVERY_GEN_FAILED'; end if;
  end loop;

  insert into public.recovery_codes (code_hash, user_id, code_words)
  values (v_hash, v_uid, v_words);

  return jsonb_build_object('code', v_words);
end;
$$;

-- ---- 사용 — 시도 제한을 걸고, 실패는 예외 대신 반환값으로 ----
create or replace function public.redeem_recovery_code(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_c    uuid := auth.uid();
  v_ip   text;
  v_hash text;
  v_t    uuid;
begin
  if v_c is null then raise exception 'AUTH_REQUIRED'; end if;

  -- PostgREST 가 넘겨주는 요청 헤더. 프록시 체인의 첫 항목이 실제 클라이언트다.
  v_ip := coalesce(
    nullif(btrim(split_part(
      coalesce(current_setting('request.headers', true)::jsonb ->> 'x-forwarded-for', ''),
      ',', 1)), ''),
    'unknown');

  if public.recovery_blocked('user', v_c::text, 10)
     or public.recovery_blocked('ip', v_ip, 50) then
    return jsonb_build_object('moved', false, 'error', 'RECOVERY_RATE_LIMITED');
  end if;

  v_hash := public.hash_recovery_code(p_code);

  select user_id into v_t from public.recovery_codes where code_hash = v_hash;
  if v_t is null then
    perform public.note_recovery_failure('user', v_c::text);
    perform public.note_recovery_failure('ip', v_ip);
    return jsonb_build_object('moved', false, 'error', 'RECOVERY_NOT_FOUND');
  end if;
  -- 자기 코드를 넣은 경우는 실패로 세지 않는다 (대입 시도가 아니다).
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

  -- 성공했으니 이 계정의 실패 기록은 지운다 (IP 창은 그대로 둔다).
  delete from public.recovery_attempts where scope = 'user' and subject = v_c::text;

  return jsonb_build_object('moved', true);
end;
$$;

-- ---- 실행 권한 — 보조 함수는 아무에게도 열지 않는다 ----
revoke execute on function public.hash_recovery_code(text)          from public, anon, authenticated;
revoke execute on function public.note_recovery_failure(text, text) from public, anon, authenticated;
revoke execute on function public.recovery_blocked(text, text, int) from public, anon, authenticated;
revoke execute on function public.issue_recovery_code()             from public, anon;
grant  execute on function public.issue_recovery_code()             to authenticated;
revoke execute on function public.redeem_recovery_code(text)        from public, anon;
grant  execute on function public.redeem_recovery_code(text)        to authenticated;
