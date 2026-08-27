# 출시 체크리스트

2026-08-27 사전 점검에서 나온 항목 중 **코드로 끝낼 수 없는 것**과 **아직 손대지
않은 것**을 모았다. 코드로 처리한 항목은 커밋 로그에 있다.

## 반드시 먼저 (이거 없으면 심사에서 막힌다)

- [ ] **도메인 확보 + `site/` 배포**
  `site/` 가 배포 대상이다 — 랜딩(`index.html`), 개인정보처리방침(`privacy.html`),
  `app-ads.txt`. 정적 파일뿐이라 빌드 과정이 없다. Cloudflare Pages·Vercel 등
  아무 정적 호스트에 폴더째 올리면 된다.

  **`web/` 은 배포하지 않는다.** Flutter 웹 빌드는 광고 SDK 가 없어
  `AdsController.showRewarded` 가 광고 없이 즉시 보상을 지급한다 — 공개하면
  아무도 광고를 안 보고 매일 한도만큼 재화를 가져간다. 두 정적 파일을 `web/`
  에서 `site/` 로 옮긴 이유가 이것이다.

  **배포처: `hynu.app`** (개인 블로그, Vercel). 없는 경로에 정상 404 를 주는 것을
  확인했으므로 그대로 쓴다. 별도 Vercel 프로젝트를 파지 말 것 — app-ads.txt 는
  루트에 있어야 하는데 루트는 블로그가 쓰고 있다. 블로그 리포에 파일을 얹는다.

  블로그 리포의 정적 디렉터리(Next.js 면 `public/`)에 이렇게 넣는다:

  | 이 리포 | 블로그 리포 | 공개 URL |
  |---|---|---|
  | `site/app-ads.txt` | `public/app-ads.txt` | `https://hynu.app/app-ads.txt` |
  | `site/index.html` | `public/luckypicky/index.html` | `https://hynu.app/luckypicky/index.html` |
  | `site/privacy.html` | `public/luckypicky/privacy.html` | `https://hynu.app/luckypicky/privacy.html` |
  | `site/favicon.png` | `public/luckypicky/favicon.png` | — |

  `app-ads.txt` 만 루트다. 나머지는 `luckypicky/` 아래 같은 폴더에 모여 있어야
  페이지 안의 상대 링크(`privacy.html`, `favicon.png`)가 그대로 동작한다.

  이 리포의 `site/` 가 원본이다. 방침 내용을 고치면 블로그 리포로 복사해야 한다
  (정적 파일 4개라 자동화할 만큼은 아니다).

  배포 후 스토어 등록:
  - 두 스토어의 **개발자 웹사이트** = `https://hynu.app` — 루트여야 한다.
    AdMob 크롤러는 이 URL 의 루트 도메인에서만 app-ads.txt 를 찾는다.
  - 두 스토어의 **개인정보처리방침 URL** = `https://hynu.app/luckypicky/privacy.html`
  - 확인: `curl -i https://hynu.app/app-ads.txt` → 200 + `text/plain`, 본문이
    실제 텍스트인지 볼 것.
  - AdMob → 앱 → app-ads.txt 상태가 "확인됨" 으로 바뀌기까지 최대 24시간.

- [ ] **Supabase 마이그레이션 적용** (SQL 에디터에서 순서대로)
  1. `supabase/migrations/20260827000010_recovery_rate_limit.sql`
  2. `supabase/migrations/20260827000011_recovery_words_i18n.sql`
  두 파일은 기존 `recovery_codes` 행의 해시를 원문에서 다시 계산한다 — 이미
  발급된 코드는 그대로 쓸 수 있다. 적용 전 앱을 올리면 `p_lang` 인자가 없는
  구버전 함수라 복구 코드 발급이 실패한다. **마이그레이션이 먼저다.**

- [ ] **AdMob 콘솔에서 GDPR 동의 메시지 생성**
  앱에 UMP 코드는 들어갔지만, AdMob 콘솔 → 개인정보 보호 및 메시지에서
  유럽 규정 메시지를 만들어 게시하지 않으면 폼이 뜨지 않는다. 코드만으로는
  절반이다. 메시지 게시 후 EEA 기기(또는 디버그 지역 설정)로 확인할 것.

- [ ] **App Store Connect 앱 개인정보 설문**
  `ios/Runner/PrivacyInfo.xcprivacy` 에 선언한 내용과 어긋나면 반려된다.
  선언한 것: 익명 계정 UUID(연결됨·앱 기능), 이용자 입력 문구(연결됨·앱 기능),
  광고 식별자와 광고 데이터(연결 안 됨·추적함·제3자 광고).

- [ ] **Play Console 데이터 보안 양식** — 위와 같은 내용으로.

- [ ] **업로드 키스토어 백업**
  `android/key.properties` 가 가리키는 `.jks` 를 잃으면 같은 앱으로 업데이트를
  올릴 수 없다. 리포지토리 밖 + 별도 매체에 백업.

## 출시 직후를 위해

- [ ] **크래시 리포팅 서비스 연결**
  수집 지점은 `lib/util/error_reporter.dart` 에 만들어 뒀다. Sentry 든
  Crashlytics 든 계정을 만들고 `reportError` 안의 표시된 한 줄에 SDK 호출을
  넣으면 세 경로(위젯/플랫폼/존)가 전부 그리로 간다.
  난독화 빌드(`--obfuscate --split-debug-info`)를 쓸 거면 심볼 업로드까지.

- [ ] **스토어 자산** — 스크린샷(ko/en/ja), 피처 그래픽, 설명문, 키워드.

## 아직 손대지 않은 검토 항목

사전 점검에서 나왔지만 이번 작업 범위에 없던 것들. 우선순위 순.

- [ ] **앱 안에 방침·문의·데이터 삭제 경로가 없다.**
  현재 설정 진입점은 언어 시트 하나뿐이다. 스토어 정책상 앱 내에서도 방침에
  닿을 수 있어야 하고, Play 는 데이터 삭제 요청 경로를 요구한다(익명 계정도
  대상). 언어 시트를 '설정' 시트로 넓히는 게 가장 작은 변경.

- [ ] **완전 온라인 전용.** `backendProvider` 가 `SupabaseGameBackend` 하나라
  비행기 모드 첫 실행은 에러 화면뿐이다. `LocalGameBackend` 가 이미 있으니
  "오프라인이라 기록만 볼 수 있어요" 정도의 열화 동작은 검토할 만하다.

- [ ] **복구 코드 입력에 확인 단계가 없다.** `redeem_recovery_code` 는 현재
  계정 자산을 덮어쓴다. 진행 중이던 계정에 옛 코드를 넣으면 조용히 날아간다.

- [ ] **보상형 광고 서버 검증(SSV) 없음.** 클라이언트가 광고 없이
  `grant_ad_clover()` 를 직접 부를 수 있다. 서버가 하루 3개로 막고 있어 피해는
  제한적 — 우선순위 낮음.

- [ ] `README.md` 가 Flutter 기본 템플릿 그대로다.

- [ ] R8/ProGuard 규칙 미설정 — 난독화 릴리스를 쓸 계획이면 필요.
