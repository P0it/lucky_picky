// ════════════════════════════════════════════════════════════════
//  오늘의 행운지수 — 총운·조언 문구 풀. (색/아이템은 fortune_pool.dart)
//
//  이 파일은 문구의 원본(source of truth)이고 tool/sync_copy.dart 가 그대로
//  Supabase copy_lines 로 동기화한다 → 앱 배포 없이 문구가 바뀐다.
//  그래서 Flutter(dart:ui) 에 의존하면 안 된다 — 순수 dart 로 유지할 것.
//
//  주의: 이 앱은 뽑기앱이 아니라 선행앱. 유머 톤은 가져가되
//  가챠·RNG·리세마라 같은 뽑기 프레임은 쓰지 않는다.
//  사주·별자리 같은 "근거" 프레임도 안 씀 — 순수 재미용 행운지수.
//  낮은 지수 문구는 자조로 받아치고 "그래서 오늘 선행 각"으로 연결한다.
//
//  말투 규칙(한국어): MZ는 "메시지"에서 나오고 어미는 친근한 해요체로 간다.
//  "~하셈 / ~임 / ~함 / ~됨" 같은 인터넷 종결어미 금지 — 가벼워 보인다.
//  반말체(~다/~하자)도 아니고, 해요체("~예요 / ~해요 / ~하세요")가 기본.
//  주 타깃은 2030 여성 — 트렌디하고 감각적이어야 한다.
//  쓰는 결(2026 상반기 실제 유행 — 웹 검증): 난리자베스([감정]+자베스),
//  장항준적 사고("~은 내일부터"), 그린그린/레드레드, 좋🤙다,
//  "아, 이런 걸로 피곤하고 싶지 않다", "피라미드에도 악플이 달린다",
//  "~감도 안 온다", "~그러더라고" + 갓생, 오운완→"오선완".
//  럭키비키는 피크가 지났으니 소량만. 새 유행어는 추측 말고 검색으로 확인.
//  금지: 만수르·개이득 같은 올드한 표현, 남초 커뮤/주식/게임 결
//  (존버, 떡상, 억까, 폼 미쳤다, 무지성) — 이런 게 "밤티"라 UX를 해친다.
//
//  언어별 문구 개수는 서로 달라도 됨 — 조회 시 리스트 길이로 modulo.
// ════════════════════════════════════════════════════════════════

class FortuneCopy {
  const FortuneCopy._();

  static const fallbackLang = 'en';

