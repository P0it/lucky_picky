import 'package:flutter_test/flutter_test.dart';
import 'package:luckypicky/config/daily_quotes.dart';
import 'package:luckypicky/config/fortune_pool.dart';
import 'package:luckypicky/data/copy_book.dart';
import 'package:luckypicky/models/daily_fortune.dart';

/// CopyBook 의 계약: 서버 문구가 있으면 서버 것, 없으면 번들 문구.
/// 폴백 단위는 (surface, lang[, grade]) 조합별이라 일부만 서버에 있어도 안전해야 한다.
void main() {
  final fortune = DailyFortune.compose('uid', DateTime(2026, 7, 13), 83);
  final day = DateTime(2026, 7, 13);

  group('서버 문구 없음 → 번들 폴백', () {
    test('데일리 문구는 번들과 동일하게 뽑힌다', () {
      expect(
        CopyBook.bundled.dailyQuote('ko', day),
        DailyQuotes.forToday('ko', day),
      );
    });

    test('총운·조언도 번들과 동일하다', () {
      expect(
        CopyBook.bundled.fortuneOverall('ko', fortune),
        FortunePool.overall('ko', fortune),
      );
      expect(
        CopyBook.bundled.fortuneAdvice('ko', fortune),
        FortunePool.advice('ko', fortune),
      );
    });
  });

  group('서버 문구 있음', () {
    final book = CopyBook.fromLines(const [
      CopyLine(surface: 'daily_quote', lang: 'ko', text: '서버 문구'),
      CopyLine(
        surface: 'fortune_overall',
        lang: 'ko',
        grade: 2,
        text: '서버 총운(맑음)',
      ),
    ]);

    test('서버에 있는 조합은 서버 문구를 쓴다', () {
      expect(book.dailyQuote('ko', day), '서버 문구');
      expect(fortune.grade, 2); // 83점 = 맑음
      expect(book.fortuneOverall('ko', fortune), '서버 총운(맑음)');
    });

    test('서버에 없는 조합(다른 언어·등급·surface)은 번들로 폴백한다', () {
      // 언어 폴백
      expect(book.dailyQuote('en', day), DailyQuotes.forToday('en', day));
      // surface 폴백 — 조언은 서버에 안 넣었다
      expect(
        book.fortuneAdvice('ko', fortune),
        FortunePool.advice('ko', fortune),
      );
      // 등급 폴백 — 서버엔 grade 2만 있다
      final low = DailyFortune.compose('uid', day, 10);
      expect(low.grade, 0);
      expect(book.fortuneOverall('ko', low), FortunePool.overall('ko', low));
    });
  });

  test('캐시 직렬화 왕복 후에도 같은 문구가 나온다', () {
    final book = CopyBook.fromLines(const [
      CopyLine(surface: 'daily_quote', lang: 'ko', text: 'A'),
      CopyLine(surface: 'daily_quote', lang: 'ko', text: 'B'),
      CopyLine(surface: 'fortune_advice', lang: 'ko', text: '조언'),
      CopyLine(surface: 'fortune_overall', lang: 'ko', grade: 2, text: '총운'),
    ]);
    final restored = CopyBook.fromLines([
      for (final j in book.toJson()) CopyLine.fromJson(j),
    ]);

    expect(restored.dailyQuote('ko', day), book.dailyQuote('ko', day));
    expect(
      restored.fortuneOverall('ko', fortune),
      book.fortuneOverall('ko', fortune),
    );
    expect(
      restored.fortuneAdvice('ko', fortune),
      book.fortuneAdvice('ko', fortune),
    );
  });

  test('같은 날·같은 점수면 문구가 고정된다 (결정론)', () {
    final again = DailyFortune.compose('uid', day, 83);
    final book = CopyBook.fromLines(const [
      CopyLine(surface: 'fortune_overall', lang: 'ko', grade: 2, text: '가'),
      CopyLine(surface: 'fortune_overall', lang: 'ko', grade: 2, text: '나'),
      CopyLine(surface: 'fortune_overall', lang: 'ko', grade: 2, text: '다'),
    ]);
    expect(
      book.fortuneOverall('ko', again),
      book.fortuneOverall('ko', fortune),
    );
  });
}
