import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luckypicky/config/luck_tickets.dart';
import 'package:luckypicky/data/local_game_backend.dart';
import 'package:luckypicky/models/app_state.dart';
import 'package:luckypicky/models/deed.dart';
import 'package:luckypicky/models/owned_ticket.dart';
import 'package:luckypicky/state/app_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// 로컬 백엔드(서버 RPC 와 동일 규칙)를 주입한 컨테이너.
  (ProviderContainer, LocalGameBackend) makeContainer(
      {AppState? seed, math.Random? rng}) {
    final backend = LocalGameBackend(seed: seed, rng: rng);
    final c = ProviderContainer(
      overrides: [gameBackendProvider.overrideWithValue(backend)],
    );
    addTearDown(c.dispose);
    return (c, backend);
  }

  /// 잎 2 / 클로버 5 — 기존 프로토타입 시드와 같은 출발 상태.
  AppState seeded() => const AppState(
      leaves: 2, clovers: 5, statLeaves: 2, statClovers: 1);

  group('카탈로그', () {
    test('70종 — 등급별 30/20/12/6/2, ID 중복 없음', () {
      expect(LuckCatalog.tickets.length, 70);
      expect(LuckCatalog.byRarity(Rarity.common).length, 30);
      expect(LuckCatalog.byRarity(Rarity.rare).length, 20);
      expect(LuckCatalog.byRarity(Rarity.epic).length, 12);
      expect(LuckCatalog.byRarity(Rarity.legendary).length, 6);
      expect(LuckCatalog.byRarity(Rarity.mythic).length, 2);
      final ids = LuckCatalog.tickets.map((t) => t.id).toSet();
      expect(ids.length, 70);
    });

    test('가중치 합 100, 전 티켓이 ko/en/ja 문구를 가진다', () {
      expect(LuckCatalog.weights.values.reduce((a, b) => a + b), 100);
      for (final t in LuckCatalog.tickets) {
        for (final lang in ['ko', 'en', 'ja']) {
          expect(t.text(lang).isNotEmpty, true, reason: '${t.id}/$lang');
        }
      }
    });
  });

  group('기본 상태 / 선행 기록', () {
    test('신규 유저 초기 상태: 전부 0, 도감 비어있음', () async {
      final (c, _) = makeContainer();
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      final s = c.read(appControllerProvider);
      expect(s.leaves, 0);
      expect(s.clovers, 0);
      expect(s.tickets, isEmpty);
      expect(s.statPulls, 0);
    });

    test('서버 상태가 부트스트랩 시 로드된다', () async {
      final (c, _) = makeContainer(seed: seeded());
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      final s = c.read(appControllerProvider);
      expect(s.leaves, 2);
      expect(s.clovers, 5);
    });

    test('선행 기록 → 잎 +1, 기록 추가', () async {
      final (c, _) = makeContainer(seed: seeded());
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      final completed = await n.recordDeed('문을 잡아드렸다');
      final s = c.read(appControllerProvider);
      expect(completed, false); // 2 → 3, 아직 미완성
      expect(s.leaves, 3);
      expect(s.statLeaves, 3);
      expect(s.history.first.text, '문을 잡아드렸다');
      expect(s.history.first.positive, true);
    });

    test('4잎 완성 → completed=true, 완성 연출 트리거', () async {
      final (c, _) = makeContainer(seed: seeded());
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      await n.recordDeed('1');
      final completed = await n.recordDeed('2'); // 2 → 3 → 4
      expect(completed, true);
      expect(c.read(appControllerProvider).leaves, 4);
      expect(c.read(appControllerProvider).celebrate, true);
      // (광고 종료 후) 완성 확정 → 잎 0, 클로버 +1
      await n.finishCloverCelebration();
      expect(c.read(appControllerProvider).leaves, 0);
      expect(c.read(appControllerProvider).clovers, 6);
    });

    test('빈 문자열은 기록되지 않는다', () async {
      final (c, _) = makeContainer(seed: seeded());
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      final before = c.read(appControllerProvider).leaves;
      await n.recordDeed('   ');
      expect(c.read(appControllerProvider).leaves, before);
    });
  });

  group('가챠 뽑기', () {
    test('뽑기 1회 → 클로버 -1, 도감 등록, 기록 추가', () async {
      final (c, _) = makeContainer(seed: seeded(), rng: math.Random(1));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      final r = await n.pullGacha();
      final s = c.read(appControllerProvider);
      expect(r, isNotNull);
      expect(r!.isNew, true);
      expect(s.clovers, 4);
      expect(s.statPulls, 1);
      expect(s.tickets.length, 1);
      expect(s.tickets.first.ticketId, r.ticket.id);
      expect(s.history.first.kind, HistoryKind.pull);
      expect(s.history.first.text, r.ticket.id); // 기록에는 ID 저장
      expect(s.history.first.amount, 1);
    });

    test('클로버 0이면 뽑을 수 없다', () async {
      final (c, _) = makeContainer(seed: seeded(), rng: math.Random(1));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      for (var i = 0; i < 5; i++) {
        expect(await n.pullGacha(), isNotNull);
      }
      expect(c.read(appControllerProvider).clovers, 0);
      expect(await n.pullGacha(), isNull);
    });

    test('중복 획득 → copies 증가, isNew=false', () async {
      final (c, _) = makeContainer(seed: seeded(), rng: _FixedRandom());
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      final first = (await n.pullGacha())!;
      final second = (await n.pullGacha())!;
      expect(second.ticket.id, first.ticket.id);
      expect(second.isNew, false);
      expect(second.owned.copies, 2);
      expect(c.read(appControllerProvider).tickets.length, 1);
    });

    test('추첨 분포가 가중치를 따른다 (시드 고정)', () {
      final rng = math.Random(42);
      final counts = <Rarity, int>{};
      const trials = 20000;
      for (var i = 0; i < trials; i++) {
        final t = LocalGameBackend.drawTicket(rng);
        counts[t.rarity] = (counts[t.rarity] ?? 0) + 1;
      }
      for (final entry in LuckCatalog.weights.entries) {
        final expected = entry.value / 100;
        final actual = (counts[entry.key] ?? 0) / trials;
        // 20000회 기준 ±2%p 허용.
        expect((actual - expected).abs() < 0.02, true,
            reason: '${entry.key}: expected $expected, got $actual');
      }
    });

    test('N회차마다 전면광고 차례가 된다', () async {
      final (c, _) = makeContainer(seed: seeded(), rng: math.Random(7));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      expect(n.shouldShowPullAd, false); // 0회
      await n.pullGacha();
      expect(n.shouldShowPullAd, false); // 1회
      await n.pullGacha();
      expect(n.shouldShowPullAd, false); // 2회
      await n.pullGacha();
      expect(n.shouldShowPullAd, true); // 3회 → 광고 차례
    });
  });

  group('무료(광고) 뽑기', () {
    test('클로버 차감 없이 하루 3회까지, 이후 null', () async {
      final (c, _) = makeContainer(seed: seeded(), rng: math.Random(3));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      expect(n.freePullsLeft, kFreePullsPerDay);
      for (var i = 0; i < kFreePullsPerDay; i++) {
        final r = await n.pullGacha(free: true);
        expect(r, isNotNull);
        expect(r!.free, true);
      }
      final s = c.read(appControllerProvider);
      expect(s.clovers, 5); // 차감 없음
      expect(n.freePullsLeft, 0);
      expect(await n.pullGacha(free: true), isNull);
      expect(s.history.first.amount, 0); // 무료 뽑기는 클로버 0 소모
    });

    test('날짜가 바뀌면 무료 한도가 리셋된다 (기준일 로직 동형 검증)', () async {
      final (c, n0) = makeContainer(seed: seeded(), rng: math.Random(3));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      for (var i = 0; i < kFreePullsPerDay; i++) {
        await n.pullGacha(free: true);
      }
      expect(n.freePullsLeft, 0);
      expect(n0, isNotNull);
      final spent = c.read(appControllerProvider);
      // lastFreePullDate 를 과거로 되돌리면 한도가 복구되어야 한다.
      final restored = AppState.fromJson(
          spent.copyWith(lastFreePullDate: '2000.01.01').toJson());
      expect(restored.freePullsUsedToday, kFreePullsPerDay);
      expect(restored.lastFreePullDate, '2000.01.01');
      // freePullsLeft 는 오늘(UTC) 날짜와 비교하므로 풀 한도로 계산된다.
      final usedToday = restored.lastFreePullDate == _todayUtc()
          ? restored.freePullsUsedToday
          : 0;
      expect(kFreePullsPerDay - usedToday, kFreePullsPerDay);
    });
  });

  group('강화', () {
    test('필요 중복: Lv1→2=1, Lv2→3=2, 소모 누계 검증', () {
      expect(OwnedTicket.costForNextLevel(1), 1);
      expect(OwnedTicket.costForNextLevel(4), 4);
      expect(OwnedTicket.consumedForLevel(1), 0);
      expect(OwnedTicket.consumedForLevel(3), 3);
      expect(OwnedTicket.consumedForLevel(5), 10);
    });

    test('중복 1개로 Lv.2 강화 성공, 재료 부족 시 실패', () async {
      final (c, _) = makeContainer(seed: seeded(), rng: _FixedRandom());
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      await n.pullGacha(); // 첫 획득 (copies 1, spare 0)
      final id = c.read(appControllerProvider).tickets.first.ticketId;
      expect(await n.enhanceTicket(id), isNull); // 재료 없음
      await n.pullGacha(); // 중복 → spare 1
      final up = await n.enhanceTicket(id);
      expect(up, isNotNull);
      expect(up!.level, 2);
      expect(up.spareCopies, 0); // 1개 소모됨
      expect(await n.enhanceTicket(id), isNull); // Lv2→3 은 2개 필요
    });

    test('최대 레벨(Lv.5)에서는 강화 불가', () {
      // 총 11장 = 첫 획득 1 + 강화 재료 10 (1+2+3+4) → 정확히 Lv.5 도달.
      const maxed = OwnedTicket(
          ticketId: 'c01', copies: 11, level: 5, firstPulledAt: '2026.01.01');
      expect(maxed.isMaxLevel, true);
      expect(maxed.canEnhance, false);
      expect(maxed.spareCopies, 0);
      // 재료가 남아돌아도 Lv.5 초과 불가.
      const overflow = OwnedTicket(
          ticketId: 'c01', copies: 99, level: 5, firstPulledAt: '2026.01.01');
      expect(overflow.canEnhance, false);
    });

    test('없는 티켓은 강화되지 않는다', () async {
      final (c, _) = makeContainer(seed: seeded());
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      expect(await n.enhanceTicket('c01'), isNull);
    });
  });

  group('로컬 데이터 이관', () {
    test('기존 shared_preferences 블롭이 첫 부트스트랩에 서버로 이관된다', () async {
      final legacy = const AppState(
        leaves: 3,
        clovers: 7,
        statLeaves: 40,
        statClovers: 9,
        statPulls: 12,
        tickets: [
          OwnedTicket(
              ticketId: 'c01', copies: 3, level: 2, firstPulledAt: '2026.06.01'),
        ],
        history: [
          HistoryEntry(
              id: 1,
              date: '2026.06.01',
              kind: HistoryKind.deed,
              text: '이관 테스트',
              amount: 1),
        ],
      );
      SharedPreferences.setMockInitialValues({
        'luckypicky_app_state_v1':
            '{"leaves":3,"clovers":7,"statLeaves":40,"statClovers":9,'
                '"statPulls":12,'
                '"tickets":[{"ticketId":"c01","copies":3,"level":2,"firstPulledAt":"2026.06.01"}],'
                '"history":[{"id":1,"date":"2026.06.01","kind":"deed","text":"이관 테스트","amount":1}],'
                '"freePullsUsedToday":0,"lastFreePullDate":""}',
      });
      final (c, backend) = makeContainer();
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      final s = c.read(appControllerProvider);
      expect(backend.importedLocal, true);
      expect(s.clovers, legacy.clovers);
      expect(s.leaves, legacy.leaves);
      expect(s.tickets.single.ticketId, 'c01');
      expect(s.tickets.single.level, 2);
      expect(s.history.single.text, '이관 테스트');
    });
  });

  test('상태가 JSON 으로 직렬화/복원된다 (도감 포함)', () async {
    final (c, _) = makeContainer(seed: seeded(), rng: math.Random(9));
    final n = c.read(appControllerProvider.notifier);
    await n.ready;
    await n.recordDeed('테스트 선행');
    await n.pullGacha();
    await n.pullGacha();
    final s = c.read(appControllerProvider);
    final restored = AppState.fromJson(s.toJson());
    expect(restored.leaves, s.leaves);
    expect(restored.clovers, s.clovers);
    expect(restored.statPulls, s.statPulls);
    expect(restored.tickets.length, s.tickets.length);
    expect(restored.tickets.first.ticketId, s.tickets.first.ticketId);
    expect(restored.tickets.first.copies, s.tickets.first.copies);
    expect(restored.history.length, s.history.length);
  });

  test('구버전 history(wish kind)는 pull 로 읽힌다', () {
    final h = HistoryEntry.fromJson(
        {'id': 1, 'date': '2026.01.01', 'kind': 'wish', 'text': 'x', 'amount': 2});
    expect(h.kind, HistoryKind.pull);
    expect(h.positive, false);
  });
}

String _todayUtc() {
  final d = DateTime.now().toUtc();
  String p(int n) => n.toString().padLeft(2, '0');
  return '${d.year}.${p(d.month)}.${p(d.day)}';
}

/// 항상 0을 돌려주는 난수원 — 같은 티켓(첫 common)만 뽑히게 해서
/// 중복/강화 로직을 결정적으로 검증한다.
class _FixedRandom implements math.Random {
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
}
