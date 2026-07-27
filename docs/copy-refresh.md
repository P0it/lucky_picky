# 문구 갱신 (로컬 편집 → PR → 서버 자동 동기화)

문구를 바꿀 때마다 스토어 심사를 기다릴 수는 없다. 그래서 이렇게 나눴다.

- **원본(source of truth)은 dart 파일** — `lib/config/daily_quotes.dart`, `lib/config/fortune_pool.dart`.
  편집·리뷰·이력이 전부 git에 남고, IDE에서 편하게 고칠 수 있다.
- **Supabase `copy_lines` 는 배달 경로일 뿐** — main 에 머지되면 GitHub Actions 가 서버로 미러링하고,
  유저는 **앱 업데이트 없이** 새 문구를 본다. 서버가 비었거나 장애면 앱은 번들 문구로 폴백한다.

```
문구 수정 (dart)  →  PR 리뷰·머지  →  Actions 가 Supabase 동기화  →  유저에게 즉시 반영
```

## 사장님이 하는 일

**직접 고칠 때**: dart 파일에서 문구를 고치고 커밋 → main 에 머지. 끝. (배포 불필요)

**매달 1일 (리서치 에이전트)**:
1. 에이전트가 최신 밈을 조사해 **dart 문구 리스트를 수정하는 PR** 을 연다. 각 문구 옆에 `// 밈 이름 - 출처/시점` 주석이 붙는다.
2. PR에서 문구를 읽고, 고칠 건 고치고, 뺄 건 빼고 **머지**한다. (PR 본문에 신규 밈 목록·출처·삭제 후보가 정리돼 있다.)
3. 머지되면 Actions 가 알아서 서버에 반영한다.

### 유행 지난 문구

자동 만료는 걸지 않는다 — 어차피 문구는 사람의 검증이 필요하니, **PR에서 눈으로 보고 빼는 게 맞다.**
에이전트가 매달 "삭제 후보"(6개월 이상 지난 밈, 출처가 한물갔다고 명시한 밈)를 PR에 적어 올리니,
그때 판단해서 지우면 된다. dart 에서 지운 문구는 다음 동기화 때 서버에서도 사라진다.

## 서버 동기화

`tool/sync_copy.dart` 가 dart 문구 목록을 읽어 `copy_lines` 를 **통째로 교체**한다
(부분 갱신을 하면 dart 에서 지운 문구가 서버에 남아 계속 노출된다).

- 자동: main 에 문구 파일이 머지되면 [`.github/workflows/sync-copy.yml`](../.github/workflows/sync-copy.yml) 실행
- 수동: `SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... dart run tool/sync_copy.dart`
- 확인만: `dart run tool/sync_copy.dart --dry-run` (서버에 쓰지 않고 반영될 줄 수만 출력)

리포 시크릿 두 개가 필요하다 (Settings → Secrets and variables → Actions):
`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`. service_role 키는 절대 앱에 넣지 않는다.

> `tool/sync_copy.dart` 는 Flutter 없이 도는 순수 dart다. 그래서 `lib/config/*.dart` 는
> `dart:ui`(Color 등)에 의존하면 안 된다 — 행운의 색이 `Color` 대신 ARGB 정수인 이유.

## 리서치 에이전트가 하는 일

> ⚠️ **2026-07-27 이후 이 섹션은 보류 상태다.** 아래 파이프라인은 "밈은 2~3개월이면
> 낡으니 매달 새로 조사한다"는 전제로 만들었는데, 문구에서 밈을 뺐으므로 전제가
> 사라졌다. 담백한 톤은 유행을 타지 않아 매달 갱신할 이유가 없다.
> 크롤링 소스·워크플로는 남겨 두되, 월간 리서치를 돌릴지는 다시 판단할 것.

무료 공개 소스만 크롤링한다:

