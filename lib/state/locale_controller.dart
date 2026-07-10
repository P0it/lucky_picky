import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 언어(로케일) 환경설정. 게임 상태(AppController)와는 분리해 관리한다.
/// - `null`  : 시스템 언어 따르기(자동 감지) — MaterialApp이 OS 로케일로 매칭.
/// - Locale  : 사용자가 직접 고른 언어(수동 지정).
const _prefsKey = 'luckypicky_locale_v1';

final localeProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends Notifier<Locale?> {
  SharedPreferences? _prefs;

  @override
  Locale? build() {
    _load();
    return null; // 저장값을 읽기 전까지는 시스템 따르기.
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final code = _prefs?.getString(_prefsKey);
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
    }
  }

  /// [locale] == null 이면 시스템 따르기로 되돌린다.
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    _prefs ??= await SharedPreferences.getInstance();
    if (locale == null) {
      await _prefs!.remove(_prefsKey);
    } else {
      await _prefs!.setString(_prefsKey, locale.languageCode);
    }
  }
}
