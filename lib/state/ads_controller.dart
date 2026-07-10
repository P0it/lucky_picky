import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

/// 전면(인터스티셜) + 보상형(리워드) 광고 관리.
/// 광고 ID 설정은 [AdConfig] (lib/config/ad_config.dart) 한 곳에서 관리합니다.
class AdsController {
  AdsController._();
  static final AdsController instance = AdsController._();

  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;
  int _interstitialRetries = 0;

  RewardedAd? _rewarded;
  bool _loadingRewarded = false;
  int _rewardedRetries = 0;

  static const _maxRetries = 4;

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// 보상형 광고가 지금 준비되어 있는지 — 무료 뽑기 버튼 활성화 판단용.
  bool get rewardedReady => _rewarded != null;

  /// 앱 시작 시 1회, 그리고 광고 소비 후마다 미리 로드.
  void preload() {
    _preloadInterstitial();
    _preloadRewarded();
  }

  // ── 전면 광고 ──────────────────────────────────────────────

  /// 로드 실패(No fill 등)는 일시적일 수 있어 지수 백오프로 재시도한다.
  void _preloadInterstitial() {
    if (!_supported || _loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
          _interstitialRetries = 0;
        },
        onAdFailedToLoad: (err) {
          _interstitial = null;
          _loadingInterstitial = false;
          debugPrint('Interstitial load failed: $err');
          // 일시적 실패는 재시도(2s, 4s, 8s, 16s). 소진 시 다음 소비 때 다시 시도.
          if (_interstitialRetries < _maxRetries) {
            _interstitialRetries++;
            Future.delayed(
                Duration(seconds: 1 << _interstitialRetries), _preloadInterstitial);
          }
        },
      ),
    );
  }

  /// 전면 광고를 보여준다. 광고가 닫히거나 표시 불가하면 [onDone] 호출.
  /// 광고 유무와 무관하게 [onDone] 은 반드시 한 번 실행된다.
  void showInterstitial({required VoidCallback onDone}) {
    final ad = _interstitial;
    if (!_supported || ad == null) {
      onDone();
      _preloadInterstitial(); // 다음 기회를 위해 재시도
      return;
    }
    _interstitial = null; // 소비

    var finished = false;
    void finishOnce() {
      if (finished) return;
      finished = true;
      _preloadInterstitial(); // 다음 광고 미리 로드
      onDone();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        finishOnce();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        debugPrint('Interstitial show failed: $err');
        finishOnce();
      },
    );
    ad.show();
  }

  // ── 보상형 광고 ────────────────────────────────────────────

  void _preloadRewarded() {
    if (!_supported || _loadingRewarded || _rewarded != null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
          _rewardedRetries = 0;
        },
        onAdFailedToLoad: (err) {
          _rewarded = null;
          _loadingRewarded = false;
          debugPrint('Rewarded load failed: $err');
          if (_rewardedRetries < _maxRetries) {
            _rewardedRetries++;
            Future.delayed(
                Duration(seconds: 1 << _rewardedRetries), _preloadRewarded);
          }
        },
      ),
    );
  }

  /// 보상형 광고를 보여준다.
  /// - 사용자가 끝까지 시청해 보상을 얻으면 [onReward] 호출.
  /// - 광고가 닫히면(보상 여부 무관) [onDone] 호출.
  /// - 미지원/미로드 플랫폼(개발 데스크톱 등)에서는 편의상 즉시 보상 처리한다.
  void showRewarded({required VoidCallback onReward, VoidCallback? onDone}) {
    final ad = _rewarded;
    if (!_supported) {
      onReward();
      onDone?.call();
      return;
    }
    if (ad == null) {
      // 로드 전이면 보상 없이 종료 — 버튼측에서 rewardedReady 로 막는 것이 기본.
      onDone?.call();
      _preloadRewarded();
      return;
    }
    _rewarded = null; // 소비

    var rewarded = false;
    var finished = false;
    void finishOnce() {
      if (finished) return;
      finished = true;
      _preloadRewarded();
      if (rewarded) onReward();
      onDone?.call();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        finishOnce();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        debugPrint('Rewarded show failed: $err');
        finishOnce();
      },
    );
    ad.show(onUserEarnedReward: (_, reward) => rewarded = true);
  }
}
