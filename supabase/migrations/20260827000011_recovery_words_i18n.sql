-- ════════════════════════════════════════════════════════════════
--  복구 코드 다국어
--
--  문제: 코드 단어가 한국어 전용이었다. 일본어·영어권 이용자는 자기 복구 코드를
--        입력할 IME 조차 없어서, 기기를 바꾸면 자산을 되찾을 방법이 사라진다.
--        정규화 규칙도 '[^[:alnum:]가-힣]' 허용 방식이라 가나·한자가 통째로
--        지워졌다 — 일본어 코드는 정규화하면 빈 문자열이 됐다.
--
--  바꾼 것:
--   1) 단어를 테이블(recovery_words)로 빼고 ko/en/ja 를 채운다. 언어를 늘릴 때
--      함수를 안 건드려도 된다.
--   2) 발급 시 이용자의 표시 언어를 받아 그 언어 단어로 만든다. 코드 자체는
--      언어와 무관하게 해시로만 대조하므로, 나중에 언어를 바꿔도 그대로 쓴다.
--   3) 정규화를 "허용 목록"에서 "공백·구두점 제거"로 뒤집는다. 어떤 문자 체계든
--      동일하게 동작한다. 기존 행은 code_words 로 해시를 재계산해 이관한다.
--      앱의 normalizeRecoveryCode 도 같은 규칙으로 맞춰야 한다.
-- ════════════════════════════════════════════════════════════════

-- ---- 언어별 단어 ----
create table if not exists public.recovery_words (
  lang text not null,
  kind text not null check (kind in ('adj', 'noun')),
  word text not null,
  primary key (lang, kind, word)
);

alter table public.recovery_words enable row level security;
-- 정책 없음 — security definer 함수만 읽는다. 단어 목록이 공개되면 대입 공간을
-- 좁혀 주는 셈이라 클라이언트에는 열지 않는다.

insert into public.recovery_words (lang, kind, word)
select 'ko', 'adj', w from unnest(array[
  '느긋한','억울한','수줍은','우아한','엉뚱한','새침한','도도한','나른한','씩씩한','얼큰한',
  '담백한','촉촉한','바삭한','소심한','대담한','은은한','발랄한','몽글한','뾰족한','폭신한',
  '매콤한','달콤한','시원한','뜨끈한','차분한','화끈한','늠름한','깜찍한','진지한','태연한',
  '느슨한','무던한','푸근한','개운한','촐랑한','진득한','명란한','오붓한','시큰둥한','수상한',
  '멀쩡한','괴상한','천진한','아득한']) w
on conflict do nothing;

insert into public.recovery_words (lang, kind, word)
select 'ko', 'noun', w from unnest(array[
  '참치마요','스파게티','형광등','소화전','고등어','세탁기','코뿔소','우체통','볼링공','지하철',
  '다시마','붕어빵','계산기','손톱깎이','두루마리','청국장','물티슈','콘센트','냉장고','고무장갑',
  '주전자','낙타','해파리','도토리','실내화','국자','빗자루','프라이팬','옷걸이','자물쇠',
  '컵라면','목도리','선풍기','가로등','방석','젓가락','반창고','삼각김밥','두더지','나침반',
  '멸치','손수레','확성기','도장']) w
on conflict do nothing;

insert into public.recovery_words (lang, kind, word)
select 'en', 'adj', w from unnest(array[
  'brave','sleepy','jolly','crispy','fluffy','grumpy','shiny','mellow','quirky','snappy',
  'breezy','cozy','dizzy','feisty','gentle','humble','itchy','jazzy','keen','lucky',
  'merry','nifty','odd','plucky','quiet','rusty','silly','tidy','upbeat','velvety',
  'witty','zesty','bouncy','clumsy','dapper','eager','fuzzy','glossy','hearty','idle',
  'lanky','misty','nimble','polite']) w
on conflict do nothing;

insert into public.recovery_words (lang, kind, word)
select 'en', 'noun', w from unnest(array[
  'tunafish','spaghetti','lightbulb','hydrant','mackerel','washer','rhino','mailbox','bowlingball','subway',
  'seaweed','fishbread','calculator','nailclipper','scroll','stewpot','wipes','outlet','fridge','rubberglove',
  'kettle','camel','jellyfish','acorn','slipper','ladle','broom','frypan','hanger','padlock',
  'cupnoodle','scarf','fan','streetlamp','cushion','chopstick','bandaid','riceball','mole','compass',
  'anchovy','handcart','megaphone','stamp']) w
on conflict do nothing;

