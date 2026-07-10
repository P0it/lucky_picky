/// 기록 항목의 종류.
/// - deed: 선행으로 잎을 모은 기록 (positive)
/// - pull: 가챠 뽑기(클로버 사용) 기록
enum HistoryKind { deed, pull }

/// 기록 항목 — 표시 문자열을 미리 굳히지 않고 구조화해 저장한다.
/// (잎/클로버 증감과 뽑기 접두어는 표시 시점에 언어별로 포맷한다.)
class HistoryEntry {
  final int id;
  final String date; // 'YYYY.MM.DD'
  final HistoryKind kind;

  /// deed: 사용자가 입력한 선행 내용 / pull: 뽑힌 행운권의 카탈로그 ID.
  final String text;

  /// deed: 채운 잎 수(+1) / pull: 사용한 클로버 수(무료 뽑기는 0).
  final int amount;

  /// 구버전 영속 데이터 호환용 — 신규 항목은 null.
  /// 값이 있으면 표시할 때 [text]/[legacyDelta]를 원문 그대로 쓴다.
  final String? legacyDelta;

  const HistoryEntry({
    required this.id,
    required this.date,
    required this.kind,
    required this.text,
    required this.amount,
    this.legacyDelta,
  });

  bool get positive => kind == HistoryKind.deed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'kind': kind.name,
        'text': text,
        'amount': amount,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) {
    // 신규 포맷(kind/amount 보유).
    if (j['kind'] != null && j['amount'] != null) {
      return HistoryEntry(
        id: j['id'] as int,
        date: j['date'] as String,
        kind: j['kind'] == 'deed' ? HistoryKind.deed : HistoryKind.pull,
        text: j['text'] as String? ?? '',
        amount: j['amount'] as int,
      );
    }
    // 구버전 포맷(delta/positive 보유) — 원문을 보존해 그대로 표시.
    final positive = j['positive'] as bool? ?? true;
    return HistoryEntry(
      id: j['id'] as int,
      date: j['date'] as String? ?? '',
      kind: positive ? HistoryKind.deed : HistoryKind.pull,
      text: j['text'] as String? ?? '',
      amount: 0,
      legacyDelta: j['delta'] as String?,
    );
  }
}
