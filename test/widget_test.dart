import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luckypicky/config/daily_quotes.dart';
import 'package:luckypicky/data/local_game_backend.dart';
import 'package:luckypicky/l10n/app_localizations.dart';
import 'package:luckypicky/models/app_state.dart';
import 'package:luckypicky/screens/home_shell.dart';
import 'package:luckypicky/state/ads_controller.dart';
import 'package:luckypicky/state/app_controller.dart';
import 'package:luckypicky/util/text_wrap.dart';
import 'package:luckypicky/theme/app_theme.dart';

// 테스트는 한국어 로케일로 고정해 기존 한글 단언을 그대로 검증한다.
// 백엔드는 서버 RPC 와 동일 규칙의 로컬 구현(시드: 잎 2 / 클로버 5)을 주입한다.
Widget _app() => ProviderScope(
      overrides: [
        gameBackendProvider.overrideWithValue(LocalGameBackend(
          seed: const AppState(
              leaves: 2, clovers: 5, statLeaves: 2, statClovers: 1),
        )),
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
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app());
    await tester.pump(); // 첫 프레임
    await tester.pump(); // 백엔드 부트스트랩(비동기) 반영
  }

  testWidgets('홈 화면이 렌더링된다 (클로버 페인터 포함)', (tester) async {
    await pumpApp(tester);
    expect(find.text(DailyQuotes.forToday('ko').keepAll), findsOneWidget);
    expect(find.text('오늘의 선행 기록하기'), findsOneWidget);
  });

  testWidgets('탭으로 네 화면을 모두 오갈 수 있다', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('뽑기'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('행운 뽑기'), findsOneWidget);
    expect(find.text('보유한 클로버'), findsOneWidget);
    expect(find.text('클로버로 뽑기'), findsOneWidget);

    await tester.tap(find.text('행운 도감'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('뽑은 행운들이 이곳에 모여요'), findsOneWidget);
    expect(find.text('0/70 수집'), findsOneWidget);

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
    expect(find.text('일반'), findsOneWidget);
    expect(find.text('신화'), findsOneWidget);
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

    // 도감에 1종 등록.
    await tester.tap(find.text('행운 도감'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1/70 수집'), findsOneWidget);
  });
}
