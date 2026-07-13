# 행운 지갑 재개편 (재조합 · 강화 Forge) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 행운 지갑에서 재조합·강화를 상단 기능 버튼으로 승격하고, 전용 풀스크린 카드 선택 화면과 극적인 성공/실패 연출을 붙인다.

**Architecture:** 서버 RPC는 손대지 않는다. 클라이언트만 바꾼다. 기존 두 개의 바텀시트(`enhance_sheet.dart`, `reforge_sheet.dart`)를 지우고, 하나의 풀스크린 `ForgeScreen`(mode = enhance | reforge)으로 통합한다. 실행 시 가챠와 동일하게 **서버 결과를 먼저 확정**한 뒤 결과를 들고 `ForgeOverlay` 라우트로 진입해 흡수 → 게이지 → 정지 → 성공/실패 시퀀스를 재생한다. 모든 연출은 `CustomPainter` (Lottie 미사용). 아이콘은 Toss Face 이모지 폰트.

**Tech Stack:** Flutter 3 / Dart, flutter_riverpod, flutter gen-l10n (ARB), CustomPainter, Toss Face OTF (`toss/tossface` v1.6.1)

## Global Constraints

- 서버(Supabase RPC / SQL 마이그레이션) 및 `GameBackend` 인터페이스는 **변경 금지**. 이번 작업은 전부 클라이언트 UI다.
- 확률·재료 수 규칙 변경 금지. 표시용 계산은 기존 `TicketInstance.successRateWith` / `materialsNeeded` / `reforgeMaterials`(3) / `reforgeUpgradeRate`(25) 를 그대로 쓴다.
- 지갑 화면에서 **도감 전체 개수(`LuckCatalog.tickets.length`, `byRarity(...).length`)를 노출하지 않는다.** 보유 장수만 쓴다.
- l10n은 항상 ko/en/ja **3개 ARB 모두** 동시에 수정한다. 문구 톤: MZ 드립 OK, 단 "선행으로 운을 만든다" 정체성 유지 — 순수 도박/가챠 프레임 금지.
- 색은 `AppColors` / `RarityStyle` 만 쓴다. Material 기본 색 하드코딩 금지.
- 하드코딩된 사용자 표시 문자열 금지 — 전부 `AppLocalizations` 경유.
- ARB 수정 후에는 반드시 `flutter gen-l10n` 을 돌려 `lib/l10n/app_localizations*.dart` 를 갱신하고 함께 커밋한다.
- 모든 명령은 리포 루트 `c:\GitHub\ooloo` 에서 실행한다. 테스트는 `flutter test`, 정적 분석은 `flutter analyze` (경고 0 유지).

---

## File Structure

**생성**
- `assets/fonts/TossFace.otf` — Toss Face 이모지 폰트
- `assets/fonts/TOSSFACE-LICENSE.txt` — 폰트 라이선스
- `lib/theme/toss_face.dart` — 이모지 상수 + `TossEmoji` 위젯
- `lib/screens/forge_screen.dart` — 풀스크린 카드 선택 (강화 2단계 / 재조합 1단계)
- `lib/widgets/forge_overlay.dart` — 실행 연출 오버레이 + `runForgeFlow`
- `lib/widgets/forge_painters.dart` — 게이지 링 · 파티클 폭발 · 균열 CustomPainter
- `test/forge_screen_test.dart`
- `test/forge_overlay_test.dart`

**수정**
- `pubspec.yaml` — TossFace 폰트 패밀리 등록
- `lib/screens/dex_screen.dart` — 상단 액션 버튼, 카운트 표기, 스텁 강화 버튼 제거
- `lib/l10n/app_{ko,en,ja}.arb` — 신규 키
- `test/widget_test.dart` — 지갑 화면 기대값 갱신

**삭제**
- `lib/widgets/enhance_sheet.dart`
- `lib/widgets/reforge_sheet.dart`

---

## Task 1: Toss Face 폰트 번들 + 이모지 위젯

**Files:**
- Create: `assets/fonts/TossFace.otf`, `assets/fonts/TOSSFACE-LICENSE.txt`, `lib/theme/toss_face.dart`
- Modify: `pubspec.yaml:36-48`
- Test: `test/toss_face_test.dart`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `abstract final class TossFace` — 상수 `recycle`, `star`, `clover`, `boom`, `crown`, `party`, `sparkles` (모두 `String`)
  - `class TossEmoji extends StatelessWidget` — `const TossEmoji(String emoji, {double size, Key? key})`
  - 폰트 패밀리 문자열 `TossFace.family` = `'TossFace'`

- [ ] **Step 1: 폰트와 라이선스를 내려받는다**

```bash
curl -sL -o assets/fonts/TossFace.otf \
  https://github.com/toss/tossface/releases/download/v1.6.1/TossFaceFontWeb.otf
curl -sL -o assets/fonts/TOSSFACE-LICENSE.txt \
  https://raw.githubusercontent.com/toss/tossface/main/LICENSE
ls -l assets/fonts/TossFace.otf assets/fonts/TOSSFACE-LICENSE.txt
```

Expected: `TossFace.otf` 가 1MB 이상, 라이선스 파일이 0바이트가 아님. 둘 중 하나라도 실패하면 여기서 멈추고 사람에게 보고한다 (임의의 다른 폰트로 대체하지 말 것).

- [ ] **Step 2: `pubspec.yaml` 에 폰트 패밀리를 추가한다**

`fonts:` 블록의 Pretendard 항목 **아래에** 이어 붙인다 (파일 끝):

```yaml
    - family: TossFace
      fonts:
        - asset: assets/fonts/TossFace.otf
```

- [ ] **Step 3: 실패하는 테스트를 쓴다**

`test/toss_face_test.dart` 를 새로 만든다:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luckypicky/theme/toss_face.dart';

