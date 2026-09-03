import 'package:flutter/foundation.dart' show kIsWeb;

// ════════════════════════════════════════════════════════════════
//  데모 모드 — 서버에 쓰지 않고 브라우저 안에서만 도는 체험판.
//
//  왜: 웹 빌드에는 광고 SDK 가 없어 보상형이 즉시 보상 처리되고
//  (AdsController.showRewarded 의 미지원 플랫폼 갈래), 익명 로그인은 실서비스
//  Supabase 에 계정을 만든다. 공개 데모를 그대로 올리면 방문자가 실 DB 에
//  계정을 쌓고 무한 코인으로 재화 경제를 깬다.
//
//  그래서 웹에서는 게임 백엔드만 로컬 구현으로 갈아끼운다(DemoGameBackend).
//  쓰기가 서버에 닿지 않으므로 위 두 문제가 동시에 사라진다.
//  문구(copy_lines)는 anon 에게 select 가 열린 읽기 전용이라 그대로 서버에서
//  받아온다 — 데모도 실제 문구로 돈다.
//
//  실서버를 붙인 웹 빌드가 필요하면 `--dart-define=DEMO_MODE=false`.
// ════════════════════════════════════════════════════════════════
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: kIsWeb);
