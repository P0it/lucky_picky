-- ════════════════════════════════════════════════════════════════
--  게임 RPC — 앱의 모든 상태 변경은 이 함수들을 통해서만 일어난다.
--  (lib/state/app_controller.dart 의 mutation 5개와 1:1 대응)
--
--  에러는 raise exception 의 메시지 코드로 전달한다:
--    AUTH_REQUIRED / INVALID_DEED / NO_CLOVER_READY / NO_CLOVERS /
--    NO_FREE_PULLS / TICKET_NOT_OWNED / CANNOT_ENHANCE / ALREADY_IMPORTED
-- ════════════════════════════════════════════════════════════════

-- ---- 선행 기록: 잎 +1 ----
create function public.record_deed(p_text text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid   uuid := auth.uid();
  v_text  text := btrim(coalesce(p_text, ''));
  v_leaves int;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if v_text = '' or char_length(v_text) > 200 then raise exception 'INVALID_DEED'; end if;

  update public.profiles
     set leaves = leaves + 1,
         stat_leaves = stat_leaves + 1,
         updated_at = now()
   where user_id = v_uid
   returning leaves into v_leaves;
  if not found then raise exception 'AUTH_REQUIRED'; end if;

  insert into public.history (user_id, kind, text, amount)
  values (v_uid, 'deed', v_text, 1);

  return jsonb_build_object('leaves', v_leaves, 'clover_completed', v_leaves >= 4);
end;
$$;

-- ---- 클로버 완성: 잎 4개 소모 → 클로버 +1 ----
-- (클라이언트는 축하 연출/광고 후 호출. 4개 초과분 잎은 보존한다.)
create function public.finish_clover()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_leaves int;
  v_clovers int;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  update public.profiles
     set leaves = leaves - 4,
         clovers = clovers + 1,
         stat_clovers = stat_clovers + 1,
         updated_at = now()
   where user_id = v_uid and leaves >= 4
   returning leaves, clovers into v_leaves, v_clovers;
  if not found then raise exception 'NO_CLOVER_READY'; end if;

  return jsonb_build_object('leaves', v_leaves, 'clovers', v_clovers);
end;
$$;

-- ---- 가챠 1회 ----
-- p_free=false: 클로버 1개 차감 / p_free=true: 오늘 무료(광고) 한도 1 소모.
-- 등급을 가중치로 뽑고 등급 내 균등 추첨 (drawTicket 과 동일한 규칙, 단 서버에서).
create function public.pull_gacha(p_free boolean default false)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid        uuid := auth.uid();
  v_profile    public.profiles%rowtype;
  v_free_limit int;
  v_free_used  int;
  v_total      int;
  v_roll       int;
  v_rarity     text;
  v_ticket_id  text;
  v_copies     int;
  v_level      int;
  v_is_new     boolean;
  rec          record;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  select * into v_profile from public.profiles
   where user_id = v_uid for update;
  if not found then raise exception 'AUTH_REQUIRED'; end if;

  -- 재화/한도 검증. 무료 뽑기 기준일은 서버(UTC) 날짜.
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

  -- 등급 추첨 (가중치 테이블 기반 — 값 변경만으로 확률 튜닝 가능).
  select sum(weight) into v_total from public.rarity_weights;
  v_roll := floor(random() * v_total)::int;
  for rec in
    select rarity, weight from public.rarity_weights order by sort_order
  loop
    if v_roll < rec.weight then
      v_rarity := rec.rarity;
      exit;
    end if;
    v_roll := v_roll - rec.weight;
  end loop;

  -- 등급 내 균등 추첨.
  select id into v_ticket_id
    from public.ticket_catalog
   where rarity = v_rarity and active
   order by random()
   limit 1;

  -- 도감 반영: 신규 등록 or 중복 카운트.
  insert into public.owned_tickets (user_id, ticket_id)
  values (v_uid, v_ticket_id)
  on conflict (user_id, ticket_id)
  do update set copies = public.owned_tickets.copies + 1
  returning copies, level, (xmax = 0) into v_copies, v_level, v_is_new;

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
    'ticket_id', v_ticket_id,
    'is_new', v_is_new,
    'copies', v_copies,
    'level', v_level,
    'free', p_free
  );
