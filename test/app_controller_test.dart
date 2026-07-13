import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luckypicky/config/luck_tickets.dart';
import 'package:luckypicky/data/local_game_backend.dart';
import 'package:luckypicky/models/app_state.dart';
import 'package:luckypicky/models/deed.dart';
import 'package:luckypicky/models/ticket_instance.dart';
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

    test('중복 획득 → 카드가 한 장 더 생기고 isNew=false', () async {
      final (c, _) = makeContainer(seed: seeded(), rng: _FixedRandom());
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      final first = (await n.pullGacha())!;
      final second = (await n.pullGacha())!;
      expect(second.ticket.id, first.ticket.id);
      expect(second.isNew, false);
      expect(second.copies, 2);
      // 같은 행운권이라도 카드는 각각 따로 존재한다.
      expect(c.read(appControllerProvider).tickets.length, 2);
      expect(second.instance.id, isNot(first.instance.id));
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
  });

  group('광고 클로버', () {
    test('하루 3회까지 클로버가 지급되고, 이후 false', () async {
      final (c, _) = makeContainer(seed: seeded(), rng: math.Random(3));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      expect(n.adCloversLeft, kAdCloversPerDay);
      for (var i = 0; i < kAdCloversPerDay; i++) {
        expect(await n.grantAdClover(), true);
      }
      expect(c.read(appControllerProvider).clovers, 5 + kAdCloversPerDay);
      expect(n.adCloversLeft, 0);
      expect(await n.grantAdClover(), false); // 한도 초과
    });

    test('지급받은 클로버로 뽑으면 클로버가 1개 줄어든다', () async {
      final (c, _) = makeContainer(seed: seeded(), rng: math.Random(3));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      await n.grantAdClover();
      final before = c.read(appControllerProvider).clovers;
      final r = await n.pullGacha();
      expect(r, isNotNull);
      final s = c.read(appControllerProvider);
      expect(s.clovers, before - 1);
      expect(s.history.first.amount, 1); // 뽑기는 언제나 클로버 1개
    });

    test('날짜가 바뀌면 광고 클로버 한도가 리셋된다 (기준일 로직 동형 검증)', () async {
      final (c, _) = makeContainer(seed: seeded(), rng: math.Random(3));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      for (var i = 0; i < kAdCloversPerDay; i++) {
        await n.grantAdClover();
      }
      expect(n.adCloversLeft, 0);
      final spent = c.read(appControllerProvider);
      // lastAdCloverDate 를 과거로 되돌리면 한도가 복구되어야 한다.
      final restored = AppState.fromJson(
          spent.copyWith(lastAdCloverDate: '2000.01.01').toJson());
      expect(restored.adCloversToday, kAdCloversPerDay);
      expect(restored.lastAdCloverDate, '2000.01.01');
      // adCloversLeft 는 오늘(UTC) 날짜와 비교하므로 풀 한도로 계산된다.
      final usedToday = restored.lastAdCloverDate == _todayUtc()
          ? restored.adCloversToday
          : 0;
      expect(kAdCloversPerDay - usedToday, kAdCloversPerDay);
    });
  });

  group('강화', () {
    /// 같은 행운권 카드 [n] 장을 가진 상태.
    AppState withCards(int n, {int targetLevel = 1}) => AppState(
          clovers: 5,
          tickets: [
            TicketInstance(
                id: 'i0',
                ticketId: 'c01',
                level: targetLevel,
                pulledAt: '2026.01.01'),
            for (var i = 1; i < n; i++)
              TicketInstance(
                  id: 'i$i', ticketId: 'c01', pulledAt: '2026.01.01'),
          ],
        );

    test('요구 재료: +0→+1 은 1장, +3→+4 는 4장', () {
      expect(TicketInstance.materialsFor(1), 1);
      expect(TicketInstance.materialsFor(4), 4);
      expect(TicketInstance.successRates[2], 100);
      expect(TicketInstance.successRates[5], 40);
    });

    test('재료 1장으로 +1 강화 성공 — 재료 카드는 사라진다', () async {
      final (c, _) = makeContainer(seed: withCards(2), rng: _Roll(0));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;

      final r = await n.enhanceTicket('i0', ['i1']);
      expect(r, isNotNull);
      expect(r!.success, true);
      expect(r.level, 2); // = +1
      expect(r.rate, 100);

      final s = c.read(appControllerProvider);
      expect(s.tickets.length, 1); // 재료 소모
      expect(s.tickets.single.id, 'i0');
      expect(s.tickets.single.plus, 1);
    });

    test('강화 실패 — 재료만 사라지고 단계는 그대로', () async {
      // +1 → +2 기본 80%. 같은 등급의 다른 카드를 재료로 쓰면 보정 0 → 80%.
      // 굴림 99 → 실패.
      final seed = AppState(clovers: 5, tickets: const [
        TicketInstance(
            id: 'i0', ticketId: 'c01', level: 2, pulledAt: '2026.01.01'),
        TicketInstance(id: 'm1', ticketId: 'c02', pulledAt: '2026.01.01'),
        TicketInstance(id: 'm2', ticketId: 'c03', pulledAt: '2026.01.01'),
      ]);
      final (c, _) = makeContainer(seed: seed, rng: _Roll(99));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;

      final r = await n.enhanceTicket('i0', ['m1', 'm2']);
      expect(r, isNotNull);
      expect(r!.success, false);
      expect(r.rate, 80);

      final s = c.read(appControllerProvider);
      expect(s.tickets.length, 1); // 재료 2장 소모
      expect(s.tickets.single.plus, 1); // 단계 유지
    });

    test('재료 수가 요구량과 다르면 강화되지 않는다', () async {
      final (c, _) =
          makeContainer(seed: withCards(3, targetLevel: 2), rng: _Roll(0));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      // +1 → +2 는 2장 필요.
      expect(await n.enhanceTicket('i0', ['i1']), isNull);
      expect(c.read(appControllerProvider).tickets.length, 3); // 소모 없음
    });

    test('최고 단계(+4)에서는 강화 불가', () async {
      final (c, _) =
          makeContainer(seed: withCards(6, targetLevel: 5), rng: _Roll(0));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      final target = c.read(appControllerProvider).tickets.first;
      expect(target.isMaxLevel, true);
      expect(await n.enhanceTicket('i0', ['i1', 'i2', 'i3', 'i4', 'i5']),
          isNull);
    });

    test('없는 카드는 강화되지 않는다', () async {
      final (c, _) = makeContainer(seed: seeded());
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      expect(await n.enhanceTicket('nope', const []), isNull);
    });

    test('재료 등급이 확률을 바꾼다 — 상위 +10%p, 하위 -10%p, 같은 카드 +15%p', () {
      // c01(일반) 카드를 +1 → +2 (기본 80%) 로 올리는 상황.
      const target = TicketInstance(
          id: 'i0', ticketId: 'c01', level: 2, pulledAt: '2026.01.01');
      const sameCard =
          TicketInstance(id: 'm1', ticketId: 'c01', pulledAt: '2026.01.01');
      const sameRarity =
          TicketInstance(id: 'm2', ticketId: 'c02', pulledAt: '2026.01.01');
      const higher = // r01 = 희귀 (한 단계 위)
          TicketInstance(id: 'm3', ticketId: 'r01', pulledAt: '2026.01.01');

      expect(target.baseSuccessRate, 80);
      // 같은 등급 2장 → 보정 없음.
      expect(target.successRateWith([sameRarity, sameRarity]), 80);
      // 같은 카드 1장(+15) + 같은 등급 1장 → 95.
      expect(target.successRateWith([sameCard, sameRarity]), 95);
      // 상위 등급 2장 → +10 x 2 = 100.
      expect(target.successRateWith([higher, higher]), 100);

      // 반대로 전설 카드를 하위 등급으로 강화하면 확률이 깎인다.
      const legend = TicketInstance(
          id: 'L', ticketId: 'l01', level: 2, pulledAt: '2026.01.01');
      // 일반(3단계 아래) 2장 → 80 - 30 x 2 = 20.
      expect(legend.successRateWith([sameRarity, sameRarity]), 20);
    });

    test('아무 카드나 재료로 쓸 수 있다 (다른 등급 포함)', () async {
      final seed = AppState(clovers: 5, tickets: const [
        TicketInstance(id: 'i0', ticketId: 'c01', pulledAt: '2026.01.01'),
        TicketInstance(id: 'r0', ticketId: 'r01', pulledAt: '2026.01.01'),
      ]);
      final (c, _) = makeContainer(seed: seed, rng: _Roll(0));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;

      // 희귀 카드를 일반 카드의 강화 재료로 태운다 (+1 은 기본 100%).
      final r = await n.enhanceTicket('i0', ['r0']);
      expect(r, isNotNull);
      expect(r!.success, true);
      expect(r.rate, 100);
      final s = c.read(appControllerProvider);
      expect(s.tickets.length, 1);
      expect(s.tickets.single.plus, 1);
    });
  });

  group('재조합', () {
    AppState threeCommons() => const AppState(clovers: 5, tickets: [
          TicketInstance(id: 'a', ticketId: 'c01', pulledAt: '2026.01.01'),
          TicketInstance(id: 'b', ticketId: 'c02', pulledAt: '2026.01.01'),
          TicketInstance(id: 'c', ticketId: 'c03', pulledAt: '2026.01.01'),
        ]);

    test('카드 3장 → 새 카드 1장, 재료는 사라진다', () async {
      final (c, _) = makeContainer(seed: threeCommons(), rng: _Roll(99));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;

      final r = await n.reforgeTickets(['a', 'b', 'c']);
      expect(r, isNotNull);
      expect(r!.upgraded, false); // 굴림 99 → 승급 실패(25%)
      final s = c.read(appControllerProvider);
      expect(s.tickets.length, 1); // 3장 소모 + 1장 생성
      expect(s.tickets.single.id, r.instance.id);
      // 승급 실패 → 재료 최고 등급(일반) 그대로.
      expect(LuckCatalog.byId(r.instance.ticketId)!.rarity, Rarity.common);
    });

    test('승급 판정에 성공하면 한 등급 위로 나온다', () async {
      final (c, _) = makeContainer(seed: threeCommons(), rng: _Roll(0));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;

      final r = await n.reforgeTickets(['a', 'b', 'c']);
      expect(r!.upgraded, true); // 굴림 0 → 25% 안쪽
      expect(LuckCatalog.byId(r.instance.ticketId)!.rarity, Rarity.rare);
    });

    test('재료가 3장이 아니면 재조합되지 않는다', () async {
      final (c, _) = makeContainer(seed: threeCommons(), rng: _Roll(0));
      final n = c.read(appControllerProvider.notifier);
      await n.ready;
      expect(await n.reforgeTickets(['a', 'b']), isNull);
      expect(c.read(appControllerProvider).tickets.length, 3);
    });
  });

  group('로컬 데이터 이관', () {
    test('기존 shared_preferences 블롭이 첫 부트스트랩에 서버로 이관된다', () async {
      const legacy = AppState(
        leaves: 3,
        clovers: 7,
        statLeaves: 40,
        statClovers: 9,
        statPulls: 12,
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
      // 구버전 합산 형태(copies 3 / level 2)는 카드로 펼쳐진다:
      // 강화된 1장(+1) + 아직 안 쓴 여분 1장.
      expect(s.tickets.length, 2);
      expect(s.tickets.every((t) => t.ticketId == 'c01'), true);
      expect(s.tickets.map((t) => t.level).toList()..sort(), [1, 2]);
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
    expect(restored.tickets.first.id, s.tickets.first.id);
    expect(restored.tickets.first.level, s.tickets.first.level);
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

/// 항상 정해진 값을 굴리는 난수원 — 강화 성공/실패 판정을 고정한다.
/// (성공 조건: nextInt(100) < 성공확률)
class _Roll implements math.Random {
  final int value;
  const _Roll(this.value);

  @override
  bool nextBool() => false;
  @override
  double nextDouble() => value / 100;
  @override
  int nextInt(int max) => value % max;
}