  // ── 총운: [등급 0=흐림, 1=보통, 2=맑음, 3=대박] × 문구 ──────────
  static const Map<String, List<List<String>>> _overallByLang = {
    'ko': [
      [
        '오늘 운은 좀 아끼는 중…\n내일 몰아준대요',
        '운이 낮잠 자는 중.\n깨우는 법은 선행이에요',
        '오늘은 수동모드.\n행운은 직접 만들어요',
        '이럴 때일수록\n착한 일 할 타이밍이에요',
        '운세가 저점이면\n지금이 매수 타이밍이에요',
        '조심조심.\n대신 내일치 운 적립 중이에요',
        '정신 차려요,\n이 각박한 세상 속에서도 선행',
        '운은 로딩 중…\n선행으로 부스트할 수 있어요',
        '오늘 얼마나 안 좋을지\n감도 안 오네요',
        '이런 날은 선행이 답이다\n그러더라고요',
        '아, 이런 걸로\n피곤하고 싶지 않다',
        '피라미드에도 악플 달려요.\n오늘 그 일도 그런 거고요',
        '걱정은 내일부터.\n이게 장항준적 사고',
      ],
      [
        '나쁘지 않아요.\n딱 평타',
        '무난무난.\n선행 하나면 상향 조정돼요',
        '보통의 하루.\n반전은 오늘 하기 나름이에요',
        '운세 미지근.\n온도 올리는 건 친절이에요',
        '평범이 제일 어렵다던데\n해냈네요',
        '못 먹어도 고!\n선행 하나면 위로 가요',
        '소소한 행운 예보.\n우산은 필요 없어요',
        '기본기 탄탄한\n하루가 될 것 같아요',
        '중간은 가요.\n갓생까진 한 끗',
        '선행 하나면\n지수 바로 올라가요',
        '나쁘지 않은데요?\n이 정도면 좋다~ 🤙',
        '선행 하나면 올라간다\n그러더라고요',
      ],
      [
        '오늘 꽤 맑아요.\n좋은 일 예감',
        '행운 신호등,\n초록불 들어왔어요',
        '뭔가 될 것 같은 날.\n그 느낌 맞아요',
        '오늘 착한 일 하면\n이자 붙어서 돌아와요',
        '타이밍 좋네요.\n미뤄둔 거 오늘 해요',
        '주변에 행운 입자\n농도가 짙어요',
        '작은 친절이 큰 행운으로\n돌아오는 날이에요',
        '오늘 웃을 일 있어요.\n"무야호" 나올지도',
        '오늘 지수?\n그린그린 💚',
        '행복회로 돌려도\n되는 날이에요',
        '오늘 컨디션,\n주인공 각이에요',
        '착한 일 하면 이자 붙는다\n그러더라고요',
      ],
      [
        '운세 만렙 근접.\n뭐든 되는 날이에요',
        '이 정도면\n사방이 네잎클로버예요',
        '대박 예감.\n행운 나눠주고 다녀요',
        '이거 실화냐?\n소리 나오는 날이에요',
        '오늘은 내가 누군가의\n행운이 될 차례예요',
        '운이 이 정도면\n전생에 나라를 구했나요?',
        '오늘 좀 하는데요?\n마음껏 즐겨요',
        '행운 최대출력.\n아낌없이 써요',
        '오늘 지수 최고치.\n완전 럭키비키',
        '이 정도면 갓생 확정.\n인증하고 가세요',
        '오늘 운세\n난리자베스',
        '오늘 얼마나 잘될지\n감도 안 오네요',
      ],
    ],
    'en': [
      [
        'Luck is buffering…\ntry a good deed',
        'Low battery luck.\nKindness is the charger',
        'Luck called in sick.\nMake your own today',
        'Rough forecast —\nperfect day to earn karma',
        'Luck is on airplane mode.\nGood deeds still send',
        'Your luck is at a low.\nBuy the dip',
        'Careful mode on.\nTomorrow owes you one',
        'Stats are low,\nvibes can still be high',
      ],
      [
        'Solidly mid.\nOne good deed = instant buff',
        'Average day.\nPlot twist available on request',
        'Lukewarm luck.\nKindness turns up the heat',
        'Nothing crazy,\nnothing tragic. Balanced',
        'Room-temperature fortune.\nYou set the vibe',
        'A basic day —\nin a comforting way',
        'Small wins forecast.\nNo umbrella needed',
        'Perfectly average.\nUpgrade path: be kind',
      ],
      [
        'Green light\nfrom the luck gods',
        'Something good is loading…\nalmost there',
        'Be kind today —\nit returns with interest',
        'Lucky particle density:\nhigh',
        'Good timing day.\nDo the thing you postponed',
        'A small kindness\ncomes back big today',
        'Forecast: clear skies,\nhigh chance of smiles',
        'The universe is lowkey\nrooting for you',
      ],
      [
        'Near max luck.\nToday just works',
        'Four-leaf clovers\neverywhere you step',
        'Jackpot energy.\nShare the luck around',
        'Main character day.\nConfirmed',
        'Today YOU are someone\nelse\'s lucky charm',
        'Luck level: did you\nsave a country?',
        'Legendary day unlocked.\nEnjoy it',
        'Full power luck.\nSpend it generously',
      ],
    ],
    'ja': [
      [
        '運は充電中…\n善行でブースト可',
        '運勢低め。\nでも徳は積める',
        '今日は慎重モード。\n明日に運を貯金中',
        '運が在宅勤務らしい。\n自作しよう',
        '数値は低い、\n気持ちは高く',
        '運の底値。\n仕込みどき',
        'こういう日こそ\n一日一善',
        '運はローディング中。\n善行で読み込み加速',
      ],
      [
        '悪くない。\nちょうど平均',
        '普通の日。\n逆転はきみの手の中',
        'ぬるめの運勢。\n親切で温度上げてこ',
        '無難オブ無難。\n一善で上方修正可',
        '小さいラッキー予報。\n傘は不要',
        '平凡って\n実は尊い',
        '基本に忠実な\n一日になりそう',
        '中の上を\n狙える日',
      ],
      [
        '今日はかなり晴れ。\nいいこと予感',
        '運の信号、\n青になりました',
        'なんかいけそうな日。\nその直感、正解',
        '今日の善行は\n利子つきで返ってくる',
        'タイミング良き。\n後回しのアレ、今日やろ',
        'ラッキー粒子、\n濃度高め',
        '小さな親切が\n大きな幸運になる日',
        '今日は笑うこと\nあるらしい',
      ],
      [
        '運勢ほぼカンスト。\n何でもいける',
        '見渡す限り\n四つ葉クローバー',
        '大当たりの予感。\n運のおすそ分けを',
        '主人公モード\n発動',
        '今日はきみが誰かの\nラッキーアイテム',
        '前世で国を救った?\nってレベル',
        '伝説の一日、\n開幕',
        '運、最大出力。\n惜しみなく使え',
      ],
    ],
  };

