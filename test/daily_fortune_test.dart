import 'package:flutter_test/flutter_test.dart';
import 'package:luckypicky/config/fortune_pool.dart';
import 'package:luckypicky/models/daily_fortune.dart';

void main() {
  final date = DateTime(2026, 7, 13);

  group('DailyFortune.compose', () {
    test('같은 (uid, 날짜, 점수)는 항상 같은 조합', () {
      final a = DailyFortune.compose('user-1', date, 87);
      final b = DailyFortune.compose('user-1', date, 87);
      expect(a.overallRoll, b.overallRoll);
      expect(a.adviceRoll, b.adviceRoll);
      expect(a.colorRoll, b.colorRoll);
      expect(a.luckyNumber, b.luckyNumber);
      expect(a.itemRoll, b.itemRoll);
    });

    test('다른 uid 또는 다른 날짜면 조합이 달라진다 (샘플 통계)', () {
      var diffUid = 0;
      var diffDate = 0;
      const n = 200;
      final base = DailyFortune.compose('user-1', date, 50);
      for (var i = 0; i < n; i++) {
        final byUid = DailyFortune.compose('user-$i', date, 50);
        final byDate =
            DailyFortune.compose('user-1', date.add(Duration(days: i + 1)), 50);
        if (byUid.adviceRoll != base.adviceRoll) diffUid++;
        if (byDate.adviceRoll != base.adviceRoll) diffDate++;
      }
      // 해시가 제대로 섞이면 거의 전부 달라야 한다.
      expect(diffUid, greaterThan(n * 0.9));
      expect(diffDate, greaterThan(n * 0.9));
    });

    test('luckIndex는 0~100으로 클램프', () {
      expect(DailyFortune.compose('u', date, -5).luckIndex, 0);
      expect(DailyFortune.compose('u', date, 999).luckIndex, 100);
    });

    test('행운의 숫자에 4는 절대 없다', () {
      for (var i = 0; i < 500; i++) {
        final f = DailyFortune.compose('user-$i', date, 50);
        expect(f.luckyNumber, isNot(4));
        expect(f.luckyNumber, inInclusiveRange(1, 9));
      }
    });

    test('uid null(오프라인)도 크래시 없이 동작', () {
      final f = DailyFortune.compose(null, date, 42);
      expect(f.luckIndex, 42);
    });
  });

  group('gradeForLuckIndex 경계값', () {
    test('구간 매핑: ~39 / 40~64 / 65~84 / 85~100', () {
      expect(gradeForLuckIndex(0), 0);
      expect(gradeForLuckIndex(39), 0);
      expect(gradeForLuckIndex(40), 1);
      expect(gradeForLuckIndex(64), 1);
      expect(gradeForLuckIndex(65), 2);
      expect(gradeForLuckIndex(84), 2);
      expect(gradeForLuckIndex(85), 3);
      expect(gradeForLuckIndex(100), 3);
    });
  });

  group('FortunePool 조회', () {
    test('지원 3개 언어 전부 + 미지원 언어 폴백에서 빈 문자열 없이 반환', () {
      for (final lang in ['ko', 'en', 'ja', 'xx']) {
        for (final score in [0, 39, 40, 64, 65, 84, 85, 100]) {
          final f = DailyFortune.compose('user-7', date, score);
          expect(FortunePool.overall(lang, f), isNotEmpty);
          expect(FortunePool.advice(lang, f), isNotEmpty);
          expect(FortunePool.item(lang, f), isNotEmpty);
          expect(FortunePool.luckyColor(f).name(lang), isNotEmpty);
        }
      }
    });

    test('총운 풀은 4등급 × 언어별로 채워져 있다', () {
      // roll 값이 어떤 값이어도 modulo 조회라 범위 밖 접근이 없다.
      final f = DailyFortune.compose('user-8', date, 90);
      expect(f.grade, 3);
      expect(FortunePool.overall('ko', f), isNotEmpty);
    });
  });
}
