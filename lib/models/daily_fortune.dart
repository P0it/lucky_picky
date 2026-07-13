// ════════════════════════════════════════════════════════════════
//  오늘의 행운지수 — 조합 로직.
//
//  행운지수(luckIndex)는 유저가 게이지 미니게임에서 직접 "잡은" 값이고,
//  나머지 요소(총운/조언/행운의 색·숫자·아이템)는 hash(uid + 날짜) 시드로
//  결정론 조합한다. 같은 유저·같은 날이면 항상 같은 조합 → 서버·LLM 불필요.
//
//  Random(seed) 대신 FNV-1a 해시를 필드별로 재해시해 쓰는 이유:
//  Dart의 Random 구현에 기대지 않는 플랫폼 무관 결정론을 보장하기 위함.
// ════════════════════════════════════════════════════════════════

/// FNV-1a 32-bit. 문자열 → 비음수 해시.
int fnv1a(String input) {
  var hash = 0x811c9dc5;
  for (final code in input.codeUnits) {
    hash ^= code;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// 동아시아권 금기(四=죽음 연상) 때문에 4는 후보에서 제외.
const List<int> kLuckyNumberCandidates = [1, 2, 3, 5, 6, 7, 8, 9];

/// 행운지수 구간 → 총운 등급 (0=흐림, 1=구름조금, 2=맑음, 3=대박맑음).
int gradeForLuckIndex(int luckIndex) {
  if (luckIndex <= 39) return 0;
  if (luckIndex <= 64) return 1;
  if (luckIndex <= 84) return 2;
  return 3;
}

class DailyFortune {
  final int luckIndex; // 0~100, 게이지에서 잡은 값
  final int grade; // 0~3, luckIndex에서 파생
  final int overallRoll; // 총운 문구 선택용 (풀 길이로 modulo해 사용)
  final int adviceRoll;
  final int colorRoll;
  final int luckyNumber; // 1~9 (4 제외)
  final int itemRoll;

  const DailyFortune({
    required this.luckIndex,
    required this.grade,
    required this.overallRoll,
    required this.adviceRoll,
    required this.colorRoll,
    required this.luckyNumber,
    required this.itemRoll,
  });

  /// [uid] 는 Supabase 익명 uid. 오프라인 첫 실행 등으로 null이면 '' 폴백.
  /// [date] 는 로컬 날짜 기준. [luckIndex] 는 0~100으로 클램프된다.
  factory DailyFortune.compose(String? uid, DateTime date, int luckIndex) {
    final idx = luckIndex.clamp(0, 100);
    final seed = fnv1a('${uid ?? ''}|${dateKeyOf(date)}');
    // 모든 요소는 (uid, 날짜, 잡은 점수)로 결정된다. 점수를 섞는 이유:
    // 같은 날 재도전으로 점수가 바뀌면 조합도 새로 나와야 "다시 뽑은" 느낌이 난다.
    // (같은 점수를 다시 잡으면 같은 조합 — 결정론 유지)
    int roll(int salt) => fnv1a('$seed:$salt:$idx');
    return DailyFortune(
      luckIndex: idx,
      grade: gradeForLuckIndex(idx),
      overallRoll: roll(1),
      adviceRoll: roll(2),
      colorRoll: roll(3),
      luckyNumber:
          kLuckyNumberCandidates[roll(4) % kLuckyNumberCandidates.length],
      itemRoll: roll(5),
    );
  }

  /// 'YYYY-MM-DD' (로컬).
  static String dateKeyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
