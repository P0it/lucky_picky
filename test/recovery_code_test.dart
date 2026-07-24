import 'package:flutter_test/flutter_test.dart';

import 'package:luckypicky/data/game_backend.dart';
import 'package:luckypicky/data/local_game_backend.dart';
import 'package:luckypicky/models/app_state.dart';

void main() {
  /// 같은 저장소를 공유하는 두 계정(=두 기기/브라우저).
  (LocalGameBackend, LocalGameBackend) twoAccounts({AppState? seedA}) {
    final store = LocalRecoveryStore();
    final a = LocalGameBackend(seed: seedA, recovery: store);
    final b = LocalGameBackend(recovery: store);
    return (a, b);
  }

  Future<AppState> stateOf(LocalGameBackend b) async =>
      (await b.fetchState()).data;

  group('복구 코드', () {
    test('발급은 멱등이다 — 같은 계정은 늘 같은 코드', () async {
      final (a, _) = twoAccounts();
      final first = await a.issueRecoveryCode();
      final second = await a.issueRecoveryCode();
      expect(first, isNotEmpty);
      expect(second, first);
    });

    test('코드로 복구하면 옛 계정의 자산이 새 계정으로 옮겨온다', () async {
      final (a, b) = twoAccounts(
          seedA: const AppState(leaves: 3, clovers: 7, coins: 2, statPulls: 4));
      final code = await a.issueRecoveryCode();

      // 새 기기 b 는 빈 계정.
      expect((await stateOf(b)).clovers, 0);

      await b.redeemRecoveryCode(code);

      final movedTo = await stateOf(b);
      expect(movedTo.clovers, 7);
      expect(movedTo.leaves, 3);
      expect(movedTo.coins, 2);
      expect(movedTo.statPulls, 4);

      // 옛 계정 a 는 빈 계정으로 초기화된다.
      final emptied = await stateOf(a);
      expect(emptied.clovers, 0);
      expect(emptied.leaves, 0);
    });

    test('코드는 자산을 따라간다 — 복구 후 그 코드로 다시 되찾을 수 있다', () async {
      final store = LocalRecoveryStore();
      final a = LocalGameBackend(
          seed: const AppState(clovers: 9), recovery: store);
      final b = LocalGameBackend(recovery: store);
      final c = LocalGameBackend(recovery: store);

      final code = await a.issueRecoveryCode();
      await b.redeemRecoveryCode(code); // a → b
      expect((await stateOf(b)).clovers, 9);

      // 같은 코드로 c 가 복구하면, 이제 자산이 있는 b 에서 가져온다.
      await c.redeemRecoveryCode(code);
      expect((await stateOf(c)).clovers, 9);
      expect((await stateOf(b)).clovers, 0);
    });

    test('없는 코드는 RECOVERY_NOT_FOUND', () async {
      final (_, b) = twoAccounts();
      expect(
        () => b.redeemRecoveryCode('없는 코드 이상한 조합'),
        throwsA(isA<GameRuleException>().having(
            (e) => e.code, 'code', GameRuleException.recoveryNotFound)),
      );
    });

    test('자기 코드를 넣으면 아무 일도 없다 (no-op)', () async {
      final (a, _) = twoAccounts(seedA: const AppState(clovers: 5));
      final code = await a.issueRecoveryCode();
      await a.redeemRecoveryCode(code);
      expect((await stateOf(a)).clovers, 5);
    });

    test('정규화 — 공백·대소문자가 달라도 같은 코드로 인식된다', () async {
      final (a, b) = twoAccounts(seedA: const AppState(clovers: 3));
      final code = await a.issueRecoveryCode();
      // 공백을 뭉개고 구분자를 섞어 넣어도 통과해야 한다.
      final messy = '  ${code.replaceAll(' ', '·')}  ';
      await b.redeemRecoveryCode(messy);
      expect((await stateOf(b)).clovers, 3);
    });
  });
}