- 고구마팜 <https://gogumafarm.kr/category/trends/> (월간 밈 모음)
- HSAD 이달의 트렌드 밈집 <https://blog.hsad.co.kr/category/트렌드/이달의%20트렌드%20밈집>
- 소마코 <https://somako.co.kr/>
- 위픽 밈 아카이브 <https://letter.wepick.kr/>
- 나무위키 「밈(인터넷 용어)/시기별」

**캐릿(careet.net)은 자동 크롤링하지 않는다.** 20대 트렌드 소스로는 제일 정확하지만 유료 회원제라,
로그인 세션을 흉내 내 긁어오는 건 이용약관 위반이고 유료 콘텐츠 무단 복제 문제가 된다.
대신 리서치 보고서에 **"캐릿 확인 필요"** 섹션을 둔다 — 사장님이 회원으로 읽고 본문을 붙여넣어 주면
그 내용으로 문구를 다시 뽑는다.

## 문구 톤 규칙 (에이전트·사람 공통)

### 공통

- 주 타깃 **2030 여성**. "밤티(못생긴)" 문구는 UX를 해친다.
- 어미는 **해요체** ("~예요 / ~해요 / ~하세요"). `~하셈 / ~임 / ~함 / ~됨` 금지 — 가벼워 보인다.
- 앱 정체성은 **선행앱**: "운은 기다리는 게 아니라 선행으로 만드는 것". 순수 가챠·확률 자조 드립 금지.
- "그러니 착하게 살자"로 **설명하는 꼬리를 붙이지 않는다** — 오글거린다. 메시지는 암시로.

### 밈 금지 — 전 surface 공통 (2026-07-27 개편)

무한도전 밈·난리자베스·럭키비키 같은 유행어 톤을 **전면 철회**했다. "개그 욕심"으로
읽힌다는 판단. 되돌리지 말 것.

- **밈·유행어를 쓰지 않는다.** 담백한 속담·관용구 결 + 살짝 미는 넛지.
- 짧은 완결형 문장. 홈 헤드라인은 21px 기준 **2줄이 한계**, 3줄은 넘기지 않는다.
- 넛지는 반 발짝만 — 훈수·명령조로 넘어가지 않게 한다.
- **손익 계산 프레임 금지**("손해 같지만 남는 장사", "먼저 사과하면 이긴 것").
- 주식·게임 결도 같은 이유로 금지(저점 매수, 만렙, 부스트, 존버, 떡상).
- 소소한 예언(엘리베이터·붕어빵 꼬리·셔플 첫 곡)은 밈이 아니라 담백한 디테일이라
  계속 쓴다 — `fortune_overall` 의 재미는 여기서 나온다.

## 데이터 구조

| 컬럼 | 설명 |
|---|---|
| `surface` | `daily_quote`(홈 문구) / `fortune_overall`(행운지수 총운) / `fortune_advice`(선행 추천) |
| `lang` | `ko` / `en` / `ja` |
| `grade` | `fortune_overall` 전용. 0=흐림 1=보통 2=맑음 3=대박 (그 외 surface는 null) |
| `text` | 문구. 줄바꿈은 `\n` |
| `tag` / `ends_at` | 스키마엔 있지만 지금 워크플로에선 안 쓴다(만료는 PR에서 사람이 판단). 나중에 자동 만료가 필요해지면 그때 채운다. |
| `active` | 노출 스위치. 동기화 스크립트는 항상 true 로 넣는다. |

폴백 단위는 `(surface, lang, grade)` 조합별이다. 서버에 그 조합의 행이 하나도 없을 때만 번들 문구가 쓰인다.
동기화 스크립트는 세 언어의 모든 면을 한꺼번에 밀어넣으므로, 평소엔 서버 문구가 곧 dart 문구다.

관련 코드: [`tool/sync_copy.dart`](../tool/sync_copy.dart),
[`supabase/migrations/20260713000007_copy_lines.sql`](../supabase/migrations/20260713000007_copy_lines.sql),
[`lib/data/copy_book.dart`](../lib/data/copy_book.dart), [`lib/state/copy_controller.dart`](../lib/state/copy_controller.dart)
