import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ════════════════════════════════════════════════════════════════
//  광고 동의 (UMP — Google User Messaging Platform)
//
//  EEA·영국처럼 동의가 필요한 지역에서는 광고 SDK 초기화 전에 동의를 받아야
//  한다. 안 받으면 AdMob 정책 위반이고 해당 지역 노출이 사실상 막힌다.
//  동의가 필요 없는 지역(한국·일본·미국 등)에서는 폼이 뜨지 않고 그냥 통과한다.
//
//  실패해도 앱을 막지 않는다 — 동의 정보를 못 받으면 canRequestAds 가 false 로
//  남아 광고만 빠지고, 나머지 기능은 그대로 돈다.
// ════════════════════════════════════════════════════════════════
class ConsentGate {
  ConsentGate._();
  static final ConsentGate instance = ConsentGate._();

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// 동의 정보를 갱신하고, 필요하면 동의 폼을 띄운다.
  /// 폼이 닫히거나(또는 필요 없거나) 실패하면 완료된다 — 절대 매달리지 않는다.
  Future<void> gather() async {
    if (!_supported) return;
    final done = Completer<void>();
    void finish([Object? _]) {
      if (!done.isCompleted) done.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        // 동의가 필요한 지역이면 폼을 띄우고, 아니면 즉시 반환된다.
        await ConsentForm.loadAndShowConsentFormIfRequired((err) {
          if (err != null) debugPrint('Consent form: ${err.message}');
          finish();
        });
      },
      (err) {
        debugPrint('Consent info update failed: ${err.message}');
        finish();
      },
    );

    // 네트워크가 죽어 콜백이 영영 안 오는 경우까지 대비 — 광고만 포기하고 진행.
    return done.future.timeout(const Duration(seconds: 15), onTimeout: () {});
  }

  /// 광고를 요청해도 되는 상태인지. 동의 거부·미수집이면 false.
  Future<bool> canRequestAds() async {
    if (!_supported) return false;
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      return false;
    }
  }

  /// '광고 개인정보 설정' 진입점을 노출해야 하는 지역인지.
  /// 동의를 받은 지역에서는 언제든 다시 열 수 있어야 한다 (UMP 요구사항).
  Future<bool> privacyOptionsRequired() async {
    if (!_supported) return false;
    try {
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  /// 이미 받은 동의를 다시 열어 변경하게 한다.
  Future<void> showPrivacyOptions() async {
    if (!_supported) return;
    await ConsentForm.showPrivacyOptionsForm((err) {
      if (err != null) debugPrint('Privacy options form: ${err.message}');
    });
  }
}
