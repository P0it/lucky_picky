-- ════════════════════════════════════════════════════════════════
--  copy_lines — 앱 문구(홈 데일리 문구 / 행운지수 총운·조언)의 서버 소스.
--
--  왜 서버로 빼는가: 밈·유행어는 2~3개월이면 낡는다. 문구가 앱에 하드코딩돼
--  있으면 교체할 때마다 스토어 심사를 기다려야 한다. 서버에 두면 당일 반영.
--
--  동작 규칙 (앱: lib/data/copy_repository.dart):
--   - 앱은 (surface, lang[, grade]) 별로 "오늘 유효한" 행을 받아 그 목록만 쓴다.
--   - 해당 조합의 서버 행이 0개면 앱에 번들된 문구(dart config)로 폴백한다.
--     → 테이블이 비어 있어도 앱은 정상 동작한다. 마이그레이션만 먼저 올려도 됨.
--   - 오프라인이면 마지막으로 받은 캐시를, 캐시도 없으면 번들 문구를 쓴다.
--
--  만료: 밈 문구는 tag='meme' + ends_at 을 반드시 채운다. 지나면 뷰에서 자동
--  제외되므로 사람이 지우러 오지 않아도 낡은 밈이 노출되지 않는다.
--  시즌 안 타는 기본 문구(선행→행운)는 tag='evergreen', ends_at=null.
-- ════════════════════════════════════════════════════════════════

create table if not exists public.copy_lines (
  id          bigint generated always as identity primary key,
  -- 어느 자리에 쓰이는 문구인가
  surface     text     not null check (surface in ('daily_quote', 'fortune_overall', 'fortune_advice')),
  lang        text     not null check (lang in ('ko', 'en', 'ja')),
  -- fortune_overall 전용: 0=흐림 1=보통 2=맑음 3=대박. 나머지 surface는 null.
  grade       smallint          check (grade between 0 and 3),
  text        text     not null check (length(btrim(text)) > 0),
  -- 'meme'은 유행 타는 문구(만료 필수), 'evergreen'은 상시 문구.
  tag         text     not null default 'evergreen' check (tag in ('evergreen', 'meme')),
  starts_at   date,             -- null = 즉시
  ends_at     date,             -- null = 무기한 (meme이면 채울 것)
  active      boolean  not null default true,
  note        text,             -- 출처/유래 메모 (예: '난리자베스 - 2026-02 인스타')
  created_at  timestamptz not null default now(),

  -- fortune_overall 은 grade 필수, 그 외 surface 는 grade 금지.
  constraint copy_lines_grade_matches_surface check (
    (surface = 'fortune_overall' and grade is not null)
    or (surface <> 'fortune_overall' and grade is null)
  ),
  -- 유행어에 만료일을 빠뜨리면 낡은 밈이 영원히 남는다. 스키마로 막는다.
  constraint copy_lines_meme_needs_expiry check (
    tag <> 'meme' or ends_at is not null
  )
);

-- 앱이 실제로 읽는 창구. "오늘 유효한 행"만 보인다.
create or replace view public.copy_lines_active as
select id, surface, lang, grade, text
from public.copy_lines
where active
  and (starts_at is null or starts_at <= current_date)
  and (ends_at   is null or ends_at   >= current_date);

alter table public.copy_lines enable row level security;

-- 읽기는 누구나(익명 로그인 유저 포함). 쓰기 정책은 두지 않는다
-- → SQL 에디터(service_role)로만 문구를 넣고 뺀다. 클라이언트는 절대 못 쓴다.
drop policy if exists "read active copy lines" on public.copy_lines;
create policy "read active copy lines" on public.copy_lines
  for select
  to anon, authenticated
  using (
    active
    and (starts_at is null or starts_at <= current_date)
    and (ends_at   is null or ends_at   >= current_date)
  );

grant select on public.copy_lines_active to anon, authenticated;

-- 조회는 항상 (surface, lang) 단위.
create index if not exists copy_lines_lookup_idx
  on public.copy_lines (surface, lang, grade)
  where active;