  // ── 조언: 전부 "오늘 해볼 만한 선행" 유도 ──────────────────────
  static const Map<String, List<String>> _adviceByLang = {
    'ko': [
      '엘리베이터 문 한 번 잡아주세요. 그게 시작이에요',
      '오늘 마주치는 사람에게 먼저 인사해 보세요',
      '미뤄둔 답장 지금 해요. 그것도 선행이에요',
      '길에 떨어진 쓰레기 하나만 주워 보세요',
      '동료에게 커피 한 잔 사 주세요',
      '부모님께 전화 한 통. 효도는 최고의 선행이에요',
      '고생한 나에게도 친절하게 대해 주세요',
      '뒷사람 위해 문 3초만 잡아 주세요',
      '오늘 한 명 칭찬해 주세요. 진심으로요',
      '지갑 말고 마음을 열면 운이 들어와요',
      '자리 양보할 기회가 오면 바로 실행해요',
      '고맙다는 말, 오늘 세 번 써 봐요',
      '리뷰 하나 정성껏 남겨 보세요. 사장님이 웃어요',
      '먼저 사과하면 진 게 아니라 이긴 거예요',
      '식물에 물 주세요. 생명을 살리는 것도 선행이에요',
      '오늘 배운 꿀팁 아낌없이 공유해요',
      '화날 뻔한 순간에 한 번 참아요. 그것도 덕이에요',
      '힘들어 보이는 사람에게 밥 한 끼 사 주세요',
      '누군가의 실수, 오늘은 그냥 웃어넘겨요',
      '잘 자요. 내일 선행할 체력 충전도 선행이에요',
    ],
    'en': [
      'Hold the elevator for someone. That\'s the start',
      'Greet someone first today',
      'Reply to that message you\'ve been ignoring',
      'Pick up one piece of litter',
      'Buy a coworker a coffee',
      'Call your parents. Elite good deed',
      'Be kind to yourself too — you count',
      'Hold the door three extra seconds',
      'Compliment one person. Mean it',
      'Open your heart, not your wallet',
      'Offer your seat if the moment comes',
      'Say thank you three times today',
      'Leave one thoughtful review somewhere',
      'Apologizing first is winning, actually',
      'Water a plant. Saving lives counts',
      'Share a tip you learned today',
      'Almost got mad? Let one slide',
      'Treat someone having a rough week',
      'Laugh off someone\'s small mistake today',
      'Sleep well. Charging up for good deeds counts',
    ],
    'ja': [
      'エレベーターの「開」を押してあげよう',
      '今日会う人に先にあいさつ',
      '返してない返信、今返そう。それも善行',
      '落ちてるゴミをひとつだけ拾う',
      '同僚にコーヒーおごってみる',
      '親に電話一本。最強の徳積み',
      'がんばってる自分にも優しく',
      '後ろの人のためにドアを3秒キープ',
      '今日ひとりを本気で褒める',
      '財布より心を開くと運が入る',
      '席をゆずるチャンスが来たら即実行',
      '「ありがとう」を今日3回言う',
      'レビューをひとつ丁寧に書く',
      '先に謝れる人が実は勝ち',
      '植物に水やり。命を守るのも善行',
      '今日知った豆知識をシェアする',
      'イラッとしても一回スルー。それも徳',
      '疲れてる人にごはんをごちそうする',
      '誰かの小さなミスは笑って流す',
      'よく寝る。明日の善行の充電も善行',
    ],
  };

  // ── 번들 풀 접근자 (서버 문구가 없을 때의 폴백 — CopyBook 이 참조) ──
  static List<String> overallPool(String lang, int grade) {
    final grades = _overallByLang[lang] ?? _overallByLang[fallbackLang]!;
    return grades[grade];
  }

  static List<String> advicePool(String lang) =>
      _adviceByLang[lang] ?? _adviceByLang[fallbackLang]!;
}
