import '../config/daily_quotes.dart';
import '../config/fortune_copy.dart';
import '../models/daily_fortune.dart';

// ════════════════════════════════════════════════════════════════
//  CopyBook — 문구 조회기. 서버(copy_lines) 문구가 있으면 그걸,
//  없으면 앱에 번들된 문구(config/*.dart)를 쓴다.
//
//  왜: 밈·유행어는 2~3개월이면 낡는데 앱 문구를 바꾸려면 스토어 심사를
//  기다려야 한다. 서버 테이블에 넣으면 당일 반영되고, 밈 문구의 ends_at 이
//  지나면 서버가 안 내려주므로 그 면(surface)은 자동으로 번들 문구로 돌아간다.
//
//  폴백 단위는 (surface, lang[, grade]) 조합별. 예를 들어 서버에 한국어
//  총운만 넣어두면, 조언·영어·일본어는 계속 번들 문구가 쓰인다.
//
//  선택 규칙은 번들과 동일하다 — 데일리 문구는 연중 일수 순환,
//  행운지수 문구는 DailyFortune 의 roll 값을 풀 길이로 modulo.
//  덕분에 "같은 날·같은 점수면 같은 문구"라는 결정론이 서버 문구에서도 유지된다.
// ════════════════════════════════════════════════════════════════

/// 서버에서 받은 문구 한 줄.
class CopyLine {
  final String surface; // daily_quote | fortune_overall | fortune_advice
  final String lang;
  final int? grade; // fortune_overall 만 사용 (0~3)
  final String text;

  const CopyLine({
    required this.surface,
    required this.lang,
    required this.text,
    this.grade,
  });

  factory CopyLine.fromJson(Map<String, dynamic> j) => CopyLine(
    surface: j['surface'] as String,
    lang: j['lang'] as String,
    grade: (j['grade'] as num?)?.toInt(),
    text: j['text'] as String,
  );

  Map<String, dynamic> toJson() => {
    'surface': surface,
    'lang': lang,
    if (grade != null) 'grade': grade,
    'text': text,
  };
}

class CopyBook {
  /// key: 'surface|lang' 또는 총운은 'fortune_overall|lang|grade'
  final Map<String, List<String>> _remote;

  const CopyBook._(this._remote);

  /// 서버 문구 없음 — 전부 번들 문구로 동작. (첫 실행·오프라인·장애 시)
  static const CopyBook bundled = CopyBook._({});

  bool get usesRemote => _remote.isNotEmpty;

  factory CopyBook.fromLines(Iterable<CopyLine> lines) {
    final map = <String, List<String>>{};
    for (final l in lines) {
      // 지원하지 않는 surface/lang 이 섞여 들어와도 조회 키가 안 맞아 무시된다.
      map.putIfAbsent(_key(l.surface, l.lang, l.grade), () => []).add(l.text);
    }
    return CopyBook._(map);
  }

  static String _key(String surface, String lang, int? grade) =>
      grade == null ? '$surface|$lang' : '$surface|$lang|$grade';

  /// 서버 목록이 비어 있으면 null → 호출부가 번들 폴백을 쓴다.
  List<String>? _pool(String surface, String lang, [int? grade]) {
    final list = _remote[_key(surface, lang, grade)];
    return (list == null || list.isEmpty) ? null : list;
  }

  /// 홈 데일리 문구. [day] 미지정 시 오늘.
  String dailyQuote(String lang, [DateTime? day]) {
    final pool = _pool('daily_quote', lang) ?? DailyQuotes.poolFor(lang);
    return DailyQuotes.pickForDay(pool, day ?? DateTime.now());
  }

  /// 행운지수 총운 (등급별).
  String fortuneOverall(String lang, DailyFortune f) {
    final pool =
        _pool('fortune_overall', lang, f.grade) ??
        FortuneCopy.overallPool(lang, f.grade);
    return pool[f.overallRoll % pool.length];
  }

  /// 행운지수 조언 (오늘 해볼 만한 선행).
  String fortuneAdvice(String lang, DailyFortune f) {
    final pool = _pool('fortune_advice', lang) ?? FortuneCopy.advicePool(lang);
    return pool[f.adviceRoll % pool.length];
  }

  List<Map<String, dynamic>> toJson() => [
    for (final e in _remote.entries)
      for (final text in e.value) _lineOf(e.key, text).toJson(),
  ];

  static CopyLine _lineOf(String key, String text) {
    final parts = key.split('|');
    return CopyLine(
      surface: parts[0],
      lang: parts[1],
      grade: parts.length > 2 ? int.tryParse(parts[2]) : null,
      text: text,
    );
  }
}
