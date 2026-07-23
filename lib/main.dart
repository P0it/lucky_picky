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
import 'widgets/app_loading_screen.dart';

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

/// Supabase 초기화 — `runApp` 전에 await 하면 그동안 화면이 비어 있으므로,
/// 앱을 먼저 띄우고 이 provider 가 끝날 때까지 로딩 화면을 보여준다.
final bootstrapProvider = FutureProvider<void>((ref) async {
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseKey);
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Android: 어두운 아이콘
    statusBarBrightness: Brightness.light, // iOS: 밝은 배경 → 어두운 아이콘
  ));
  runApp(const ProviderScope(child: LuckyPickyApp()));
}

/// 넓은 화면(웹/데스크톱)에서 앱을 폰 폭으로 가운데 고정한다.
/// 실제 모바일 기기처럼 좁은 화면에서는 전체 폭을 그대로 사용한다.
class _PhoneFrame extends StatelessWidget {
  static const _maxWidth = 430.0;
  final Widget child;
  const _PhoneFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width <= _maxWidth) return child;
    return ColoredBox(
      color: const Color(0xFF191F28), // 양옆 레터박스 배경
      child: Center(
        child: ClipRect(
          child: SizedBox(width: _maxWidth, child: child),
        ),
      ),
    );
  }
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
      // 데스크톱/웹의 넓은 폭에서는 폰 크기로 가운데 고정, 양옆은 여백.
      builder: (context, child) => _PhoneFrame(child: child!),
      home: const _Bootstrap(),
    );
  }
}

/// 초기화가 끝나면 홈으로, 그 전까지는 로딩 화면을 보여준다.
class _Bootstrap extends ConsumerWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(bootstrapProvider).when(
          data: (_) => const HomeShell(),
          loading: () => const AppLoadingScreen(),
          error: (_, _) => AppLoadingErrorScreen(
            onRetry: () => ref.invalidate(bootstrapProvider),
          ),
        );
  }
}
