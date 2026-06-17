import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'screens/home_shell.dart';
import 'state/ads_controller.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Android: 어두운 아이콘
    statusBarBrightness: Brightness.light, // iOS: 밝은 배경 → 어두운 아이콘
  ));
  runApp(const ProviderScope(child: OolooApp()));
}

class OolooApp extends StatefulWidget {
  const OolooApp({super.key});

  @override
  State<OolooApp> createState() => _OolooAppState();
}

class _OolooAppState extends State<OolooApp> {
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
      title: 'ooloo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeShell(),
    );
  }
}
