import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/copy_book.dart';

// ════════════════════════════════════════════════════════════════
//  문구 소스 — Supabase copy_lines_active 뷰에서 "오늘 유효한" 문구를 받아온다.
//
//  가용성 우선순위:
//    1) 서버 응답  2) 마지막으로 받은 캐시  3) 앱 번들 문구(config/*.dart)
//  네트워크가 죽어도 문구는 항상 나온다. 서버 문구가 아예 없어도(테이블 빈 상태)
//  번들로 동작하므로, 마이그레이션만 올려두고 문구는 나중에 채워도 된다.
//
//  갱신 시점: 앱 시작 시 1회. 유행어 교체는 하루 단위 이슈라 이걸로 충분하다.
// ════════════════════════════════════════════════════════════════

const _prefsKey = 'luckypicky_copy_v1';

final copyBookProvider = NotifierProvider<CopyController, CopyBook>(
  CopyController.new,
);

class CopyController extends Notifier<CopyBook> {
  @override
  CopyBook build() {
    _load();
    return CopyBook.bundled;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) 캐시부터 즉시 반영 — 서버 응답을 기다리는 동안 낡은 번들 문구가 보이지 않게.
    final cached = _decode(prefs.getString(_prefsKey));
    if (cached != null) state = cached;

    // 2) 서버 최신본으로 덮어쓰기. 실패하면 캐시/번들 유지.
    try {
      final rows = await Supabase.instance.client
          .from('copy_lines_active')
          .select('surface,lang,grade,text');
      final lines = [for (final r in rows) CopyLine.fromJson(r)];
      // 서버가 비어 있으면(문구를 아직 안 넣었으면) 번들을 쓰는 게 맞다.
      // 캐시도 지워야 "서버에서 문구를 내린" 의도가 다음 실행에도 반영된다.
      if (lines.isEmpty) {
        await prefs.remove(_prefsKey);
        state = CopyBook.bundled;
        return;
      }
      final book = CopyBook.fromLines(lines);
      state = book;
      await prefs.setString(_prefsKey, jsonEncode(book.toJson()));
    } catch (_) {
      // 오프라인·장애 — 이미 반영한 캐시(없으면 번들)로 계속 간다.
    }
  }

  CopyBook? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      if (list.isEmpty) return null;
      return CopyBook.fromLines([
        for (final e in list) CopyLine.fromJson(e as Map<String, dynamic>),
      ]);
    } catch (_) {
      return null; // 손상된 캐시는 무시하고 번들로.
    }
  }
}
