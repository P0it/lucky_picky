// ════════════════════════════════════════════════════════════════
//  매일 바뀌는 홈 화면 문구 — "선행하면 운이 쌓인다"는 MZ식 드립 한마디.
//
//  주의: 이 앱은 뽑기앱이 아니라 선행앱. 유머 톤은 가져가되
//  가챠·RNG·리세마라 같은 뽑기 프레임은 쓰지 않는다.
//  핵심 메시지 = 운은 기다리는 게 아니라 선행으로 직접 만드는 것.
//
//  날짜(연중 일수)를 기준으로 하나를 고르므로,
//  같은 날에는 항상 같은 문구가 나오고 날이 바뀌면 다음 문구로 넘어갑니다.
//
//  단순 번역이 아니라 각 언어권 밈 감성에 맞춰 "직접 각색"한 문구입니다.
//  한국어는 짤·유행어 패러디 톤, 영어는 인터넷 밈 톤,
//  일본어는 徳を積む 넷슬랭 톤으로 작성했습니다.
//  (동아시아권에서 숫자 4를 한자 四로 강조하면 죽음을 연상시키므로
//  그런 표현은 피했습니다.)
//
//  언어별 문구 개수는 서로 달라도 됩니다(리스트 길이로 순환).
// ════════════════════════════════════════════════════════════════
class DailyQuotes {
  const DailyQuotes._();

  // 줄바꿈 지점(\n)은 어구 경계에 맞춰 직접 넣어둡니다.
  static const Map<String, List<String>> _byLang = {
    'ko': [
      '운은 찾아오는 게 아니라\n찾아가는 거다',
      '운이 없지\n가오가 없냐',
      '너 지금 운이 없다고\n우니?',
      '운도 돈으로\n살 수 있다면?',
      '저는 님을 도우러 온\n사람입니다',
      '착한 일 하면 복 받는다?\nㅇㅇ 맞음',
      '운빨도\n적금처럼 쌓는 거임',
      '오늘 선행 하나,\n행운 +1. 개이득',
      '행운은 배달 안 됨.\n직접 만드셈',
      '노력은 배신해도\n선행은 안 배신함',
      '될놈될?\n착한놈될임',
      '오늘의 운세:\n착한 일 하면 좋음',
      '행운도\n출석체크 하는 거 알지?',
      '복 짓는 사람이\n복 받는 거임',
      '어제 운 없었으면\n오늘 만들면 됨',
      '우주는 다 보고 있다.\n방금 그 선행도',
      '남 돕고 운 챙기고,\n일석이조 아님?',
      '행운아 안녕,\n오늘은 뭐 도와줄까',
    ],
    'en': [
      'Luck doesn’t knock.\nYou go knock on luck.',
      'What if you could\nbuy luck? Just asking.',
      'Hi, I’m literally here\nto help you.',
      'Crying over bad luck?\nGo do a good deed.',
      'Karma is just luck\nwith receipts',
      'Fortune favors the kind.\nIt’s canon.',
      'Stack kindness\nlike it’s savings',
      'One good deed a day\nkeeps bad luck away',
      'Luck doesn’t do delivery.\nYou make it yourself.',
      'Hard work may betray you.\nKindness won’t.',
      'The universe saw that.\nNice one.',
      'Today’s fortune:\ndo good, get good',
      'Even luck takes\nattendance, you know',
      'No luck? No problem.\nGo make some.',
      'Be the plot twist\nin someone’s bad day',
      'Luck is earned.\nStart earning.',
      'Help someone today.\nThe math works out.',
      'Hey lucky one —\nwho are we helping today?',
    ],
    'ja': [
      '運は来ない。\n迎えに行くもの',
      '運がないって\n泣いてるの?',
      '運もお金で\n買えたらいいのに?',
      'わたし、あなたを\n助けに来た者です',
      '徳を積む。\n運が積もる。以上',
      '努力は裏切る。\n善行は裏切らない',
      'カルマとは\nレシート付きの運',
      '幸運は配達不可。\n自分でつくるもの',
      '一日一善、\n厄除けになるらしい',
      '今日の運勢:\n善行すれば良し',
      '幸運にも\n出席確認があるらしい',
      '宇宙は見てる。\nさっきのいいことも',
      '運がない日は\n運をつくればいい',
      '推しは推せる時に、\n善行はできる時に',
      '徳ポイント、\n貯まってますか',
      '誰かの今日を\n救うのはきみかも',
      'いいことすると\nいいことある。マジで',
      'やあラッキーなきみ、\n今日は誰を助ける?',
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
