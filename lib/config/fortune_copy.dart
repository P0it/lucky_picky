// ════════════════════════════════════════════════════════════════
//  오늘의 행운지수 — 총운·조언 문구 풀. (색/아이템은 fortune_pool.dart)
//
//  이 파일은 문구의 원본(source of truth)이고 tool/sync_copy.dart 가 그대로
//  Supabase copy_lines 로 동기화한다 → 앱 배포 없이 문구가 바뀐다.
//  그래서 Flutter(dart:ui) 에 의존하면 안 된다 — 순수 dart 로 유지할 것.
//
//  주의: 이 앱은 뽑기앱이 아니라 선행앱. 가챠·RNG·리세마라 같은
//  뽑기 프레임은 쓰지 않는다.
//  사주·별자리 같은 "근거" 프레임도 안 씀 — 순수 재미용 행운지수.
//  낮은 지수 문구는 담담하게 받아주고 선행 쪽으로 슬쩍 연결한다.
//
//  톤 (2026-07-27 개편): 홈 데일리 문구(daily_quotes.dart)와 같은 결.
//  밈·유행어를 쓰지 않는다. 담백한 문장 + 살짝 미는 넛지.
//    · 종결은 해요체("~예요 / ~해요 / ~해보세요 / ~할까요 / ~답니다").
//      반말체·인터넷 종결어미(~하셈/~임/~함)는 쓰지 않는다.
//    · 훈수·명령조로 넘어가지 않게 한다 — 넛지는 반 발짝만.
//    · "그러니 착하게 살자" 식으로 설명하는 꼬리를 붙이지 않는다.
//    · 손익 계산 프레임("손해 같지만 남는 장사", "먼저 사과하면 이긴 것")도
//      쓰지 않는다 — 유저가 반려한 결이다.
//    · 소소한 예언(엘리베이터·붕어빵 꼬리·셔플 첫 곡)은 밈이 아니라
//      담백한 디테일이라 계속 쓴다. 이 톤의 재미는 여기서 나온다.
//  ※ 이전 버전은 무야호·난리자베스·럭키비키 같은 유행어 톤이었으나
//    "개그 욕심"이라는 판단으로 전면 교체했다. 되돌리지 말 것.
//
//  단순 번역이 아니라 각 언어권 표현으로 "직접 각색"한 문구입니다.
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
        '오늘 운은 좀 쉬어가는 중.\n대신 마음은 쓸 수 있어요',
        '안 풀리는 게\n당신 탓은 아니에요',
        '이런 날도\n지나가긴 해요',
        '기대는 낮게,\n친절은 그대로',
        '오늘은 운 말고\n실력으로 가는 날이에요',
        '이런 날일수록\n먼저 웃는 쪽이 편해요',
        '오늘의 목표는\n무사히 집에 가기',
        '신호등이 다 빨간불.\n천천히 가라는 뜻이에요',
        '엘리베이터는 오늘\n늘 반대편에 있어요',
        '이어폰 한쪽이\n말썽부릴 수 있어요',
        '배터리 8% 같은 하루.\n충전은 천천히 해요',
        '우산 챙기는 게\n마음 편할 거예요',
        '오늘 좀 억울한 일은\n그냥 흘려보내요',
        '운은 잠깐 자리를 비웠어요.\n곧 돌아와요',
        '조심조심.\n내일 몫이 쌓이는 중이에요',
        '별일 없이 지나가면\n그걸로 충분한 날이에요',
      ],
      [
        '나쁘지 않아요.\n딱 평타예요',
        '평범이 제일 어렵다던데\n해냈네요',
        '무난한 하루.\n반전은 하기 나름이에요',
        '미지근한 운세.\n온도는 올릴 수 있어요',
        '별일 없는 하루.\n그거 은근 귀해요',
        '기본기 탄탄한\n하루가 될 것 같아요',
        '소소한 행운 예보.\n우산은 필요 없어요',
        '친절 하나면\n한 칸 올라가요',
        '탕비실 간식,\n마지막 하나는 당신 거예요',
        '버스가 딱 맞게\n도착하는 하루예요',
        '커피 온도가\n딱 좋을 거예요',
        '오늘의 반전은\n오후 3시쯤 와요',
        '작게 웃을 일이\n두 번쯤 있어요',
        '점심 메뉴는\n남이 정해줄 것 같아요',
        '자판기 앞에서\n오래 고민하게 돼요',
        '운은 잔잔해요.\n파도는 직접 만들어요',
      ],
      [
        '오늘 꽤 맑아요.\n좋은 일 예감이에요',
        '행운 신호등,\n초록불 들어왔어요',
        '뭔가 될 것 같은 날.\n그 느낌 맞아요',
        '오늘 건넨 친절은\n이자 붙어서 돌아와요',
        '타이밍 좋네요.\n미뤄둔 거 오늘 해요',
        '오늘 웃을 일\n한 번은 있어요',
        '좋은 날엔\n나눠도 안 줄어요',
        '신호등이\n이상하게 다 초록불',
        '찾던 물건이\n제자리에서 나와요',
        '엘리베이터가 1층에서\n기다리고 있어요',
        '주머니에서 잊고 있던\n돈이 나올 수 있어요',
        '김밥에 계란이\n두 개 들어 있어요',
        '셔플 첫 곡부터\n인생곡일 거예요',
        '누가 먼저\n연락해 올 것 같아요',
        '지하철에서\n앉아서 갈 수 있어요',
        '오늘 사진 잘 나와요.\n한 장 남겨두세요',
      ],
      [
        '오늘은 뭘 해도\n되는 날이에요',
        '이 정도면\n사방이 네잎클로버예요',
        '대박 예감.\n나눠주고 다녀도 돼요',
        '오늘은 내가 누군가의\n행운이 될 차례예요',
        '운이 이 정도면\n전생에 나라를 구했나 봐요',
        '오늘 좀 하는데요?\n마음껏 즐겨요',
        '행운 최대치.\n아낌없이 써도 돼요',
        '오늘의 운은\n나눠 써도 남아요',
        '이런 날엔\n먼저 한턱내도 좋아요',
        '자판기에서 하나\n더 떨어질 수 있어요',
        '과자 봉지에 질소보다\n과자가 많은 날',
        '신호등 다 초록,\n엘리베이터도 1층',
        '뭘 눌러도 원하는 게\n나오는 하루예요',
        '오늘 잡은 지수,\n액자에 넣어도 돼요',
        '우산 안 챙겨도 돼요.\n비 안 와요',
        '붕어빵 꼬리까지\n팥이 차 있을 거예요',
      ],
    ],
    'en': [
      [
        'Luck is taking a day off.\nKindness still works',
        'Not your fault today.\nReally',
        'Rough days pass too',
        'Expect little,\nbe kind anyway',
        'Today runs on skill,\nnot luck',
        'On days like this,\nsmiling first is easier',
        'Today’s goal:\nget home safely',
        'Every light turns red.\nGo slow',
        'The elevator will be\non the wrong floor',
        'One earbud will act up.\nStay strong',
        'A low-battery kind of day.\nCharge slowly',
        'Bring an umbrella.\nJust in case',
        'Let today’s small\nannoyance slide',
        'Luck stepped out.\nIt comes back',
        'Careful mode on.\nTomorrow is stacking up',
        'Nothing happening\nis enough today',
      ],
      [
        'Not bad.\nSolidly average',
        'Ordinary is harder\nthan it sounds. Well done',
        'A plain day.\nThe twist is up to you',
        'Lukewarm fortune.\nYou can warm it up',
        'Nothing happens today.\nHighly underrated',
        'A day with\ngood fundamentals',
        'Small wins forecast.\nNo umbrella needed',
        'One kindness moves\nthe needle a notch',
        'Last snack in the\noffice kitchen? Yours',
        'The bus arrives exactly\nwhen you do',
        'Your coffee lands at\nthe perfect temperature',
        'A small twist arrives\naround 3pm',
        'Two small laughs\non today’s calendar',
        'Someone else picks\nlunch. A blessing',
        'You’ll stand at the vending\nmachine far too long',
        'Calm waters.\nYou make the waves',
      ],
      [
        'Pretty clear today.\nGood things ahead',
        'The luck light\njust turned green',
        'Feels like it might work out.\nThat feeling is right',
        'Kindness today\ncomes back with interest',
        'Good timing.\nDo the thing you postponed',
        'You’ll laugh\nat least once today',
        'Sharing today\ncosts you nothing',
        'Every traffic light\ngoes green today',
        'The thing you lost is\nexactly where you left it',
        'The elevator is waiting\non your floor',
        'Cash in a pocket\nyou forgot about',
        'Extra filling in\nwhatever you order',
        'First song on shuffle:\nan absolute favorite',
        'Someone texts you\nfirst today',
        'You get the seat\non the train',
        'Photos come out well.\nKeep one',
      ],
      [
        'Everything just works\ntoday',
        'Four-leaf clovers\neverywhere you step',
        'Jackpot energy.\nPass some around',
        'Today YOU are someone\nelse’s lucky charm',
        'This much luck?\nYou saved a country once',
        'You’re on a roll.\nEnjoy it',
        'Luck at full power.\nSpend it freely',
        'Today’s luck\nstretches when shared',
        'A good day to treat\nsomeone',
        'The vending machine\ndrops an extra one',
        'More chips than air\nin the bag today',
        'All lights green,\nelevator already here',
        'Whatever you press,\nyou get what you wanted',
        'Frame today’s number',
        'Leave the umbrella.\nIt won’t rain',
        'Filled all the way\nto the last bite',
      ],
    ],
    'ja': [
      [
        '運は今日お休み中。\n優しさは営業中です',
        'うまくいかないの、\nあなたのせいじゃない',
        'こういう日も\n過ぎていきます',
        '期待は低めに、\n親切はそのままで',
        '今日は運じゃなく\n実力で行く日',
        'こういう日は\n先に笑うほうが楽です',
        '今日の目標は\n無事に帰ること',
        '信号は全部赤の予感。\nゆっくり行きましょう',
        'エレベーターは今日\n必ず反対の階に',
        'イヤホン、片方だけ\n不調かも',
        '電池8%みたいな一日。\nゆっくり充電を',
        '傘、持っていくと\n安心かもしれません',
        '今日のモヤモヤは\n流してしまいましょう',
        '運はちょっと\n席を外しています',
        '慎重に。\n明日のぶんが貯まっています',
        '何事もなければ\nそれで十分な日です',
      ],
      [
        '悪くありません。\nちょうど平均です',
        '普通が一番むずかしい。\nできてますね',
        '無難な一日。\n逆転は自分次第です',
        'ぬるめの運勢。\n温度は上げられます',
        '何も起きない一日。\nそれ、贅沢です',
        '基本に忠実な\n一日になりそう',
        '小さいラッキー予報。\n傘は不要です',
        'ひとつの親切で\n一段上がります',
        '給湯室のお菓子、\n最後のひとつはあなたに',
        'バスがちょうど\n来るタイミングの日',
        'コーヒーの温度が\nちょうどよさそう',
        '小さな展開が\n15時ごろに',
        '小さく笑うこと、\n2回くらいありそう',
        'ランチは誰かが\n決めてくれそう',
        '自販機の前で\n長く迷いそうです',
        '運は穏やか。\n波は自分で',
      ],
      [
        '今日はかなり晴れ。\nいいこと、ありそうです',
        '運の信号、\n青になりました',
        'なんかいけそうな日。\nその直感、正解です',
        '今日の親切は\n利子つきで返ってきます',
        'タイミング良好。\n後回しのアレ、今日に',
        '今日は笑うこと\n一度はありそう',
        'いい日は\n分けても減りません',
        '信号がなぜか\n全部青になる日',
        '探し物は\nちゃんと元の場所に',
        'エレベーターが\n1階で待っています',
        'ポケットから\n忘れていたお金が出るかも',
        '頼んだものに\nおまけが入っていそう',
        'シャッフル1曲目が\n好きな曲の予感',
        '誰かから先に\n連絡が来そうです',
        '電車、たぶん座れます',
        '写真がよく撮れる日。\n一枚残しておいて',
      ],
      [
        '今日は何をしても\nうまくいく日です',
        '見渡す限り\n四つ葉のクローバー',
        '大当たりの予感。\nおすそ分けもぜひ',
        '今日はあなたが誰かの\nラッキーアイテム',
        '前世で国を救った\nレベルの運です',
        '今日は絶好調。\n存分にどうぞ',
        '運、最大出力。\n惜しみなく使って',
        '今日の運は\n分けても余ります',
        'こんな日は\nごちそうしてもいい日',
        '自販機、もう一本\n出てくるかも',
        'お菓子の袋、今日は\n窒素よりお菓子が多い',
        '信号は全部青、\nエレベーターも1階',
        '押したものが\nぜんぶ当たる日',
        '今日の数値、\n額に入れていいレベル',
        '傘はいりません。\n降らないので',
        'たい焼きは\n尻尾まであんこ入り',
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
      '부모님께 전화 한 통. 오래 걸리지 않아요',
      '고생한 나에게도 친절하게 대해 주세요',
      '뒷사람 위해 문 3초만 잡아 주세요',
      '오늘 한 명 칭찬해 주세요. 진심으로요',
      '지갑보다 마음을 먼저 열어 보세요',
      '자리 양보할 기회가 오면 바로 실행해요',
      '고맙다는 말, 오늘 세 번 써 봐요',
      '리뷰 하나 정성껏 남겨 보세요. 사장님이 웃어요',
      '먼저 사과하는 쪽이 대체로 마음 편해요',
      '식물에 물 주세요. 생명을 살리는 것도 선행이에요',
      '오늘 배운 꿀팁 아낌없이 공유해요',
      '화날 뻔한 순간에 한 번 참아요. 그것도 덕이에요',
      '힘들어 보이는 사람에게 밥 한 끼 사 주세요',
      '누군가의 실수, 오늘은 그냥 웃어넘겨요',
      '잘 자요. 내일 선행할 체력 충전도 선행이에요',
    ],
    'en': [
      'Hold the elevator for someone. That’s the start',
      'Greet someone first today',
      'Reply to that message you’ve been ignoring',
      'Pick up one piece of litter',
      'Buy a coworker a coffee',
      'Call your parents. It won’t take long',
      'Be kind to yourself too — you count',
      'Hold the door three extra seconds',
      'Compliment one person. Mean it',
      'Open your heart before your wallet',
      'Offer your seat if the moment comes',
      'Say thank you three times today',
      'Leave one thoughtful review somewhere',
      'Apologizing first is easier than waiting',
      'Water a plant. Keeping things alive counts',
      'Share a tip you learned today',
      'Almost got mad? Let one slide',
      'Treat someone having a rough week',
      'Laugh off someone’s small mistake today',
      'Sleep well. Resting up for tomorrow counts',
    ],
    'ja': [
      'エレベーターの「開」を押してあげよう',
      '今日会う人に先にあいさつ',
      '返してない返信、今返そう。それも善行',
      '落ちてるゴミをひとつだけ拾う',
      '同僚にコーヒーをおごってみる',
      '親に電話一本。すぐ終わります',
      'がんばってる自分にも優しく',
      '後ろの人のためにドアを3秒キープ',
      '今日ひとりを本気で褒める',
      '財布より先に心を開いてみる',
      '席をゆずるチャンスが来たら即実行',
      '「ありがとう」を今日3回言う',
      'レビューをひとつ丁寧に書く',
      '先に謝ると、あとが楽です',
      '植物に水やり。命を守るのも善行',
      '今日知った豆知識をシェアする',
      'イラッとしても一回スルー。それも徳',
      '疲れてる人にごはんをごちそうする',
      '誰かの小さなミスは笑って流す',
      'よく寝る。明日のための充電も善行',
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
