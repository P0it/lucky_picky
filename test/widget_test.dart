import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luckypicky/config/daily_quotes.dart';
import 'package:luckypicky/data/local_game_backend.dart';
import 'package:luckypicky/l10n/app_localizations.dart';
import 'package:luckypicky/models/app_state.dart';
import 'package:luckypicky/models/ticket_instance.dart';
import 'package:luckypicky/screens/home_shell.dart';
import 'package:luckypicky/state/ads_controller.dart';
import 'package:luckypicky/state/app_controller.dart';
import 'package:luckypicky/util/text_wrap.dart';
import 'package:luckypicky/theme/app_theme.dart';
import 'package:luckypicky/widgets/collection_card.dart';

// 테스트는 한국어 로케일로 고정해 기존 한글 단언을 그대로 검증한다.
// 백엔드는 서버 RPC 와 동일 규칙의 로컬 구현(시드: 잎 2 / 클로버 5)을 주입한다.
const _defaultSeed =
    AppState(leaves: 2, clovers: 5, statLeaves: 2, statClovers: 1);

Widget _app({AppState seed = _defaultSeed}) => ProviderScope(
      overrides: [
        gameBackendProvider.overrideWithValue(LocalGameBackend(seed: seed)),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeShell(),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // 모달/시트가 화면 안에 들어오도록 폰 크기 캔버스로 설정.
  Future<void> pumpApp(WidgetTester tester, {AppState seed = _defaultSeed}) async {
    tester.view.physicalSize = const Size(440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(seed: seed));
    await tester.pump(); // 첫 프레임
    await tester.pump(); // 백엔드 부트스트랩(비동기) 반영
  }

  testWidgets('홈 화면이 렌더링된다 (클로버 페인터 포함)', (tester) async {
    await pumpApp(tester);
    expect(find.text(DailyQuotes.forToday('ko').keepAll), findsOneWidget);
    expect(find.text('오늘의 선행 기록하기'), findsOneWidget);
  });

  testWidgets('탭으로 다섯 화면을 모두 오갈 수 있다', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('뽑기'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('행운 뽑기'), findsOneWidget);
    expect(find.text('보유한 클로버'), findsOneWidget);
    expect(find.text('클로버로 뽑기'), findsOneWidget);

    await tester.tap(find.text('운세'));
    await tester.pump(); // prefs 비동기 로드 반영
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('오늘의 행운지수'), findsOneWidget);
    expect(find.text('행운 게이지 돌리기'), findsOneWidget); // 진입만으로는 시작 안 됨

    await tester.tap(find.text('행운 지갑'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('뽑은 행운들이 이곳에 모여요'), findsOneWidget);
    expect(find.text('0장 보유'), findsOneWidget);

    await tester.tap(find.text('나의 기록'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('나의 선행 기록'), findsOneWidget);
    expect(find.text('뽑은 행운'), findsOneWidget);

    await tester.tap(find.text('홈'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('오늘의 선행 기록하기'), findsOneWidget);
  });

  testWidgets('선행 기록 시트로 잎을 채운다', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('오늘의 선행 기록하기'));
    await tester.pump(); // 모달 entrance 시작
    await tester.pump(const Duration(milliseconds: 400)); // entrance 진행 완료(화면 안)
    expect(find.text('어떤 선행을 베푸셨나요?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '쓰레기를 주웠다');
    await tester.pump();
    await tester.tap(find.text('기록 완료하고 잎 채우기'));
    await tester.pump(); // 탭 처리 → pop 예약 + 토스트 삽입
    await tester.pump(const Duration(milliseconds: 400)); // 시트 닫힘 애니메이션
    await tester.pump(const Duration(milliseconds: 400)); // 라우트 제거 + 정착

    // 시트가 닫히고 잎 채움 토스트가 뜬다.
    expect(find.text('어떤 선행을 베푸셨나요?'), findsNothing);
    expect(find.text('잎을 채웠어요'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2200)); // 토스트 타이머 flush
  });

  testWidgets('AdsController 는 비-모바일에서 광고를 스킵하고 보상/완료를 호출한다', (tester) async {
    bool done = false;
    AdsController.instance.showInterstitial(onDone: () => done = true);
    expect(done, true);

    bool rewarded = false;
    AdsController.instance.showRewarded(onReward: () => rewarded = true);
    expect(rewarded, true);
  });

  testWidgets('확률 정보 시트에 등급/확률/비유가 표시된다', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('뽑기'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('확률 정보'));
    await tester.pumpAndSettle();

    expect(find.text('획득 확률'), findsOneWidget);
    expect(find.text('노멀'), findsOneWidget);
    expect(find.text('미스틱'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('2%'), findsOneWidget);
    expect(find.textContaining('로또 1등보다'), findsOneWidget);
  });

  testWidgets('뽑기 → 캡슐 개봉 → 결과 확인 → 도감에 등록된다', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('뽑기'));
    await tester.pump(const Duration(milliseconds: 400)); // 탭 전환 완료

    // 뽑기 시작 → 오버레이 진입(코인 → 레버 → 낙하 연출).
    await tester.tap(find.text('클로버로 뽑기'));
    await tester.pump(); // 라우트 push
    await tester.pump(const Duration(milliseconds: 300)); // 페이드 전환
    await tester.pump(const Duration(milliseconds: 600)); // 코인 투입
    await tester.pump(const Duration(milliseconds: 900)); // 레버 회전
    await tester.pump(const Duration(milliseconds: 800)); // 캡슐 낙하
    await tester.pump(const Duration(milliseconds: 300)); // waitTap 힌트 표시
    expect(find.text('캡슐을 탭해서 열어보세요!'), findsOneWidget);

    // 캡슐 탭 → 버스트 → 결과 카드.
    await tester.tap(find.text('캡슐을 탭해서 열어보세요!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700)); // 버스트
    await tester.pump(const Duration(milliseconds: 500)); // 카드 등장
    expect(find.text('NEW!'), findsOneWidget);
    expect(find.text('좋아요'), findsOneWidget);

    // 확인 → 오버레이 닫힘 (1회차라 전면광고 차례 아님).
    await tester.tap(find.text('좋아요'));
    await tester.pumpAndSettle();
    expect(find.text('행운 뽑기'), findsOneWidget); // 가챠 화면 복귀
    expect(find.text('4개'), findsOneWidget); // 클로버 5 → 4

    // 도감에 1장 등록.
    await tester.tap(find.text('행운 지갑'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1장 보유'), findsOneWidget);
  });

  testWidgets('행운 지갑 — 보유 장수만 보이고, 강화 진입점은 상단 버튼 하나뿐이다',
      (tester) async {
    // 카드 4장(그중 한 장은 만렙)을 가진 지갑.
    const cards = [
      TicketInstance(id: 'i1', ticketId: 'c01', level: 1, pulledAt: '2026.07.13'),
      TicketInstance(id: 'i2', ticketId: 'c01', level: 2, pulledAt: '2026.07.13'),
      TicketInstance(id: 'i3', ticketId: 'c02', level: 5, pulledAt: '2026.07.13'),
      TicketInstance(id: 'i4', ticketId: 'c03', level: 1, pulledAt: '2026.07.13'),
    ];
    await pumpApp(tester,
        seed: const AppState(leaves: 2, clovers: 5, tickets: cards));

    await tester.tap(find.text('행운 지갑'));
    await tester.pump(const Duration(milliseconds: 400));

    // 티켓 행이 4개 그려졌는데도 강화/재조합 버튼은 각각 하나뿐이어야 한다.
    // (행마다 강화 버튼을 박아 두면 여기서 findsNWidgets(4) 가 되어 실패한다)
    expect(find.byType(CollectionCard), findsNWidgets(cards.length));
    expect(find.text('강화하기'), findsOneWidget);
    expect(find.text('재조합'), findsOneWidget);

    // 그 강화 버튼은 티켓 행 밖에 있다 — 행 서브트리 안에는 하나도 없다.
    expect(
      find.descendant(
        of: find.byType(CollectionCard),
        matching: find.text('강화하기'),
      ),
      findsNothing,
    );

    // 도감 전체 수(3/30, 6/70 …)는 어디에도 없다. 보유 장수만 보인다.
    expect(find.textContaining('/30'), findsNothing);
    expect(find.textContaining('/70'), findsNothing);
    expect(find.text('4장 보유'), findsOneWidget);
    expect(find.text('4장'), findsOneWidget); // 노멀 섹션 헤더 (c01/c02/c03 모두 노멀)
  });
}
