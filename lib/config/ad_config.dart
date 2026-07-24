import 'dart:io' show Platform;

// ════════════════════════════════════════════════════════════════
//  광고 설정 — 출시 전 "여기 한 파일"만 바꾸면 됩니다.
//
//  [1] 광고단위 ID (이 파일에서 처리):
//      1) 실 ID 를 넣은 플랫폼의 _useTestAds{Android,Ios} 를 false 로 바꾸고
//      2) 아래 _android*/_ios* 상수에 발급받은
//         실제 광고단위 ID 를 입력하세요.
//      토글은 플랫폼별로 나뉘어 있다 — Android/iOS 는 실 ID 준비 시점이
//      다를 수 있어, 준비된 쪽만 먼저 실광고로 전환한다.
//      광고단위는 2종입니다:
//      - 전면(interstitial): 클로버 완성 직후 + 뽑기 3회차마다
//      - 보상형(rewarded): 무료 뽑기 / 한 번 더 뽑기
//
//  [2] 앱 ID (네이티브 파일 — Dart 에서 못 읽어 아래 2곳을 직접 수정):
//      - Android: android/app/src/main/AndroidManifest.xml
//          meta-data  com.google.android.gms.ads.APPLICATION_ID
//          android:value="ca-app-pub-XXXXXXXX~YYYYYYYY"
//      - iOS:     ios/Runner/Info.plist
//          key  GADApplicationIdentifier
//          string  ca-app-pub-XXXXXXXX~YYYYYYYY
//
//  주의: 테스트 ID 는 수익이 발생하지 않습니다. 본인 앱 광고는 직접 클릭 금지!
// ════════════════════════════════════════════════════════════════
class AdConfig {
  /// 플랫폼별 테스트 광고 토글.
  /// true  : Google 공식 테스트 광고 (개발/테스트용, 수익 0)
  /// false : 실제 광고 (출시용) — 해당 플랫폼 슬롯에 실 ID + 앱 ID 필수.
  static const bool _useTestAdsAndroid = false; // Android 실 ID 적용됨
  static const bool _useTestAdsIos = false; //     iOS 실 ID 적용됨

  // ── 실제 광고단위 ID (해당 플랫폼 토글이 false 일 때 사용) ──
  static const String _androidInterstitial = 'ca-app-pub-4235844602701475/9466544015';
  static const String _iosInterstitial = 'ca-app-pub-4235844602701475/4162512379';
  static const String _androidRewarded = 'ca-app-pub-4235844602701475/4513866169';
  static const String _iosRewarded = 'ca-app-pub-4235844602701475/6676995071';

  // ── Google 공식 테스트 광고단위 ID (수정 금지) ──
  static const String _androidTestInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String _iosTestInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const String _androidTestRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const String _iosTestRewarded = 'ca-app-pub-3940256099942544/1712485313';

  /// 현재 플랫폼/모드에 맞는 전면 광고단위 ID.
  static String get interstitial {
    if (Platform.isIOS) {
      return _useTestAdsIos ? _iosTestInterstitial : _iosInterstitial;
    }
    return _useTestAdsAndroid ? _androidTestInterstitial : _androidInterstitial;
  }

  /// 현재 플랫폼/모드에 맞는 보상형 광고단위 ID.
  static String get rewarded {
    if (Platform.isIOS) {
      return _useTestAdsIos ? _iosTestRewarded : _iosRewarded;
    }
    return _useTestAdsAndroid ? _androidTestRewarded : _androidRewarded;
  }
}
