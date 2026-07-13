# 행운 지갑 재개편 — 재조합 · 강화 (Forge)

날짜: 2026-07-13
대상: `lib/screens/dex_screen.dart` 및 강화/재조합 플로우 전반

## 배경

현재 행운 지갑은 티켓 카드 스텁마다 「강화하기」 버튼이 박혀 있고, 누르면 바텀시트에서
재료를 고른 뒤 결과가 토스트 한 줄로 끝난다. 문제가 셋이다.

1. 카드 끝에 붙은 강화 버튼이 티켓의 시각적 완결성을 깬다.
2. 강화·재조합이라는 핵심 상호작용에 연출이 없다. 성공/실패가 토스트로만 통보된다.
3. 등급 헤더가 `일반 3/30`처럼 도감 전체 수를 노출한다. 지갑은 도감이 아니다 —
   내가 가진 것만 보여주면 된다.

## 목표

- 재조합 / 강화를 화면 상단의 **기능 버튼**으로 승격한다.
- 버튼을 누르면 지갑 카드 중에서 고르는 **전용 풀스크린**으로 전환된다.
- 실행 결과는 **극적인 연출**로 보여준다. 재료 흡수 → 게이지 → 정지 → 성공/실패.
- 카운트 표기는 **보유 장수**만 쓴다. 전체 도감 수는 지갑에서 노출하지 않는다.
- Material 기본 아이콘 대신 **Toss Face** 이모지 폰트를 쓴다.

## 1. 지갑 화면 (`dex_screen.dart`)

### 상단

```
행운 지갑
뽑은 행운들이 이곳에 모여요                        12장 보유

[ ♻️ 재조합 ]            [ ⭐ 강화하기 ]
```

- 액션 버튼 2개를 한 줄에 나란히 (`Expanded` 반반, 높이 52).
  - 재조합: 보유 카드가 `reforgeMaterials`(3) 미만이면 비활성.
  - 강화: 강화 가능한 카드(= max level 미만)가 하나도 없으면 비활성.
  - 비활성 버튼을 눌러도 라우트로 가지 않고, 왜 안 되는지 토스트를 띄운다.
- 우측 칩: `6/70 수집` → `12장 보유` (총 보유 인스턴스 수).
- `dexProgress` l10n 키는 `dexOwnedCount(count)` 로 교체.

### 등급 섹션

- 헤더: `● 일반 3/30` → `● 일반 3장`. `LuckCatalog.byRarity(...).length` 참조 제거.
- 섹션 마커 원형 도트는 유지 (등급색 아이덴티티).

### 티켓 행 (`_TicketRow`)

- 스텁(우측 28%) 안의 **강화 버튼 제거**.
- 스텁에는 `+N` 강화 단계와 클로버 마크만. 강화 최대치인 카드는 👑 배지.
- 카드 탭 → 기존대로 티켓 상세(`ticketRoute`).

## 2. 포지 화면 (신규 `lib/screens/forge_screen.dart`)

강화와 재조합이 하나의 풀스크린 라우트를 공유한다.

```dart
enum ForgeMode { enhance, reforge }
Route<void> forgeRoute(ForgeMode mode);
```

### 강화 (2단계)

- **STEP 1 — 대상 고르기**: 강화 가능한 카드(레벨 < max)만 목록에 뜬다.
  카드를 탭해 하나 고르고 하단 CTA `다음`.
- **STEP 2 — 재료 고르기**: 상단에 대상 카드가 고정되고, 그 아래에 실시간
  **성공 확률 게이지**(등급색 링 또는 바). 재료 후보는 대상 제외 전 카드.
  정렬은 기존 `enhance_sheet` 규칙 그대로 (같은 행운권 → 상위 등급 → 저레벨 순).
  필요 장수 `target.materialsNeeded` 를 정확히 채워야 CTA 활성.
  확률은 `TicketInstance.successRateWith` 로 계산 (서버 식과 동치, 표시용).
- 뒤로가기: STEP 2 → STEP 1 → 지갑.

### 재조합 (1단계)

- 재료 3장 선택만. 상단에 결과 등급 미리보기(= 재료 중 최고 등급)와
  승급 확률(`reforgeUpgradeRate`) 안내.
- 정렬은 기존 `reforge_sheet` 규칙 (하위 등급 · 저레벨 우선).

### 공용

- 상단 스텝 인디케이터 + 하단 고정 CTA (`SafeArea` 하단 패딩).
- 카드 선택 위젯은 `_PickCard` 하나로 통일. 선택 시 등급색 테두리 + 체크.
- `enhance_sheet.dart`, `reforge_sheet.dart` 는 **삭제**한다. 후보 정렬·확률 계산
  로직은 이 화면으로 옮긴다.

## 3. 연출 (신규 `lib/widgets/forge_overlay.dart`)

가챠와 동일한 패턴: **서버 호출을 먼저 확정**하고 결과를 들고 오버레이 라우트로 진입한다
(빌드 중 상태 변경 방지). 연출 도중 결과가 바뀌지 않으므로 게이지·정지 시간을 자유롭게 쓸 수 있다.