insert into public.recovery_words (lang, kind, word)
select 'ja', 'adj', w from unnest(array[
  'のんきな','しずかな','はでな','すなおな','へんな','げんきな','ゆかいな','まじめな','ひまな','ふしぎな',
  'あまい','からい','しょっぱい','あつい','つめたい','ねむい','やさしい','きびしい','まるい','ほそい',
  'おおきい','ちいさい','あかるい','くらい','はやい','おそい','かるい','おもい','あたらしい','ふるい',
  'うれしい','かなしい','さびしい','たのしい','すずしい','あたたかい','かわいい','こわい','めずらしい','あやしい',
  'のどかな','ゆるやかな','にぎやかな','おだやかな']) w
on conflict do nothing;

insert into public.recovery_words (lang, kind, word)
select 'ja', 'noun', w from unnest(array[
  'ツナマヨ','スパゲティ','けいこうとう','しょうかせん','さば','せんたくき','サイ','ポスト','ボウリング','ちかてつ',
  'こんぶ','たいやき','でんたく','つめきり','まきもの','なべ','ウェットティッシュ','コンセント','れいぞうこ','ゴムてぶくろ',
  'やかん','ラクダ','クラゲ','どんぐり','スリッパ','おたま','ほうき','フライパン','ハンガー','なんきんじょう',
  'カップめん','マフラー','せんぷうき','がいとう','ざぶとん','はし','ばんそうこう','おにぎり','モグラ','コンパス',
  'にぼし','リヤカー','メガホン','はんこ']) w
on conflict do nothing;

-- ---- 정규화 — 허용 목록이 아니라 공백·구두점 제거로 ----
--  가나·한자·라틴 어디에도 같은 규칙이 먹는다. 앱의 normalizeRecoveryCode 와
--  반드시 같은 결과를 내야 한다(공백/구두점 제거 + 소문자).
create or replace function public.normalize_recovery_code(p_code text)
returns text
language sql
immutable
set search_path = ''
as $$
  select regexp_replace(lower(coalesce(p_code, '')), '[[:space:][:punct:]]', '', 'g');
$$;

-- 규칙이 바뀌었으니 기존 코드의 해시를 원문에서 다시 계산한다.
update public.recovery_codes
   set code_hash = public.hash_recovery_code(code_words);

-- ---- 발급 — 표시 언어를 받아 그 언어 단어로 ----
drop function if exists public.issue_recovery_code();

create or replace function public.issue_recovery_code(p_lang text default 'en')
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid   uuid := auth.uid();
  v_lang  text;
  v_adj   text[];
  v_noun  text[];
  v_glue  text;   -- 형용사와 명사 사이 (일본어는 붙여 쓴다)
  v_words text;
  v_hash  text;
  v_try   int := 0;
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;

  -- 이미 발급했으면 같은 코드를 그대로 돌려준다. 나중에 앱 언어를 바꿔도
  -- 코드는 처음 발급된 언어 그대로다 — 이미 적어둔 코드가 바뀌면 안 된다.
  select code_words into v_words from public.recovery_codes where user_id = v_uid;
  if v_words is not null then
    return jsonb_build_object('code', v_words);
  end if;

  -- 모르는 언어는 영어로 (읽고 입력할 수 있는 것이 한국어보다 넓다).
  v_lang := coalesce(
    (select w.lang from public.recovery_words w where w.lang = p_lang limit 1), 'en');
  v_glue := case when v_lang = 'ja' then '' else ' ' end;

  select array_agg(word) into v_adj
    from public.recovery_words where lang = v_lang and kind = 'adj';
  select array_agg(word) into v_noun
    from public.recovery_words where lang = v_lang and kind = 'noun';

  loop
    v_try := v_try + 1;
    -- 3쌍 = 44^6 ≈ 72.6억.
    v_words := (
      select string_agg(
        v_adj[1 + floor(random() * array_length(v_adj, 1))::int] || v_glue ||
        v_noun[1 + floor(random() * array_length(v_noun, 1))::int],
        ' ')
      from generate_series(1, 3));
    v_hash := public.hash_recovery_code(v_words);
    exit when not exists (select 1 from public.recovery_codes where code_hash = v_hash);
    if v_try >= 20 then raise exception 'RECOVERY_GEN_FAILED'; end if;
  end loop;

  insert into public.recovery_codes (code_hash, user_id, code_words)
  values (v_hash, v_uid, v_words);

  return jsonb_build_object('code', v_words);
end;
$$;

-- ---- 실행 권한 ----
revoke execute on function public.issue_recovery_code(text) from public, anon;
grant  execute on function public.issue_recovery_code(text) to authenticated;
