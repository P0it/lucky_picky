import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luckypicky/l10n/app_localizations.dart';
import 'package:luckypicky/models/deed.dart';
import 'package:luckypicky/theme/app_theme.dart';
import 'package:luckypicky/widgets/deed_heatmap.dart';

// 히트맵은 달 이름·요일을 intl DateFormat 으로 만든다. 로케일 데이터가 준비되지
// 않은 언어에서는 LocaleDataException 으로 화면이 통째로 깨지는데, 그 사고는
// 한국어로만 돌려보면 절대 안 보인다. 그래서 세 언어를 다 그려본다.
void main() {
  const history = <HistoryEntry>[
    HistoryEntry(
        id: 1, date: '2026.08.03', kind: HistoryKind.deed, text: '길을 알려드렸다', amount: 1),
    HistoryEntry(
        id: 2, date: '2026.08.03', kind: HistoryKind.deed, text: '자리를 양보했다', amount: 1),
    HistoryEntry(
        id: 3, date: '2026.08.11', kind: HistoryKind.deed, text: '쓰레기를 주웠다', amount: 1),
  ];

  Widget app(Locale locale) => MaterialApp(
        theme: buildAppTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: DeedHeatmap(history: history)),
        ),
      );

  for (final code in ['ko', 'en', 'ja']) {
    testWidgets('$code 로케일에서 히트맵이 날짜 서식과 함께 그려진다', (tester) async {
      tester.view.physicalSize = const Size(440, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app(Locale(code)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // 범례는 번역문이 나와야 한다 — 한국어 문구가 새어 나오면 실패.
      final l = AppLocalizations.of(
          tester.element(find.byType(DeedHeatmap)));
      expect(find.text(l.heatmapLegendLow), findsOneWidget);
      expect(find.text(l.heatmapLegendHigh), findsOneWidget);
      expect(find.text(l.heatmapTapHint), findsOneWidget);
      if (code != 'ko') {
        expect(find.text('적음'), findsNothing);
        expect(find.text('많음'), findsNothing);
      }
    });
  }
}
