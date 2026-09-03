import 'package:shared_preferences/shared_preferences.dart';

import 'game_backend.dart';
import 'local_game_backend.dart';
import 'state_cache.dart';

// ════════════════════════════════════════════════════════════════
//  웹 데모용 백엔드 — 서버 대신 [LocalGameBackend] 의 규칙을 브라우저 안에서
//  그대로 돌린다. 규칙이 서버 RPC 와 1:1 이라 데모도 실제와 똑같이 움직이되,
//  쓰기가 실서비스 Supabase 에 닿지 않는다. (왜 필요한지는 config/app_mode.dart)
//
//  진행 상황은 [StateCache] 사본으로 잇는다. AppController 가 상태 변화마다
//  사본을 남기므로(SharedPreferences → 브라우저 localStorage), 첫 실행 때
//  그 사본을 씨앗으로 넣어주기만 하면 새로고침을 견딘다.
// ════════════════════════════════════════════════════════════════

/// 데모에서 무료 코인을 마지막으로 받은 날 — 사본(AppState)에 없는 값이라
/// 따로 남긴다. 없으면 새로고침 한 번마다 코인이 하나씩 늘어난다.
const _freeCoinDateKey = 'luckypicky_demo_free_coin_date';

class DemoGameBackend extends LocalGameBackend {
  /// 이관은 이미 끝난 것으로 둔다 — 데모에는 서버로 옮길 옛 데이터가 없다.
  DemoGameBackend() : super(importedLocal: true);

  final StateCache _cache = const StateCache();
  bool _restored = false;

  static String _today() {
    final d = DateTime.now().toUtc();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${p(d.month)}.${p(d.day)}';
  }

  @override
  Future<void> ensureSignedIn() async {
    if (_restored) return;
    _restored = true; // 실패해도 다시 시도하지 않는다 — 빈 상태로 시작하면 된다.
    final cached = await _cache.read();
    if (cached != null) restore(cached);
  }

  @override
  Future<DailyCoinResult> claimDailyCoin() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _today();
    if (prefs.getString(_freeCoinDateKey) == today) {
      final snap = await fetchState();
      return DailyCoinResult(claimed: false, coins: snap.data.coins);
    }
    final result = await super.claimDailyCoin();
    if (result.claimed) await prefs.setString(_freeCoinDateKey, today);
    return result;
  }
}
