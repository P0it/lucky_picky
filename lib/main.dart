import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_shell.dart';
import 'state/ads_controller.dart';
import 'state/locale_controller.dart';
import 'theme/app_theme.dart';

/// Supabase 접속 정보 — publishable key 는 RLS 전제하에 공개 가능한 값.
/// 빌드 시 --dart-define 으로 교체할 수 있다.
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://snejndzqxmwsdmdojmag.supabase.co',
);
const _supabaseKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_cyPflSPV34SN6sg3TUAj2A_MHWJT4u7',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseKey);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Android: 어두운 아이콘
    statusBarBrightness: Brightness.light, // iOS: 밝은 배경 → 어두운 아이콘
  ));
  runApp(const ProviderScope(child: LuckyPickyApp()));
}

class LuckyPickyApp extends ConsumerStatefulWidget {
  const LuckyPickyApp({super.key});

  @override
  ConsumerState<LuckyPickyApp> createState() => _LuckyPickyAppState();
}

class _LuckyPickyAppState extends ConsumerState<LuckyPickyApp> {
  @override
  void initState() {
    super.initState();
    // 첫 프레임 이후에 광고/추적동의 초기화 (ATT 프롬프트는 앱이 활성화된 뒤 떠야 함).
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAds());
  }

  Future<void> _initAds() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    // iOS 14.5+ : 광고 초기화 전에 App Tracking Transparency 권한 요청.
    if (Platform.isIOS) {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    }

    await MobileAds.instance.initialize();
    AdsController.instance.preload();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LuckyPicky',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // null = OS 언어 자동 감지, 값이 있으면 사용자가 고른 언어로 강제.
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeShell(),
    );
  }
}
