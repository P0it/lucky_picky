import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════
//  전역 오류 수집기
//
//  릴리스 빌드에서 잡히지 않은 예외는 아무 흔적도 남기지 않는다 — 스토어 콘솔의
//  난독화된 스택 하나만 보고 원인을 추측해야 한다. 그래서 오류가 흘러나가는
//  경로를 한 곳으로 모은다:
//    - FlutterError.onError            : 위젯 빌드/레이아웃/페인트 중 예외
//    - PlatformDispatcher.onError      : 프레임워크 밖(비동기 콜백 등)의 예외
//    - runZonedGuarded                 : 그 둘도 못 잡는 잔여 비동기 예외
//
//  ※ 이 파일은 "수집 지점"만 만든다. 실제 원격 리포팅(Crashlytics/Sentry)은
//    계정과 DSN 이 있어야 붙일 수 있다 — [reportError] 안의 표시된 한 줄에
//    SDK 호출을 넣으면 세 경로가 전부 그리로 흘러간다.
// ════════════════════════════════════════════════════════════════

/// 오류 한 건을 기록한다. 여기서 죽으면 안 된다 — 수집기 자신이 던지면
/// 오류 처리 경로가 통째로 무너진다.
void reportError(Object error, StackTrace? stack, {String? context}) {
  try {
    if (kDebugMode) {
      // 개발 중에는 콘솔에 그대로. 스택까지 봐야 원인이 잡힌다.
      debugPrint('[error]${context == null ? '' : ' ($context)'} $error');
      if (stack != null) debugPrintStack(stackTrace: stack);
      return;
    }
    // 릴리스: 최소한 OS 로그(logcat / Console.app)에는 남긴다.
    developer.log(
      error.toString(),
      name: context ?? 'luckypicky',
      error: error,
      stackTrace: stack,
    );
    // TODO(출시): 원격 리포팅 SDK 를 붙일 자리.
    //   예) await Sentry.captureException(error, stackTrace: stack);
  } catch (_) {
    // 수집 실패는 삼킨다.
  }
}

/// 앱 시작 시 한 번. 프레임워크가 오류를 흘리는 두 경로를 [reportError] 로 묶고,
/// 화면이 깨졌을 때 회색/빨간 오류 상자 대신 담백한 안내를 보여준다.
void installErrorHandlers() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    reportError(details.exception, details.stack, context: 'flutter');
    previous?.call(details); // 디버그 콘솔의 기존 출력은 그대로 유지.
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    reportError(error, stack, context: 'platform');
    return true; // 처리했음 — 앱을 죽이지 않는다.
  };

  // 릴리스에서만 교체한다. 개발 중에는 빨간 오류 상자가 더 유용하다.
  if (!kDebugMode) {
    ErrorWidget.builder = (details) => const _QuietErrorBox();
  }
}

/// 한 위젯이 깨졌을 때 그 자리에 들어가는 조용한 대체 화면.
class _QuietErrorBox extends StatelessWidget {
  const _QuietErrorBox();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFFFFFFF),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '🍀',
            style: TextStyle(fontSize: 28),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
