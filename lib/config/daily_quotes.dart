// ════════════════════════════════════════════════════════════════
//  매일 바뀌는 홈 화면 명언 — 친절·선행·따뜻함에 대한 한마디.
//
//  날짜(연중 일수)를 기준으로 하나를 고르므로,
//  같은 날에는 항상 같은 문구가 나오고 날이 바뀌면 다음 문구로 넘어갑니다.
//
//  단순 번역이 아니라 각 언어권 정서에 맞춰 "직접 각색"한 문구입니다.
//  네잎클로버=행운이라는 '설명'에 기대지 않고, "오늘의 작은 행운/다정함"
//  이라는 보편 감정에 맞춰 작성했습니다. (동아시아권에서 숫자 4를 한자 四로
//  강조하면 죽음을 연상시키므로 그런 표현은 피했습니다.)
//
//  언어별 문구 개수는 서로 달라도 됩니다(리스트 길이로 순환).
// ════════════════════════════════════════════════════════════════
class DailyQuotes {
  const DailyQuotes._();

  // 줄바꿈 지점(\n)은 어구 경계에 맞춰 직접 넣어둡니다.
  static const Map<String, List<String>> _byLang = {
    'ko': [
      '오늘도 다정한 하루 보내고 있나요',
      '작은 친절 하나,\n여기 남겨볼까요',
      '좋은 마음, 천천히 모아가요',
      '오늘 누군가에게\n건넨 다정함이 있었나요',
      '조용히 건넨 친절도 충분해요',
      '천천히 채워도 괜찮아요',
      '마음 쓴 하루였네요',
      '당신의 다정함이\n조금씩 쌓이고 있어요',
      '오늘 한 칸,\n마음을 내어볼까요',
      '작은 선행도 충분히 의미 있어요',
      '괜찮아요, 작은 것부터',
      '여기, 당신의 다정한 기록이에요',
      '오늘도 마음 한 칸\n내어주셨네요',
      '잘 지내고 있나요, 오늘도',
      '누군가에게 건넨 다정함,\n기억하고 있어요',
      '서두르지 않아도 돼요',
      '오늘의 다정함을 남겨주세요',
      '다정한 마음으로 하루를 시작해요',
    ],
    'en': [
      'Spending a kind day\nagain today?',
      'One small kindness —\nleave it here?',
      'Gather the good\nslowly, no rush',
      'Was there a little warmth\nyou gave someone today?',
      'A quiet kindness\nis more than enough',
      'It’s okay\nto fill it slowly',
      'You spent your heart\nwell today',
      'Your warmth\nis adding up,\nlittle by little',
      'One square today —\ncare to share your heart?',
      'Even a small good deed\nmeans plenty',
      'It’s okay —\nstart with something small',
      'Here lies your\ngentle little record',
      'You spared a square\nof your heart again today',
      'Hope you’re doing well,\ntoday too',
      'The warmth you gave someone —\nI remember it',
      'There’s no need\nto hurry',
      'Leave behind\ntoday’s little kindness',
      'Start the day\nwith a gentle heart',
    ],
    'ja': [
      '今日もやさしい一日を\n過ごしていますか',
      '小さな親切ひとつ、\nここに残しませんか',
      'いい心、\nゆっくり集めていこう',
      '今日、誰かに\nやさしさを渡しましたか',
      'そっと渡した親切も\n十分です',
      'ゆっくり満たしても\n大丈夫',
      '心をつかった\n一日でしたね',
      'あなたのやさしさが\n少しずつ積もっています',
      '今日ひとマス、\n心を差し出してみませんか',
      '小さな善い行いも\nちゃんと意味がある',
      '大丈夫、\n小さなことから',
      'ここに、あなたの\nやさしい記録があります',
      '今日も心をひとマス\n分けてくれましたね',
      '元気にしていますか、\n今日も',
      '誰かに渡したやさしさ、\nちゃんと覚えています',
      '急がなくても\n大丈夫',
      '今日のやさしさを\n残してください',
      'やさしい心で\n一日を始めよう',
    ],
  };

  static const _fallbackLang = 'en';

  /// [lang] 언어의 오늘 문구. 미지원 언어는 영어로 폴백.
  /// [now] 미지정 시 현재 시각 기준.
  static String forToday(String lang, [DateTime? now]) {
    final list = _byLang[lang] ?? _byLang[_fallbackLang]!;
    final d = now ?? DateTime.now();
    final startOfYear = DateTime(d.year, 1, 1);
    final dayOfYear = d.difference(startOfYear).inDays; // 0..365
    return list[dayOfYear % list.length];
  }
}