```dart
Future<void> runForgeFlow(BuildContext, WidgetRef, {required ForgeRequest req});
```

`GameConnectionException` 은 진입 전에 잡아 토스트로 처리한다 (기존 시트와 동일).

### 시퀀스

| 페이즈 | 시간 | 내용 |
|---|---|---|
| `absorb` | 0.8s | 재료 카드들이 대상 카드로 빨려 들어간다. 카드마다 스태거(120ms), 흡수 순간 light haptic |
| `charge` | 1.2s | 대상 카드가 떠오르고 등급색 링 게이지가 확률만큼 차오른다. 진동 고조 |
| `hold` | 0.3s | 정지. 침묵. 게이지 끝에서 한 박자 |
| `result` | — | 성공/실패 분기 |

- **성공**: 화이트 플래시 → 클로버 파티클 폭발 → `+N` 각인 스탬프(스케일 인 + 살짝 회전) → heavy haptic ×3. 🎉 배지.
- **실패**: 화면 쉐이크 → 카드 균열선 → 파편 낙하 + 재가 흩날림 → 무거운 단발 haptic. 💥 배지.
- **재조합**: `charge` 에서 게이지 대신 3장이 소용돌이로 합쳐진다. `result` 에서 새 카드가
  뒤집히며 등장하고, 승급했으면 등급 상승 플래시가 한 번 더 터진다.

파티클·게이지·균열은 전부 `CustomPainter`. Lottie는 쓰지 않는다 —
클로버 그린 아이덴티티를 유지하고 기존 `_BurstPainter` / `confetti_burst` 톤을 그대로 잇는다.

결과 화면 하단 CTA: `확인` (지갑으로 복귀). 강화 실패 시에도 동일.

## 4. Toss Face 이모지

- `assets/fonts/TossFace.otf` 번들. `pubspec.yaml` 에 `TossFace` 패밀리 추가.
  라이선스 파일도 `assets/fonts/` 에 함께 넣는다.
- `lib/theme/toss_face.dart`:

```dart
abstract final class TossFace {
  static const recycle = '♻️';   // ♻️ 재조합
  static const star    = '⭐';         // ⭐ 강화
  static const clover  = '🍀';   // 🍀 성공
  static const boom    = '💥';   // 💥 실패
  static const crown   = '👑';   // 👑 만렙
  static const party   = '🎉';   // 🎉
}

class TossEmoji extends StatelessWidget { /* Text(emoji, fontFamily: 'TossFace') */ }
```

- 적용 범위: 지갑 액션 버튼, 등급 만렙 배지, 빈 지갑 안내, 포지 스텝 헤더,
  결과 오버레이 배지. **이번 범위 안의 화면만** 교체하고 앱 전역 일괄 교체는 하지 않는다.

## 5. l10n

3개 언어(ko/en/ja) ARB에 신규 키를 넣는다.

| 키 | ko 예시 |
|---|---|
| `dexOwnedCount` | `{count}장 보유` |
| `dexRarityCount` | `{count}장` |
| `forgeStepTarget` | `강화할 카드를 고르세요` |
| `forgeStepMaterial` | `재료를 고르세요` |
| `forgeNext` | `다음` |
| `forgeNoEnhanceable` | `강화할 수 있는 카드가 없어요` |
| `forgeNotEnoughCards` | `카드가 {n}장 이상 있어야 해요` |
| `forgeSuccess` | `강화 성공!` |
| `forgeFail` | `강화 실패…` |
| `forgeReforged` | `새 행운이 나왔어요` |
| `forgeUpgraded` | `등급이 올랐어요!` |
| `forgeConfirm` | `확인` |

제거: `dexProgress`, `dexEnhanceCta`, `enhance*`/`reforge*` 시트 전용 키 중 미사용분.
문구 톤은 기존 규칙을 따른다 — 순수 가챠 프레임 금지, 「선행으로 운을 만든다」.

## 6. 서버

**변경 없다.** `enhance_ticket`, `reforge_tickets` RPC와 로컬 백엔드는 그대로 쓴다.
이번 작업은 전부 클라이언트 UI다.

## 7. 테스트

- `test/app_controller_test.dart` — 기존 강화/재조합 테스트는 그대로 통과해야 한다
  (컨트롤러 API 변경 없음).
- `test/widget_test.dart` — 지갑 화면에서 `일반 3/30` 문자열이 사라지고 `3장`이 뜨는지,
  강화 버튼이 티켓 행에 없는지 확인.
- 신규: 포지 화면 위젯 테스트 — 강화 STEP1 → STEP2 전이, 재료 수를 채우기 전엔 CTA 비활성.
- 연출 오버레이는 결과를 주입받는 순수 위젯이므로, 성공/실패 각각 렌더 스모크 테스트.

## 범위 밖

- 앱 전역 Material 아이콘 → Toss Face 일괄 교체
- 서버 룰(확률·재료 수) 변경
- 티켓 상세 화면 리디자인