void main() {
  testWidgets('TossEmoji renders the glyph with the TossFace family',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(child: TossEmoji(TossFace.clover, size: 20)),
    ));

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, TossFace.clover);
    expect(text.style?.fontFamily, TossFace.family);
    expect(text.style?.fontSize, 20);
  });

  test('emoji constants are the agreed codepoints', () {
    expect(TossFace.recycle, '♻️'); // ♻️ 재조합
    expect(TossFace.star, '⭐'); // ⭐ 강화
    expect(TossFace.clover, '\u{1F340}'); // 🍀
    expect(TossFace.boom, '\u{1F4A5}'); // 💥
    expect(TossFace.crown, '\u{1F451}'); // 👑
  });
}
```

- [ ] **Step 4: 테스트를 돌려 실패를 확인한다**

Run: `flutter test test/toss_face_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:luckypicky/theme/toss_face.dart'`

- [ ] **Step 5: `lib/theme/toss_face.dart` 를 구현한다**

```dart
import 'package:flutter/widgets.dart';

/// Toss Face 이모지 — Material 기본 아이콘 대신 쓰는 앱 공용 픽토그램.
/// 폰트는 assets/fonts/TossFace.otf (toss/tossface v1.6.1).
abstract final class TossFace {
  static const family = 'TossFace';

  static const recycle = '♻️'; // ♻️ 재조합
  static const star = '⭐'; // ⭐ 강화
  static const clover = '\u{1F340}'; // 🍀 성공 / 브랜드
  static const boom = '\u{1F4A5}'; // 💥 강화 실패
  static const crown = '\u{1F451}'; // 👑 만렙
  static const party = '\u{1F389}'; // 🎉 축하
  static const sparkles = '✨'; // ✨ 등급 상승
}

/// 이모지 한 글자를 아이콘처럼 그린다. 폰트 폴백을 막기 위해 패밀리를 고정한다.
class TossEmoji extends StatelessWidget {
  final String emoji;
  final double size;

  const TossEmoji(this.emoji, {super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji,
      style: TextStyle(
        fontFamily: TossFace.family,
        fontSize: size,
        height: 1,
      ),
    );
  }
}
```

- [ ] **Step 6: 테스트가 통과하는지 확인한다**

Run: `flutter test test/toss_face_test.dart && flutter analyze`
Expected: PASS, analyze 이슈 0건

- [ ] **Step 7: 커밋**

```bash
git add assets/fonts/TossFace.otf assets/fonts/TOSSFACE-LICENSE.txt \
        lib/theme/toss_face.dart pubspec.yaml test/toss_face_test.dart
git commit -m "feat: Toss Face 이모지 폰트 번들 + TossEmoji 위젯"
```

---

## Task 2: l10n 키 정리

**Files:**
- Modify: `lib/l10n/app_ko.arb`, `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb`
- Generated: `lib/l10n/app_localizations*.dart` (`flutter gen-l10n` 산출물)

**Interfaces:**
- Consumes: 없음
- Produces: `AppLocalizations` 의 신규 게터/메서드 —
  `dexOwnedCount(int count)`, `dexRarityCount(int count)`, `forgeEnhanceCta`, `forgeReforgeCta`,
  `forgeStepTarget`, `forgeStepMaterial`, `forgeStepReforge`, `forgeNext`, `forgeBack`,
  `forgeRunEnhance(int have, int need)`, `forgeRunReforge(int have, int need)`,
  `forgeRate(int rate)`, `forgeRateHint`, `forgeWarn`, `forgeReforgeHint(int rate)`,
  `forgeNoEnhanceable`, `forgeNotEnoughCards(int need)`, `forgeNoMaterial`,
  `forgeSuccess`, `forgeSuccessPlus(int plus)`, `forgeFail`, `forgeFailHint`,
  `forgeReforged`, `forgeUpgraded`, `forgeConfirm`

- [ ] **Step 1: `lib/l10n/app_ko.arb` 를 수정한다**

`"dexEnhanceCta"`, `"dexEnhanceNeed"`, `"dexProgress"` 세 줄과, `"enhanceTitle"` 부터 `"toastReforgedUp"` 까지의 블록(현재 67–86행)을 **삭제**하고, 그 자리에 아래를 넣는다. `dexTitle`/`dexSubtitle`/`dexEmpty`/`dexEnhanceMax`/`dexPlus` 는 남긴다.

```json
  "dexOwnedCount": "{count}장 보유",
  "dexRarityCount": "{count}장",

  "forgeEnhanceCta": "강화하기",
  "forgeReforgeCta": "재조합",
  "forgeStepTarget": "강화할 카드를 고르세요",
  "forgeStepMaterial": "재료로 태울 카드를 고르세요",
  "forgeStepReforge": "갈아 넣을 카드 {need}장을 고르세요",
  "forgeNext": "다음",
  "forgeBack": "뒤로",
  "forgeRunEnhance": "강화하기 ({have}/{need})",
  "forgeRunReforge": "재조합하기 ({have}/{need})",
  "forgeRate": "성공 확률 {rate}%",
  "forgeRateHint": "같은 카드 +15%p · 상위 등급 +10%p · 하위 등급 -10%p",
  "forgeWarn": "실패해도 재료는 사라져요",
  "forgeReforgeHint": "재료 중 가장 높은 등급으로 나오고, {rate}% 확률로 한 등급 올라가요",
  "forgeNoEnhanceable": "강화할 수 있는 카드가 없어요",
  "forgeNotEnoughCards": "카드가 {need}장 이상 있어야 해요",
  "forgeNoMaterial": "재료로 쓸 다른 카드가 없어요",
  "forgeSuccess": "강화 성공!",
  "forgeSuccessPlus": "+{plus}",
  "forgeFail": "강화 실패…",
  "forgeFailHint": "재료는 사라졌지만, 행운은 아직 남아 있어요",
  "forgeReforged": "새 행운이 나왔어요",
  "forgeUpgraded": "등급이 올랐어요!",
  "forgeConfirm": "확인",
```

- [ ] **Step 2: `lib/l10n/app_en.arb` 에 같은 키를 넣는다**

