import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luckypicky/data/game_backend.dart';
import 'package:luckypicky/l10n/app_localizations.dart';
import 'package:luckypicky/models/ticket_instance.dart';
import 'package:luckypicky/widgets/forge_overlay.dart';
import 'package:luckypicky/widgets/forge_painters.dart';

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

const _target = TicketInstance(id: 'i1', ticketId: 'c02', pulledAt: '');

List<TicketInstance> _materials(int n) => [
      for (var i = 0; i < n; i++)
        TicketInstance(id: 'm$i', ticketId: 'c01', pulledAt: ''),
    ];

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
      ),
      target: _target,
      materials: _materials(2),
      accent: const Color(0xFF6FC143),
    )));

    // 프레임 0 — 아직 흡수 페이즈다. 결과 UI 가 미리 보이면 연출이 통째로 건너뛴 것.
    await tester.pump();
    expect(find.text('강화 성공!'), findsNothing);
    expect(find.text('확인'), findsNothing);

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
      ),
      target: _target,
      materials: _materials(1),
      accent: const Color(0xFF6FC143),
    )));

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('강화 실패…'), findsOneWidget);
  });

  testWidgets('the gauge fills to the SERVER rate, not a client prediction',
      (tester) async {
    // 클라이언트라면 c02(+0) 에 같은 카드 1장 → 100% 로 예측한다.
    // 서버는 원격 설정(game_config)에 따라 35% 로 굴렸다 — 게이지는 서버 값을 따라야 한다.
    const serverRate = 35;
    final material =
        [const TicketInstance(id: 'm0', ticketId: 'c02', pulledAt: '')];
    expect(_target.successRateWith(material), isNot(serverRate));

    await tester.pumpWidget(_host(ForgeOverlay(
      result: const ForgeEnhanceResult(
        outcome: EnhanceOutcome(
          instanceId: 'i1',
          ticketId: 'c02',
          success: false,
          level: 1,
          rate: serverRate,
        ),
        ticketId: 'c02',
      ),
      target: _target,
      materials: material,
      accent: const Color(0xFF6FC143),
    )));

    // 충전 페이즈로 들어간 뒤 게이지를 읽는다.
    await tester.pump(const Duration(milliseconds: 1400));

    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<ForgeGaugePainter>()
        .single;
    expect(painter.rate, closeTo(serverRate / 100, 1e-9));

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
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
      materials: _materials(3),
      accent: const Color(0xFF6FC143),
    )));

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('등급이 올랐어요!'), findsOneWidget);
  });

  testWidgets('plain reforge ends on the new-ticket line, not the tier-up line',
      (tester) async {
    await tester.pumpWidget(_host(ForgeOverlay(
      result: ForgeReforgeResult(
        outcome: const ReforgeOutcome(
          instance: TicketInstance(id: 'n2', ticketId: 'c02', pulledAt: ''),
          isNew: false,
          upgraded: false,
        ),
      ),
      materials: _materials(3),
      accent: const Color(0xFF6FC143),
    )));

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('새 행운이 나왔어요'), findsOneWidget);
    expect(find.text('등급이 올랐어요!'), findsNothing);
  });
}
