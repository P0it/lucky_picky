// ════════════════════════════════════════════════════════════════
//  매일 바뀌는 홈 화면 문구 — 선행을 부드럽게 권하는 한마디.
//
//  주의: 이 앱은 뽑기앱이 아니라 선행앱. 가챠·RNG·리세마라 같은
//  뽑기 프레임은 쓰지 않는다.
//  핵심 메시지 = 운은 기다리는 게 아니라 선행으로 직접 만드는 것.
//
//  날짜(연중 일수)를 기준으로 하나를 고르므로,
//  같은 날에는 항상 같은 문구가 나오고 날이 바뀌면 다음 문구로 넘어갑니다.
//
//  톤 (2026-07-27 개편): 밈·유행어를 쓰지 않는다.
//  담백한 속담·관용구 결 + 살짝 미는 넛지. 강요가 아니라 권유.
//    · 짧은 완결형 문장. 홈 헤드라인은 21px 2줄이 한계다.
//    · 종결은 해요체("~예요 / ~해요 / ~해보세요 / ~할까요 / ~답니다").
//      반말체·인터넷 종결어미(~하셈/~임/~함)는 쓰지 않는다.
//    · "그러니 착하게 살자" 식으로 설명하는 꼬리를 붙이지 않는다.
//    · 훈수·명령조로 넘어가지 않게 한다 — 넛지는 반 발짝만.
//  ※ 이전 버전은 무한도전 밈·난리자베스 같은 유행어 톤이었으나
//    "개그 욕심"이라는 판단으로 전면 교체했다. 되돌리지 말 것.
//
//  단순 번역이 아니라 각 언어권 표현으로 "직접 각색"한 문구입니다.
//  한국어 속담을 직역하면 죽으므로, 영어·일본어는 같은 뜻의 현지
//  관용구로 갈아끼웠습니다(정 없으면 평이한 문장으로).
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
      '좋은 게 좋은 거잖아요.',
      '오지랖일까 망설이지 마세요.',
      '가는 말이 고우면\n오는 말도 고와요.',
      '사실, 나를 위한 일일지도 몰라요.',
      '오늘은 먼저 인사해볼까요.',
      '웃는 얼굴에\n침 못 뱉는대요.',
      '어색한 건 잠깐이에요.',
      '콩 한 쪽도 나누면\n두 쪽이 돼요.',
      '배려도 똑똑해야 할 수 있답니다.',
      '기다리기보단,\n내가 먼저 다가가볼까요.',
      '발 없는 말이 천 리 가요.\n좋은 말도요.',
      '괜한 참견 같아도\n대부분은 고마워해요.',
      '굳이 배려해보세요.',
      '돌고 도는 게 인심이라잖아요.',
      '오늘은 누구부터 챙겨볼까요.',
      '티 낼까 말까 싶을 땐\n티 내는 쪽으로.',
      '뿌린 대로 거둔대요.\n오늘 뭘 뿌릴까요.',
      '늦었나 싶어도\n대체로 안 늦었어요.',
      '세상 참 좁아요.\n그래서 드리는 말씀이에요.',
      '한 사람만 웃겨보고 올까요.',
      '안 하면 계속 생각나요.\n그냥 해보세요.',
    ],
    'en': [
      'What goes around\ncomes around. Really.',
      'Don’t overthink it.\nJust be kind.',
      'A kind word\ncosts nothing.',
      'Honestly, it might be\nfor you too.',
      'Shall we say hello first?',
      'Kindness takes\na little cleverness.',
      'The awkward part\nlasts a second.',
      'Share it and\nsomehow it grows.',
      'Rather than waiting,\nshall we go first?',
      'Good words travel\nfurther than you think.',
      'Feels like meddling?\nMost people are glad.',
      'Be kind on purpose today.',
      'What you give\nhas a way of coming back.',
      'Who are you\nchecking in on today?',
      'When in doubt,\nlean toward doing it.',
      'It’s smaller than it looks.\nJust do it.',
      'Not too late.\nIt rarely is.',
      'Shall we make\none person laugh today?',
    ],
    'ja': [
      '情けは人の為ならず。\n本当の話です。',
      'お節介かな、と\n迷わなくていいですよ。',
      'ひと言でいいんです。',
      '実は、自分のため\nかもしれません。',
      '今日は先に\n挨拶してみましょうか。',
      '笑う門には福来る、\nと言いますよね。',
      '気まずいのは一瞬です。',
      '分けると、なぜか\n増えるものがあります。',
      '気づかいにも、\nちょっとしたコツを。',
      '待つより、\n先に行ってみましょうか。',
      'いい言葉ほど\n遠くまで届きます。',
      '余計かなと思っても、\nたいてい喜ばれます。',
      'あえて、やさしく。',
      '巡り巡って、\n戻ってくるそうです。',
      '今日は誰から\n気にかけましょうか。',
      '迷ったら、やる方に。',
      '遅いかなと思っても、\nだいたい間に合います。',
      '今日はひとりだけ、\n笑わせてみましょうか。',
    ],
  };

  static const _fallbackLang = 'en';

  /// 앱에 번들된 [lang] 문구 풀. 서버(copy_lines) 문구가 없을 때의 폴백이라
  /// CopyBook 이 직접 참조한다. 미지원 언어는 영어로 폴백.
  static List<String> poolFor(String lang) =>
      _byLang[lang] ?? _byLang[_fallbackLang]!;

  /// [pool] 에서 오늘 날짜에 해당하는 문구 하나. 연중 일수 기준 순환이라
  /// 같은 날엔 항상 같은 문구가 나온다. (서버 문구도 같은 규칙으로 고른다.)
  static String pickForDay(List<String> pool, DateTime day) {
    final startOfYear = DateTime(day.year, 1, 1);
    final dayOfYear = day.difference(startOfYear).inDays; // 0..365
    return pool[dayOfYear % pool.length];
  }

  /// [lang] 언어의 오늘 문구(번들 기준). 서버 문구까지 반영하려면 CopyBook 을 쓸 것.
  /// [now] 미지정 시 현재 시각 기준.
  static String forToday(String lang, [DateTime? now]) =>
      pickForDay(poolFor(lang), now ?? DateTime.now());
}