ko와 동일한 위치에서 옛 키를 지우고 아래를 넣는다:

```json
  "dexOwnedCount": "{count} cards",
  "dexRarityCount": "{count}",

  "forgeEnhanceCta": "Enhance",
  "forgeReforgeCta": "Reforge",
  "forgeStepTarget": "Pick a card to enhance",
  "forgeStepMaterial": "Pick the cards to burn",
  "forgeStepReforge": "Pick {need} cards to melt down",
  "forgeNext": "Next",
  "forgeBack": "Back",
  "forgeRunEnhance": "Enhance ({have}/{need})",
  "forgeRunReforge": "Reforge ({have}/{need})",
  "forgeRate": "{rate}% success",
  "forgeRateHint": "Same card +15%p · higher tier +10%p · lower tier -10%p",
  "forgeWarn": "Materials burn even if it fails",
  "forgeReforgeHint": "You get the highest tier among the materials, with a {rate}% chance to tier up",
  "forgeNoEnhanceable": "No card can be enhanced yet",
  "forgeNotEnoughCards": "You need at least {need} cards",
  "forgeNoMaterial": "No other card to use as material",
  "forgeSuccess": "Enhanced!",
  "forgeSuccessPlus": "+{plus}",
  "forgeFail": "It didn't take…",
  "forgeFailHint": "The materials are gone, but your luck isn't",
  "forgeReforged": "A new luck came out",
  "forgeUpgraded": "Tier up!",
  "forgeConfirm": "OK",
```

- [ ] **Step 3: `lib/l10n/app_ja.arb` 에 같은 키를 넣는다**

```json
  "dexOwnedCount": "{count}枚 所持",
  "dexRarityCount": "{count}枚",

  "forgeEnhanceCta": "強化する",
  "forgeReforgeCta": "再構成",
  "forgeStepTarget": "強化するカードを選んでください",
  "forgeStepMaterial": "素材にするカードを選んでください",
  "forgeStepReforge": "溶かすカードを{need}枚選んでください",
  "forgeNext": "次へ",
  "forgeBack": "戻る",
  "forgeRunEnhance": "強化する ({have}/{need})",
  "forgeRunReforge": "再構成する ({have}/{need})",
  "forgeRate": "成功確率 {rate}%",
  "forgeRateHint": "同じカード +15%p ・ 上位等級 +10%p ・ 下位等級 -10%p",
  "forgeWarn": "失敗しても素材は消えます",
  "forgeReforgeHint": "素材の中で最も高い等級で出て、{rate}%の確率で一段階上がります",
  "forgeNoEnhanceable": "強化できるカードがありません",
  "forgeNotEnoughCards": "カードが{need}枚以上必要です",
  "forgeNoMaterial": "素材にできるカードがありません",
  "forgeSuccess": "強化成功！",
  "forgeSuccessPlus": "+{plus}",
  "forgeFail": "強化失敗…",
  "forgeFailHint": "素材は消えましたが、幸運はまだ残っています",
  "forgeReforged": "新しい幸運が出ました",
  "forgeUpgraded": "等級が上がりました！",
  "forgeConfirm": "確認",
```

- [ ] **Step 4: 코드를 생성한다**

Run: `flutter gen-l10n`
Expected: 에러 없이 종료. `lib/l10n/app_localizations.dart` 에 `forgeStepTarget` 이 생겼는지 확인:

Run: `grep -c "forgeStepTarget" lib/l10n/app_localizations.dart`
Expected: `1` 이상

- [ ] **Step 5: 아직 삭제된 키를 참조하는 곳을 확인한다**

Run: `flutter analyze`
Expected: `enhance_sheet.dart`, `reforge_sheet.dart`, `dex_screen.dart`, `ticket_screen.dart` 에서 `l.enhanceTitle` 등 **없어진 게터** 에러가 뜬다. 이건 예상된 것이다 — Task 3~6에서 해소된다. **여기서 코드를 고치지 말고 그대로 둔다.**

주의: `ticket_screen.dart` 는 자체 키(`ticketEnhance`, `ticketEnhanceMax`, `toastEnhanced`)를 쓴다. 이 키들은 **지우지 않았으므로** ticket_screen 에서 에러가 나면 안 된다. 만약 났다면 ARB에서 잘못된 줄을 지운 것이니 되돌린다.

- [ ] **Step 6: 커밋**

```bash
git add lib/l10n
git commit -m "feat(l10n): 포지(재조합/강화) 문구 키 추가, 시트 전용 키 제거"
```

---

## Task 3: 연출용 페인터 (게이지 · 폭발 · 균열)

**Files:**
- Create: `lib/widgets/forge_painters.dart`
- Test: `test/forge_painters_test.dart`

**Interfaces:**
- Consumes: `RarityStyle` (`lib/widgets/rarity_style.dart`)
- Produces:
  - `class ForgeGaugePainter extends CustomPainter` — `ForgeGaugePainter({required double t, required double rate, required Color color})` (`t` 0..1 진행, `rate` 0..1 목표 확률)
  - `class ForgeBurstPainter extends CustomPainter` — `ForgeBurstPainter({required double t, required Color color})`
  - `class ForgeCrackPainter extends CustomPainter` — `ForgeCrackPainter({required double t})`

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`test/forge_painters_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luckypicky/widgets/forge_painters.dart';

void main() {
  test('gauge repaints only when its inputs change', () {
    const a = ForgeGaugePainter(t: 0.5, rate: 0.8, color: Colors.green);
    const b = ForgeGaugePainter(t: 0.6, rate: 0.8, color: Colors.green);
    expect(a.shouldRepaint(a), isFalse);
    expect(a.shouldRepaint(b), isTrue);
  });

  testWidgets('painters draw without throwing across the whole timeline',
      (tester) async {
    for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      await tester.pumpWidget(MaterialApp(
        home: Column(children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: ForgeGaugePainter(t: t, rate: 0.6, color: Colors.green),
            ),
          ),
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: ForgeBurstPainter(t: t, color: Colors.green),
            ),
          ),
          SizedBox(
            width: 200,
            height: 120,
            child: CustomPaint(painter: ForgeCrackPainter(t: t)),
          ),
        ]),
      ));
      expect(tester.takeException(), isNull);
    }
  });
}
```