end;
$$;

-- ---- 행운권 강화: 여분 중복 소모 → 레벨 +1 ----
-- Lv.L → L+1 에 중복 L장. 누적 소모 = L(L-1)/2 (OwnedTicket 과 동일 공식).
create function public.enhance_ticket(p_ticket_id text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid   uuid := auth.uid();
  v_max   int;
  v_copies int;
  v_level int;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  v_max := coalesce(
    (select (value #>> '{}')::int from public.game_config where key = 'max_level'), 5);

  select copies, level into v_copies, v_level
    from public.owned_tickets
   where user_id = v_uid and ticket_id = p_ticket_id
   for update;
  if not found then raise exception 'TICKET_NOT_OWNED'; end if;

  -- 여분 = copies - 1(첫 획득) - 지금까지 소모분. 다음 레벨 요구량 = 현재 레벨.
  if v_level >= v_max
     or (v_copies - 1 - (v_level * (v_level - 1) / 2)) < v_level then
    raise exception 'CANNOT_ENHANCE';
  end if;

  update public.owned_tickets
     set level = v_level + 1
   where user_id = v_uid and ticket_id = p_ticket_id;

  return jsonb_build_object(
    'ticket_id', p_ticket_id,
    'copies', v_copies,
    'level', v_level + 1
  );
end;
$$;

-- ---- 로컬(shared_preferences) 데이터 1회 이관 ----
-- payload = 앱의 AppState.toJson() 원본. 프로필당 1회만 허용하고 상한 캡을 둔다.
create function public.import_local_state(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid  uuid := auth.uid();
  v_max  int;
  v_entry jsonb;
  v_date date;
  v_ticket_id text;
  v_copies int;
  v_level int;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  v_max := coalesce(
    (select (value #>> '{}')::int from public.game_config where key = 'max_level'), 5);

  -- 1회 가드 (동시 호출 방지를 위해 행 잠금 후 플래그 확인).
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

  -- 도감: 카탈로그에 존재하는 id만, 상한 캡 적용.
  for v_entry in select * from jsonb_array_elements(coalesce(p_payload -> 'tickets', '[]'::jsonb))
  loop
    v_ticket_id := v_entry ->> 'ticketId';
    if not exists (select 1 from public.ticket_catalog where id = v_ticket_id) then
      continue;
    end if;
    v_copies := least(greatest(coalesce((v_entry ->> 'copies')::int, 1), 1), 999);
    v_level  := least(greatest(coalesce((v_entry ->> 'level')::int, 1), 1), v_max);
    -- 레벨이 보유 중복으로 도달 가능한 수준을 넘으면 낮춘다.
    while v_level > 1 and (v_level * (v_level - 1) / 2) > (v_copies - 1) loop
      v_level := v_level - 1;
    end loop;
    begin
      v_date := to_date(coalesce(v_entry ->> 'firstPulledAt', ''), 'YYYY.MM.DD');
    exception when others then
      v_date := current_date;
    end;
    insert into public.owned_tickets (user_id, ticket_id, copies, level, first_pulled_at)
    values (v_uid, v_ticket_id, v_copies, v_level, coalesce(v_date, current_date))
    on conflict (user_id, ticket_id) do nothing;
  end loop;

  -- 기록: 최근 500건까지 일괄 INSERT (표시 정렬은 happened_on/created_at 기준).
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

-- 'YYYY.MM.DD' 문자열을 date 로 — 실패 시 null.
create function public.try_parse_dot_date(p text)
returns date
language plpgsql
immutable
set search_path = ''
as $$
begin
  return to_date(p, 'YYYY.MM.DD');
exception when others then
  return null;
end;
$$;

-- ---- 실행 권한: 로그인(익명 포함) 유저만 ----
revoke execute on function
  public.record_deed(text),
  public.finish_clover(),
  public.pull_gacha(boolean),
  public.enhance_ticket(text),
  public.import_local_state(jsonb)
from public, anon;

grant execute on function
  public.record_deed(text),
  public.finish_clover(),
  public.pull_gacha(boolean),
  public.enhance_ticket(text),
  public.import_local_state(jsonb)
to authenticated;
