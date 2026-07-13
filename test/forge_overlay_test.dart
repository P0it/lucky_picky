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