- [ ] **Step 2: 테스트를 돌려 실패를 확인한다**

Run: `flutter test test/forge_painters_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:luckypicky/widgets/forge_painters.dart'`

- [ ] **Step 3: `lib/widgets/forge_painters.dart` 를 구현한다**

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 강화 게이지 — 등급색 링이 성공 확률만큼 차오른다.
/// 채워지는 동안 바깥으로 얇은 광채 링이 한 겹 번진다.
class ForgeGaugePainter extends CustomPainter {
  final double t; // 0..1 애니메이션 진행
  final double rate; // 0..1 목표 확률
  final Color color;

  const ForgeGaugePainter({
    required this.t,
    required this.rate,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    if (radius <= 0) return;

    // 트랙.
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );

    // 채워지는 호 — 12시에서 시계방향.
    final sweep = 2 * math.pi * rate * t.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 7,
    );

    // 링이 차오를수록 밖으로 번지는 광채.
    final glow = (t * rate).clamp(0.0, 1.0);
    if (glow > 0) {
      canvas.drawCircle(
        c,
        radius + 6 * glow,
        Paint()
          ..color = color.withValues(alpha: 0.18 * glow)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(ForgeGaugePainter old) =>
      old.t != t || old.rate != rate || old.color != color;
}

/// 성공 폭발 — 등급색 링 두 겹 + 클로버 잎 파티클이 사방으로 흩어진다.
class ForgeBurstPainter extends CustomPainter {
  final double t; // 0..1
  final Color color;

  const ForgeBurstPainter({required this.t, required this.color});

  static const _petals = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final reach = math.min(size.width, size.height) / 2;

    // 충격파 링 두 겹 (시간차).
    for (var r = 0; r < 2; r++) {
      final lt = (t - r * 0.12).clamp(0.0, 1.0);
      if (lt <= 0) continue;
      canvas.drawCircle(
        c,
        20 + reach * lt,
        Paint()
          ..color = color.withValues(alpha: 0.5 * (1 - lt))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // 잎 파티클 — 뻗어나가며 회전하고, 뒤로 갈수록 사라진다.
    final fade = t < 0.35 ? t / 0.35 : 1 - (t - 0.35) / 0.65;
    final opacity = fade.clamp(0.0, 1.0);
    final dist = reach * (0.35 + 0.55 * t);
    final leaf = 3.4 * (t < 0.35 ? t / 0.35 : 1.0);

    for (var k = 0; k < _petals; k++) {
      final ang = (k * (2 * math.pi / _petals)) + t * 0.6;
      final p = c + Offset(dist * math.cos(ang), dist * math.sin(ang));
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(ang + t * 3);
      // 잎사귀 = 살짝 눌린 타원.
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: leaf * 2.2, height: leaf * 1.4),
        Paint()..color = color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ForgeBurstPainter old) =>
      old.t != t || old.color != color;
}

/// 실패 균열 — 카드 위에 금이 번지고, 조각이 아래로 떨어진다.
class ForgeCrackPainter extends CustomPainter {
  final double t; // 0..1

  const ForgeCrackPainter({required this.t});

  // 균열 갈래는 고정 시드 — 매 프레임 같은 모양.
  static final List<List<Offset>> _cracks = () {
    final rng = math.Random(7130);
    return List.generate(4, (i) {
      var p = const Offset(0.5, 0.5);
      final pts = <Offset>[p];
      final dir = (i * math.pi / 2) + rng.nextDouble() * 0.6 - 0.3;
      for (var s = 0; s < 4; s++) {
        p = Offset(
          p.dx + math.cos(dir + (rng.nextDouble() - 0.5) * 1.1) * 0.16,
          p.dy + math.sin(dir + (rng.nextDouble() - 0.5) * 1.1) * 0.16,
        );
        pts.add(p);
      }
      return pts;
    });
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final grow = (t / 0.45).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = const Color(0xFF3A3A3A).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (final pts in _cracks) {
      final path = Path()
        ..moveTo(pts.first.dx * size.width, pts.first.dy * size.height);
      final shown = 1 + ((pts.length - 1) * grow).floor();
      for (var i = 1; i < shown; i++) {
        path.lineTo(pts[i].dx * size.width, pts[i].dy * size.height);
      }
      canvas.drawPath(path, paint);
    }

    // 조각 낙하 — 균열이 다 번진 뒤부터.
    final fall = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
    if (fall <= 0) return;
    for (var k = 0; k < 6; k++) {
      final x = (0.18 + k * 0.13) * size.width;
      final y = size.height * (0.45 + fall * 0.9) + k * 4;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(fall * (k.isEven ? 2.4 : -2.0));
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 5),
        Paint()
          ..color = const Color(0xFF9AA0A6).withValues(alpha: 0.8 * (1 - fall)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ForgeCrackPainter old) => old.t != t;
}
```

- [ ] **Step 4: 테스트가 통과하는지 확인한다**

Run: `flutter test test/forge_painters_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: 커밋**

```bash
git add lib/widgets/forge_painters.dart test/forge_painters_test.dart
git commit -m "feat: 포지 연출 페인터 (게이지·폭발·균열)"
```

---

## Task 4: 포지 연출 오버레이

**Files:**
- Create: `lib/widgets/forge_overlay.dart`
- Test: `test/forge_overlay_test.dart`

**Interfaces:**
- Consumes: `ForgeGaugePainter`, `ForgeBurstPainter`, `ForgeCrackPainter` (Task 3), `TossFace`/`TossEmoji` (Task 1), `AppLocalizations` 신규 키 (Task 2), `EnhanceOutcome`/`ReforgeOutcome` (`lib/data/game_backend.dart`), `appControllerProvider` (`lib/state/app_controller.dart`), `showAppToast`, `Pressable`, `RarityStyle`, `LuckCatalog`
- Produces:
  - `sealed class ForgeResult` + `class ForgeEnhanceResult extends ForgeResult { final EnhanceOutcome outcome; final String ticketId; final int rate; }` + `class ForgeReforgeResult extends ForgeResult { final ReforgeOutcome outcome; }`
  - `Future<void> runEnhanceFlow(BuildContext context, WidgetRef ref, {required String targetId, required List<String> materialIds, required int rate})`
  - `Future<void> runReforgeFlow(BuildContext context, WidgetRef ref, {required List<String> materialIds})`
  - `class ForgeOverlay extends StatefulWidget { const ForgeOverlay({required ForgeResult result, required int materialCount, required Color accent}); }` — 결과를 주입받는 순수 위젯 (테스트용으로 public)

**설계 노트 (구현자용):** 가챠(`gacha_pull_overlay.dart:22-45`)와 같은 패턴이다. `run*Flow` 는 **먼저** 컨트롤러를 호출해 결과를 확정하고, `GameConnectionException` 이면 토스트만 띄우고 리턴한다. 결과가 있으면 `Navigator.push` 로 `ForgeOverlay` 를 띄운다. `ForgeOverlay` 자체는 서버를 모르고 결과만 그린다 — 그래서 테스트가 쉽다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`test/forge_overlay_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luckypicky/data/game_backend.dart';
import 'package:luckypicky/l10n/app_localizations.dart';
import 'package:luckypicky/models/ticket_instance.dart';
import 'package:luckypicky/widgets/forge_overlay.dart';

Widget _host(Widget child) => MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  testWidgets('enhance success ends on the success badge', (tester) async {
    await tester.pumpWidget(_host(ForgeOverlay(
      result: const ForgeEnhanceResult(
        outcome: EnhanceOutcome(
          instanceId: 'i1',
          ticketId: 'c02',
          success: true,
          level: 3,
          rate: 80,
        ),
        ticketId: 'c02',
        rate: 80,
      ),
      materialCount: 2,
      accent: const Color(0xFF6FC143),
    )));

    // 시퀀스를 끝까지 돌린다.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('강화 성공!'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget); // level 3 → +2
    expect(find.text('확인'), findsOneWidget);
  });

  testWidgets('enhance failure ends on the failure badge', (tester) async {
    await tester.pumpWidget(_host(ForgeOverlay(
      result: const ForgeEnhanceResult(
        outcome: EnhanceOutcome(
          instanceId: 'i1',
          ticketId: 'c02',
          success: false,
          level: 1,
          rate: 40,
        ),
        ticketId: 'c02',
        rate: 40,
      ),
      materialCount: 1,
      accent: const Color(0xFF6FC143),
    )));

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('강화 실패…'), findsOneWidget);
  });

  testWidgets('reforge upgrade shows the tier-up line', (tester) async {
    await tester.pumpWidget(_host(ForgeOverlay(
      result: ForgeReforgeResult(
        outcome: const ReforgeOutcome(
          instance: TicketInstance(id: 'n1', ticketId: 'c02', pulledAt: ''),
          isNew: true,
          upgraded: true,
        ),
      ),
      materialCount: 3,
      accent: const Color(0xFF6FC143),
    )));

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('등급이 올랐어요!'), findsOneWidget);
  });
}
```

> 주의: `'c02'` 는 실제 카탈로그에 있는 id 여야 한다. 없다면 `lib/config/luck_tickets.dart` 에서 common 등급 id 하나를 골라 세 테스트 모두에서 바꾼다.

- [ ] **Step 2: 테스트를 돌려 실패를 확인한다**

Run: `flutter test test/forge_overlay_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:luckypicky/widgets/forge_overlay.dart'`

- [ ] **Step 3: `lib/widgets/forge_overlay.dart` 를 구현한다**

핵심 요구사항 (전부 만족해야 한다):

1. `_Phase { absorb, charge, hold, result }` — 각각 800ms / 1200ms / 300ms / (정지).
2. `absorb`: `materialCount` 개의 작은 카드가 화면 바깥 지점에서 중앙 대상 카드로 빨려 들어간다. 카드마다 120ms 스태거. 각 카드가 도착할 때 `HapticFeedback.lightImpact()`.
3. `charge`: 중앙 카드가 살짝 떠오르며(`Transform.translate` + scale) `ForgeGaugePainter(t: …, rate: rate/100, color: accent)` 링이 차오른다. 240ms 간격으로 `HapticFeedback.selectionClick()`.
   - 재조합은 게이지 대신 카드가 회전(소용돌이)한다 — `rate` 가 없으므로 `ForgeGaugePainter` 를 쓰지 않고 `Transform.rotate` 로 가속 회전.
4. `hold`: 300ms 아무것도 안 한다 (정지 = 긴장).
5. `result`:
   - 강화 성공 → 흰 플래시(180ms 페이드아웃) + `ForgeBurstPainter` + `+N` 각인(`Curves.easeOutBack` 스케일 인) + `HapticFeedback.heavyImpact()` 3회(0/140/300ms). 배지 `TossEmoji(TossFace.party)` + `l.forgeSuccess` + `l.forgeSuccessPlus(level - 1)`.
   - 강화 실패 → 화면 쉐이크(`Transform.translate` 로 ±6px, 420ms 감쇠) + `ForgeCrackPainter` + `HapticFeedback.heavyImpact()` 1회. 배지 `TossEmoji(TossFace.boom)` + `l.forgeFail` + `l.forgeFailHint`.
   - 재조합 → 새 카드가 Y축으로 뒤집히며 등장. `upgraded` 면 `ForgeBurstPainter` + `TossEmoji(TossFace.sparkles)` + `l.forgeUpgraded`, 아니면 `l.forgeReforged`. 카드 문구는 `LuckCatalog.byId(outcome.instance.ticketId)?.text(lang)`.
6. 하단에 `l.forgeConfirm` CTA(`Pressable`) — 누르면 `Navigator.maybePop()`. `result` 페이즈에서만 보인다.
7. 배경은 `AppColors.white`, 액센트는 생성자로 받은 `accent` (호출측이 대상/결과 등급색을 넘긴다).
8. `runEnhanceFlow` / `runReforgeFlow`:

```dart
Future<void> runEnhanceFlow(
  BuildContext context,
  WidgetRef ref, {
  required String targetId,
  required List<String> materialIds,
  required int rate,
}) async {
  final EnhanceOutcome? r;
  try {
    r = await ref
        .read(appControllerProvider.notifier)
        .enhanceTicket(targetId, materialIds);
  } on GameConnectionException {
    if (context.mounted) {
      showAppToast(context, AppLocalizations.of(context).errorNeedConnection);
    }
    return;
  }
  if (r == null || !context.mounted) return;
  final rarity = LuckCatalog.byId(r.ticketId)?.rarity ?? Rarity.common;
  await Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => ForgeOverlay(
        result: ForgeEnhanceResult(outcome: r!, ticketId: r.ticketId, rate: rate),
        materialCount: materialIds.length,
        accent: RarityStyle.of(rarity).color,
      ),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}
```

`runReforgeFlow` 도 같은 골격 — `reforgeTickets(materialIds)` 를 호출하고, accent 는 결과 카드 등급색, `materialCount` 는 `materialIds.length`.

9. `dispose()` 에서 모든 `AnimationController` 를 해제한다. `mounted` 체크 없이 `setState` 하지 않는다.

- [ ] **Step 4: 테스트가 통과하는지 확인한다**

Run: `flutter test test/forge_overlay_test.dart && flutter analyze lib/widgets/forge_overlay.dart`
Expected: PASS (3 tests), analyze 이슈 0건

- [ ] **Step 5: 커밋**

```bash
git add lib/widgets/forge_overlay.dart test/forge_overlay_test.dart
git commit -m "feat: 강화·재조합 연출 오버레이 (흡수→게이지→정지→성공/실패)"
```

---

## Task 5: 포지 선택 화면

**Files:**
- Create: `lib/screens/forge_screen.dart`
- Test: `test/forge_screen_test.dart`
- Delete: `lib/widgets/enhance_sheet.dart`, `lib/widgets/reforge_sheet.dart`

**Interfaces:**
- Consumes: `runEnhanceFlow` / `runReforgeFlow` (Task 4), `TossEmoji`/`TossFace` (Task 1), 신규 l10n 키 (Task 2), `TicketInstance`, `LuckCatalog`, `RarityStyle`, `Pressable`, `appControllerProvider`
- Produces:
  - `enum ForgeMode { enhance, reforge }`
  - `Route<void> forgeRoute(ForgeMode mode)`
  - `class ForgeScreen extends ConsumerStatefulWidget { const ForgeScreen({required ForgeMode mode}); }`

**설계 노트:** 강화는 STEP1(대상) → STEP2(재료) 2단계, 재조합은 재료 선택 1단계뿐. 상태는 `_targetId`(강화 전용)와 `_picked`(Set<String>) 두 개면 충분하다. 뒤로가기(`PopScope`)는 STEP2 → STEP1 로 되돌리고, STEP1 에서만 화면을 닫는다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`test/forge_screen_test.dart`. 기존 `test/app_controller_test.dart` 가 `LocalGameBackend` 를 어떻게 주입하는지 먼저 읽고 (`Read test/app_controller_test.dart`) 같은 방식으로 `ProviderScope` 오버라이드를 구성한다. 카드를 3장 이상 보유한 상태를 만들고:

```dart
// 강화 모드: 대상을 고르기 전에는 CTA(다음)가 비활성이고,
// 대상을 고르면 STEP2(재료 고르기)로 넘어간다.
testWidgets('enhance flow moves from target step to material step',
    (tester) async {
  await tester.pumpWidget(_host(const ForgeScreen(mode: ForgeMode.enhance)));
  await tester.pumpAndSettle();

  expect(find.text('강화할 카드를 고르세요'), findsOneWidget);

  await tester.tap(find.byType(ForgePickCard).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();

  expect(find.text('재료로 태울 카드를 고르세요'), findsOneWidget);
});

// 재조합 모드: 3장을 다 고르기 전에는 실행 CTA가 비활성.
testWidgets('reforge CTA stays disabled until 3 cards are picked',
    (tester) async {
  await tester.pumpWidget(_host(const ForgeScreen(mode: ForgeMode.reforge)));
  await tester.pumpAndSettle();

  expect(find.text('재조합하기 (0/3)'), findsOneWidget);

  await tester.tap(find.byType(ForgePickCard).at(0));
  await tester.pumpAndSettle();
  expect(find.text('재조합하기 (1/3)'), findsOneWidget);
});
```

`ForgePickCard` 는 이 화면이 export 하는 public 위젯이어야 한다 (테스트가 찾을 수 있도록).

- [ ] **Step 2: 테스트를 돌려 실패를 확인한다**

Run: `flutter test test/forge_screen_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:luckypicky/screens/forge_screen.dart'`

- [ ] **Step 3: `lib/screens/forge_screen.dart` 를 구현한다**

요구사항:

1. `enum ForgeMode { enhance, reforge }`, `Route<void> forgeRoute(ForgeMode mode)` — `ticketRoute` (`lib/screens/ticket_screen.dart:18-24`) 와 같은 `PageRouteBuilder` + 페이드.
2. `class ForgePickCard extends StatelessWidget` — 카드 한 장의 선택 행. `TicketInstance` + `bool picked` + `VoidCallback? onTap`. 등급색 테두리 + 선택 시 체크. 기존 `enhance_sheet.dart` 의 `_materialRow` (등급명 · `+N` · 문구 1줄) 를 그대로 옮긴다.
3. 강화 STEP1: 후보 = `tickets.where((t) => !t.isMaxLevel)`. 없으면 `l.forgeNoEnhanceable` 안내. 하나만 선택 가능 (라디오처럼). 하단 CTA `l.forgeNext`, 선택 전엔 비활성.
4. 강화 STEP2: 상단에 대상 카드 고정 + `l.forgeRate(rate)` + `l.forgeWarn` + `l.forgeRateHint`. 후보 = `tickets.where((t) => t.id != targetId)`, 정렬은 기존 `enhance_sheet.dart:84-93` 의 규칙(같은 행운권 우선 → 상위 등급 → 저레벨)을 그대로 옮긴다. `need = target.materialsNeeded`. 정확히 `need` 장 고르면 CTA `l.forgeRunEnhance(picked, need)` 활성.
   - `rate = target.successRateWith(pickedCards)` — 고를 때마다 갱신.
   - 실행: `await runEnhanceFlow(context, ref, targetId: target.id, materialIds: _picked.toList(), rate: rate);` 그 뒤 `if (mounted) Navigator.of(context).maybePop();` (지갑으로 복귀).
5. 재조합: 후보 = 전 카드, 정렬은 기존 `reforge_sheet.dart:71-76` 규칙(하위 등급 → 저레벨). `need = TicketInstance.reforgeMaterials`. 상단에 `l.forgeStepReforge(need)` + `l.forgeReforgeHint(TicketInstance.reforgeUpgradeRate)`. CTA `l.forgeRunReforge(picked, need)`.
   - 실행: `await runReforgeFlow(context, ref, materialIds: _picked.toList());` 그 뒤 `maybePop()`.
6. `PopScope` — 강화 STEP2 에서 뒤로가기를 누르면 화면을 닫지 말고 STEP1 으로 돌아간다 (`_targetId = null; _picked.clear();`).
7. 상단 앱바: 좌측 뒤로가기(`TossEmoji` 아님 — `Icons.arrow_back_ios_new_rounded` 유지), 중앙 타이틀 (`l.forgeEnhanceCta` / `l.forgeReforgeCta`), 좌측 상단 모드 이모지 `TossEmoji(TossFace.star)` / `TossEmoji(TossFace.recycle)`.
8. 스크롤 리스트 + 하단 고정 CTA (`SafeArea` bottom).

- [ ] **Step 4: 옛 시트를 지운다**

```bash
git rm lib/widgets/enhance_sheet.dart lib/widgets/reforge_sheet.dart
```

- [ ] **Step 5: 테스트가 통과하는지 확인한다**

Run: `flutter test test/forge_screen_test.dart`
Expected: PASS (2 tests)

`flutter analyze` 는 아직 `dex_screen.dart` 가 지워진 시트를 import 하므로 에러가 난다 — Task 6에서 해소한다.

- [ ] **Step 6: 커밋**

```bash
git add lib/screens/forge_screen.dart test/forge_screen_test.dart
git commit -m "feat: 재조합·강화 풀스크린 선택 화면, 바텀시트 제거"
```

---

## Task 6: 지갑 화면 재개편

**Files:**
- Modify: `lib/screens/dex_screen.dart` (전면 수정)
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `forgeRoute` / `ForgeMode` (Task 5), `TossEmoji`/`TossFace` (Task 1), `dexOwnedCount` / `dexRarityCount` / `forgeEnhanceCta` / `forgeReforgeCta` / `forgeNoEnhanceable` / `forgeNotEnoughCards` (Task 2), `showAppToast`
- Produces: 없음 (말단 화면)

- [ ] **Step 1: 기존 지갑 테스트가 무엇을 기대하는지 읽는다**

Run: `grep -n "dex\|지갑\|3/30\|강화" test/widget_test.dart`

지갑 화면을 검증하는 테스트가 있으면 그 기대값을 아래 Step 2에서 갱신한다. 없으면 Step 2에서 새로 추가한다.

- [ ] **Step 2: 실패하는 테스트를 쓴다**

`test/widget_test.dart` 에 아래 테스트를 추가한다 (기존 파일의 헬퍼/`_host` 패턴을 따른다):

```dart
testWidgets('wallet shows owned counts only, and no per-ticket enhance button',
    (tester) async {
  // 카드 3장을 가진 상태로 지갑을 띄운다 (기존 파일의 시드 헬퍼 사용).
  await tester.pumpWidget(_host(const DexScreen()));
  await tester.pumpAndSettle();

  // 도감 전체 수(예: 3/30)는 어디에도 없다.
  expect(find.textContaining('/30'), findsNothing);
  expect(find.textContaining('/70'), findsNothing);

  // 상단 기능 버튼 두 개.
  expect(find.text('재조합'), findsOneWidget);
  expect(find.text('강화하기'), findsOneWidget);

  // 티켓 행 안에는 강화 버튼이 없다 — 상단 버튼이 유일한 진입점.
  expect(find.text('강화하기'), findsOneWidget);
});
```

- [ ] **Step 3: 테스트를 돌려 실패를 확인한다**

Run: `flutter test test/widget_test.dart`
Expected: FAIL — `'/30'` 을 찾았거나 `'재조합'`/`'강화하기'` 개수가 안 맞는다

- [ ] **Step 4: `dex_screen.dart` 를 고친다**

1. import 에서 `enhance_sheet.dart`, `reforge_sheet.dart` 를 지우고 `../screens/forge_screen.dart`(같은 폴더이므로 `forge_screen.dart`), `../theme/toss_face.dart`, `../widgets/app_toast.dart` 를 추가한다.
2. 상단 `Row`(현재 39–95행)를 아래 구조로 바꾼다:
   - 부제 + 우측 칩 `l.dexOwnedCount(tickets.length)` (배경 `AppColors.accentSoft`).
   - 그 아래 새 `Row`: `Expanded(_actionButton(재조합))` + `SizedBox(width: 10)` + `Expanded(_actionButton(강화하기))`, 높이 52, `AppRadius.button`.
3. `_actionButton` 규칙:
   - 재조합: 활성 조건 `tickets.length >= TicketInstance.reforgeMaterials`. 아이콘 `TossEmoji(TossFace.recycle, size: 18)`, 라벨 `l.forgeReforgeCta`, 배경 `AppColors.card` + 글자 `AppColors.sub`.
   - 강화: 활성 조건 `tickets.any((t) => !t.isMaxLevel)`. 아이콘 `TossEmoji(TossFace.star, size: 18)`, 라벨 `l.forgeEnhanceCta`, 배경 `AppColors.accent` + 글자 흰색.
   - 비활성이면 배경 `AppColors.card` + 글자 `AppColors.disabled`, 탭하면 라우트로 가지 않고 토스트:
     `showAppToast(context, l.forgeNotEnoughCards(TicketInstance.reforgeMaterials))` / `showAppToast(context, l.forgeNoEnhanceable)`
   - 활성이면 `Navigator.of(context).push(forgeRoute(ForgeMode.reforge | ForgeMode.enhance))`
4. `_raritySection` 헤더(157행): `Text('$ownedKinds/${pool.length}')` → `Text(l.dexRarityCount(cards.length))`. `pool`, `ownedKinds`, `kinds` 파라미터는 더 이상 안 쓰면 지운다 (`poolIds` 는 카드 필터에 여전히 필요하다).
5. `_TicketRow` 스텁(264–286행): `_enhanceButton(...)` 호출을 지우고, 스텁은 `+N`(있을 때) 과 만렙일 때 `TossEmoji(TossFace.crown, size: 18)` 만 보여준다. `_enhanceButton` 메서드 전체와 `l.dexEnhanceCta` / `l.dexEnhanceMax` 사용을 제거한다. `card.plus == 0 && !card.isMaxLevel` 이면 스텁은 `CloverMark(size: 22, color: style.color)` 하나만 둔다 (빈칸 방지).
6. 카드 탭은 그대로 `ticketRoute(card.id)`.

- [ ] **Step 5: 전체 테스트와 정적 분석**

Run: `flutter analyze && flutter test`
Expected: analyze 이슈 0건, 모든 테스트 PASS. 지워진 시트를 참조하는 곳이 남아 있으면 여기서 잡힌다.

- [ ] **Step 6: 커밋**

```bash
git add lib/screens/dex_screen.dart test/widget_test.dart
git commit -m "feat: 행운 지갑 재개편 — 상단 재조합/강화 버튼, 보유 장수 표기, 스텁 강화 버튼 제거"
```

---

## Task 7: 실제 앱에서 확인

**Files:** 없음 (검증 전용)

- [ ] **Step 1: 에뮬레이터에서 앱을 띄운다**

메모리의 `ooloo-local-run-setup` 절차를 따른다 (에뮬레이터 `ooloo_emu`). 안 되면 사람에게 물어본다.

Run: `flutter run -d ooloo_emu`

- [ ] **Step 2: 손으로 확인한다**

1. 행운 지갑 탭 — 상단에 `♻️ 재조합` / `⭐ 강화하기` 두 버튼이 보이고, 이모지가 **네모(tofu)로 깨지지 않는다**. 이게 깨지면 폰트 등록이 잘못된 것이다.
2. 등급 헤더에 `일반 3장` 처럼 보유 장수만 뜬다. `/30` 같은 표기가 없다.
3. 티켓 카드 오른쪽 스텁에 강화 버튼이 없다.
4. 강화하기 → 대상 고르기 → 다음 → 재료 고르기 → 강화하기. 흡수 → 게이지 → 정지 → 성공/실패 연출이 끝까지 재생되고, 확인을 누르면 지갑으로 돌아온다. 지갑의 카드 상태가 결과대로 갱신돼 있다.
5. 재조합 → 3장 선택 → 재조합하기. 새 카드 등장 연출.
6. 카드가 0장/1장인 계정에서 두 버튼이 비활성이고, 눌렀을 때 안내 토스트가 뜬다.

- [ ] **Step 3: 스크린샷을 찍어 사람에게 보고한다**

지갑 화면 + 강화 성공 연출 + 강화 실패 연출, 최소 3장.

---

## Self-Review

**스펙 커버리지**
- 지갑 상단 기능 버튼 → Task 6
- 전용 풀스크린 선택 화면(강화 2단계 / 재조합 1단계) → Task 5
- 극적인 연출(흡수 → 게이지 → 정지 → 성공/실패) → Task 3(페인터) + Task 4(시퀀스)
- 보유 장수만 표기, 도감 전체 수 비노출 → Task 6 (+ Global Constraints)
- 스텁 강화 버튼 제거 → Task 6 Step 4-5
- Toss Face 이모지 (♻️ 재조합 / ⭐ 강화) → Task 1, 적용은 Task 5·6
- l10n ko/en/ja → Task 2
- 서버 무변경 → Global Constraints
- 테스트 → 각 Task 및 Task 7 수동 검증

**타입 일관성 확인**
- `ForgeMode` 는 Task 5에서 정의되고 Task 6에서 소비된다. ✓
- `runEnhanceFlow(context, ref, targetId:, materialIds:, rate:)` / `runReforgeFlow(context, ref, materialIds:)` — Task 4 정의, Task 5 소비. 시그니처 동일. ✓
- `ForgePickCard` — Task 5에서 정의, Task 5 테스트에서 사용. ✓
- `TossFace.recycle/star/crown/party/boom/sparkles`, `TossEmoji(String, {double size})` — Task 1 정의, Task 4·5·6 소비. ✓
- `EnhanceOutcome{instanceId, ticketId, success, level, rate}`, `ReforgeOutcome{instance, isNew, upgraded}` — 기존 `lib/data/game_backend.dart:80-105` 그대로. ✓
- l10n 게터 이름은 Task 2의 ARB 키와 Task 4·5·6의 사용처가 일치한다. ✓
