// ════════════════════════════════════════════════════════════════
//  행운권 카탈로그 — 가챠에서 나오는 모든 행운권의 원본 데이터.
//
//  daily_quotes.dart 와 같은 원칙으로, 단순 번역이 아니라
//  각 언어권 밈 감성에 맞춰 "직접 각색"한 문구입니다.
//  한국어는 짤·유행어 톤, 영어는 인터넷 밈 톤, 일본어는 넷슬랭 톤.
//
//  ID 규칙: c=일반(common), r=희귀(rare), e=영웅(epic),
//           l=전설(legendary), m=신화(mythic) + 2자리 번호.
//  ID 는 영속 데이터(도감/기록)에 저장되므로 바꾸지 않습니다.
// ════════════════════════════════════════════════════════════════

/// 희귀도 5단계. 순서 = 낮은 등급 → 높은 등급.
enum Rarity { common, rare, epic, legendary, mythic }

class LuckTicket {
  final String id;
  final Rarity rarity;
  final Map<String, String> _text; // lang code -> 문구

  const LuckTicket(this.id, this.rarity, this._text);

  String text(String lang) => _text[lang] ?? _text['en'] ?? _text.values.first;
}

class LuckCatalog {
  const LuckCatalog._();

  /// 등급별 추첨 가중치(%). 합계 100.
  static const Map<Rarity, int> weights = {
    Rarity.common: 50,
    Rarity.rare: 27,
    Rarity.epic: 15,
    Rarity.legendary: 6,
    Rarity.mythic: 2,
  };

  /// 강화 최대 레벨. Lv.L → Lv.L+1 에 필요한 중복 수 = L.
  static const int maxLevel = 5;

  /// 등급 표시명.
  static const Map<Rarity, Map<String, String>> _rarityNames = {
    Rarity.common: {'ko': '일반', 'en': 'Common', 'ja': 'ノーマル'},
    Rarity.rare: {'ko': '희귀', 'en': 'Rare', 'ja': 'レア'},
    Rarity.epic: {'ko': '영웅', 'en': 'Epic', 'ja': 'エピック'},
    Rarity.legendary: {'ko': '전설', 'en': 'Legendary', 'ja': 'レジェンド'},
    Rarity.mythic: {'ko': '신화', 'en': 'Mythic', 'ja': 'ミシック'},
  };

  /// 등급별 해학적 확률 비유 — 확률 정보 시트에 % 옆에 표기.
  static const Map<Rarity, Map<String, String>> _rarityAnalogies = {
    Rarity.common: {
      'ko': '동전 던져서 앞면 나올 확률',
      'en': 'A literal coin flip',
      'ja': 'コイントスで表が出る確率',
    },
    Rarity.rare: {
      'ko': '가위바위보 첫 판에 이길 확률쯤',
      'en': 'About the odds of winning rock-paper-scissors round one',
      'ja': 'じゃんけん初戦で勝つ確率くらい',
    },
    Rarity.epic: {
      'ko': '치킨 시켰는데 닭다리가 3개 들어있을 확률 (체감)',
      'en': 'Odds of a bonus nugget in the box (vibes)',
      'ja': '唐揚げ弁当に唐揚げが1個多い確率（体感）',
    },
    Rarity.legendary: {
      'ko': '소개팅 첫 만남에 통하는 확률 (체감)',
      'en': 'Odds of a first date actually going well (vibes)',
      'ja': '初対面で意気投合する確率（体感）',
    },
    Rarity.mythic: {
      'ko': '그래도 로또 1등보다 약 160만 배 잘 나옴',
      'en': 'Still ~1.6 million times likelier than the lottery jackpot',
      'ja': 'それでもロト1等より約160万倍出やすい',
    },
  };

  static String rarityName(Rarity r, String lang) =>
      _rarityNames[r]![lang] ?? _rarityNames[r]!['en']!;

  static String rarityAnalogy(Rarity r, String lang) =>
      _rarityAnalogies[r]![lang] ?? _rarityAnalogies[r]!['en']!;

  static LuckTicket? byId(String id) => _byId[id];

  static List<LuckTicket> byRarity(Rarity r) =>
      tickets.where((t) => t.rarity == r).toList(growable: false);

  static final Map<String, LuckTicket> _byId = {
    for (final t in tickets) t.id: t,
  };

  // ────────────────────────────────────────────────────────────
  //  일반 (30종) — 소소하지만 확실한 일상의 행운
  // ────────────────────────────────────────────────────────────
  static const List<LuckTicket> tickets = [
    LuckTicket('c01', Rarity.common, {
      'ko': '엘리베이터가 기다리지 않고 바로 오는 행운',
      'en': 'Luck of the elevator arriving the second you press the button',
      'ja': 'エレベーターが待たずに即来る幸運',
    }),
    LuckTicket('c02', Rarity.common, {
      'ko': '정류장에 도착하자마자 버스가 오는 행운',
      'en': 'Luck of the bus pulling up right as you arrive',
      'ja': 'バス停に着いた瞬間バスが来る幸運',
    }),
    LuckTicket('c03', Rarity.common, {
      'ko': '가는 길 신호등이 전부 초록불인 행운',
      'en': 'Luck of hitting every green light on the way',
      'ja': '信号が全部青のまま進める幸運',
    }),
    LuckTicket('c04', Rarity.common, {
      'ko': '편의점에 최애 삼각김밥이 딱 하나 남아있는 행운',
      'en': 'Luck of the last one of your favorite snack still being there',
      'ja': 'コンビニに推しのおにぎりが1個だけ残ってる幸運',
    }),
    LuckTicket('c05', Rarity.common, {
      'ko': '알람 없이도 개운하게 눈 떠지는 행운',
      'en': 'Luck of waking up refreshed before the alarm',
      'ja': 'アラームなしでスッキリ目覚める幸運',
    }),
    LuckTicket('c06', Rarity.common, {
      'ko': '머리가 한 번에 마음대로 세팅되는 행운',
      'en': 'Luck of a zero-effort good hair day',
      'ja': '髪が一発でキマる幸運',
    }),
    LuckTicket('c07', Rarity.common, {
      'ko': '지하철 타자마자 눈앞에 자리 나는 행운',
      'en': 'Luck of a subway seat opening up right in front of you',
      'ja': '電車で目の前の席がスッと空く幸運',
    }),
    LuckTicket('c08', Rarity.common, {
      'ko': '노래 셔플이 취향 저격곡만 트는 행운',
      'en': 'Luck of shuffle playing nothing but bangers',
      'ja': 'シャッフルが神曲しか流さない幸運',
    }),
    LuckTicket('c09', Rarity.common, {
      'ko': '카페에 콘센트 자리가 남아있는 행운',
      'en': 'Luck of the café seat with the power outlet being free',
      'ja': 'カフェのコンセント席が空いてる幸運',
    }),
    LuckTicket('c10', Rarity.common, {
      'ko': '택배가 예정보다 하루 빨리 오는 행운',
      'en': 'Luck of the package arriving a day early',
      'ja': '荷物が予定より1日早く届く幸運',
    }),
    LuckTicket('c11', Rarity.common, {
      'ko': '라면 물조절 완벽 성공의 행운',
      'en': 'Luck of nailing the perfect noodle-to-water ratio',
      'ja': 'ラーメンのお湯加減が完璧に決まる幸運',
    }),
    LuckTicket('c12', Rarity.common, {
      'ko': '마트에서 제일 빨리 줄어드는 계산대 줄에 서는 행운',
      'en': 'Luck of picking the checkout line that actually moves',
      'ja': 'レジで一番早く進む列を引き当てる幸運',
    }),
    LuckTicket('c13', Rarity.common, {
      'ko': '휴대폰 배터리가 유난히 오래가는 하루의 행운',
      'en': 'Luck of your phone battery mysteriously lasting all day',
      'ja': 'スマホの充電が謎に長持ちする日の幸運',
    }),
    LuckTicket('c14', Rarity.common, {
      'ko': '재채기가 딱 한 번으로 시원하게 끝나는 행운',
      'en': 'Luck of the sneeze actually coming out on the first try',
      'ja': 'くしゃみが一発でスッキリ終わる幸運',
    }),
    LuckTicket('c15', Rarity.common, {
      'ko': '주머니에서 만 원을 발견하는 행운 (세탁 전)',
      'en': 'Luck of finding cash in your pocket (before laundry day)',
      'ja': 'ポケットから千円を発掘する幸運（洗濯前）',
    }),
    LuckTicket('c16', Rarity.common, {
      'ko': '보던 웹툰 다음 화가 무료로 풀려있는 행운',
      'en': 'Luck of the next episode being free when you catch up',
      'ja': '続きの話がちょうど無料開放されてる幸運',
    }),
    LuckTicket('c17', Rarity.common, {
      'ko': '점심 메뉴 고민이 한 번에 끝나는 행운',
      'en': 'Luck of deciding lunch in one try, no group debate',
      'ja': 'ランチ選びが一瞬で決まる幸運',
    }),
    LuckTicket('c18', Rarity.common, {
      'ko': '이어폰 줄이 하나도 안 꼬여있는 행운 (유선 한정)',
      'en': 'Luck of untangled earphones (wired gang only)',
      'ja': 'イヤホンが全く絡まってない幸運（有線限定）',
    }),
    LuckTicket('c19', Rarity.common, {
      'ko': '사진이 한 방에 잘 나오는 행운',
      'en': 'Luck of the first photo being the keeper',
      'ja': '写真が一発で盛れる幸運',
    }),
    LuckTicket('c20', Rarity.common, {
      'ko': '우산 챙긴 날에만 비가 오는 행운',
      'en': 'Luck of rain only on days you brought the umbrella',
      'ja': '傘を持った日に限って雨が降る幸運',
    }),
    LuckTicket('c21', Rarity.common, {
      'ko': '엘리베이터를 혼자 타고 조용히 올라가는 행운',
      'en': 'Luck of riding the elevator gloriously alone',
      'ja': 'エレベーターを一人で貸切できる幸運',
    }),
    LuckTicket('c22', Rarity.common, {
      'ko': '급한 날 화장실에 줄이 없는 행운',
      'en': 'Luck of no bathroom line exactly when it matters',
      'ja': 'ピンチの時にトイレが空いてる幸運',
    }),
    LuckTicket('c23', Rarity.common, {
      'ko': '자판기에서 음료가 두 개 나오는 행운',
      'en': 'Luck of the vending machine dropping two drinks',
      'ja': '自販機からドリンクが2本出てくる幸運',
    }),
    LuckTicket('c24', Rarity.common, {
      'ko': '붕어빵 트럭을 우연히 만나는 행운',
      'en': 'Luck of stumbling onto the food truck of your dreams',
      'ja': 'たい焼き屋台に偶然出会う幸運',
    }),
    LuckTicket('c25', Rarity.common, {
      'ko': '겨울인데 정전기 한 번도 안 오르는 행운',
      'en': 'Luck of zero static shocks all winter day',
      'ja': '冬なのに静電気ゼロで過ごせる幸運',
    }),
    LuckTicket('c26', Rarity.common, {
      'ko': '다이어트 중인데 회식이 안 잡히는 행운',
      'en': 'Luck of no surprise dinner invites while on a diet',
      'ja': 'ダイエット中に飲み会が入らない幸運',
    }),
    LuckTicket('c27', Rarity.common, {
      'ko': '보내기 직전에 문자 오타를 발견하는 행운',
      'en': 'Luck of catching the typo right before hitting send',
      'ja': '送信直前に誤字に気づく幸運',
    }),
    LuckTicket('c28', Rarity.common, {
      'ko': '좋아하는 빵이 막 구워져 나오는 타이밍의 행운',
      'en': 'Luck of your favorite bread coming out fresh as you walk in',
      'ja': '好きなパンが焼きたてで出てくる幸運',
    }),
    LuckTicket('c29', Rarity.common, {
      'ko': '책상 모서리에 무릎 안 부딪히고 지나가는 행운',
      'en': 'Luck of clearing the table corner without a knee tax',
      'ja': '机の角に膝をぶつけずに済む幸運',
    }),
    LuckTicket('c30', Rarity.common, {
      'ko': '낮잠 5분 잤는데 5시간 잔 것 같은 행운',
      'en': 'Luck of a 5-minute nap hitting like 5 hours',
      'ja': '5分の昼寝が5時間分に感じる幸運',
    }),

    // ────────────────────────────────────────────────────────────
    //  희귀 (20종) — 오늘 하루가 즐거워지는 행운
    // ────────────────────────────────────────────────────────────
    LuckTicket('r01', Rarity.rare, {
      'ko': '새로운 인연의 행운 (연인 아님)',
      'en': 'Luck of a new connection (not romantic, calm down)',
      'ja': '新しい出会いの幸運（恋人ではない）',
    }),
    LuckTicket('r02', Rarity.rare, {
      'ko': '중고거래 첫 문의가 쿨거래인 행운',
      'en': 'Luck of the first buyer being a no-haggle legend',
      'ja': 'フリマの最初の問い合わせが即決の幸運',
    }),
    LuckTicket('r03', Rarity.rare, {
      'ko': '배달비 무료 쿠폰이 때마침 있는 행운',
      'en': 'Luck of a free-delivery coupon exactly when cravings hit',
      'ja': '送料無料クーポンがちょうどある幸運',
    }),
    LuckTicket('r04', Rarity.rare, {
      'ko': '회의가 갑자기 취소되는 행운',
      'en': 'Luck of the meeting getting cancelled last minute',
      'ja': '会議が急にキャンセルされる幸運',
    }),
    LuckTicket('r05', Rarity.rare, {
      'ko': '세일 코너에 내 사이즈만 남아있는 행운',
      'en': 'Luck of the sale rack having exactly your size',
      'ja': 'セール品に自分のサイズだけ残ってる幸運',
    }),
    LuckTicket('r06', Rarity.rare, {
      'ko': '시험 직전에 본 부분이 그대로 나오는 행운',
      'en': 'Luck of the exam covering the one page you crammed',
      'ja': '直前に見たところがそのまま出る幸運',
    }),
    LuckTicket('r07', Rarity.rare, {
      'ko': '미용실에서 말한 대로 잘려 나오는 행운',
      'en': 'Luck of the haircut looking like what you actually asked for',
      'ja': '美容院で注文通りの髪型になる幸運',
    }),
    LuckTicket('r08', Rarity.rare, {
      'ko': '사진첩 정리하다 추억 대박을 발견하는 행운',
      'en': 'Luck of finding a gem while cleaning your camera roll',
      'ja': 'アルバム整理で神写真を発掘する幸運',
    }),
    LuckTicket('r09', Rarity.rare, {
      'ko': '구독 해지 직전에 반값 제안을 받는 행운',
      'en': 'Luck of the 50%-off offer right as you hit cancel',
      'ja': '解約直前に半額オファーが来る幸運',
    }),
    LuckTicket('r10', Rarity.rare, {
      'ko': '티켓팅 새로고침 한 번에 자리 잡는 행운',
      'en': 'Luck of scoring tickets on the very first refresh',
      'ja': 'チケット争奪戦を一発更新で勝ち抜く幸運',
    }),
    LuckTicket('r11', Rarity.rare, {
      'ko': '인생 맛집을 웨이팅 없이 들어가는 행운',
      'en': 'Luck of walking into the hyped restaurant, zero wait',
      'ja': '人気店に並ばず入れる幸運',
    }),
    LuckTicket('r12', Rarity.rare, {
      'ko': '단톡방에서 내 드립이 제대로 먹히는 행운',
      'en': 'Luck of your joke actually landing in the group chat',
      'ja': 'グルチャで自分のボケがウケる幸運',
    }),
    LuckTicket('r13', Rarity.rare, {
      'ko': '좋아하는 노래 라이브가 음원보다 좋은 행운',
      'en': 'Luck of the live version being better than the studio one',
      'ja': '推し曲のライブが音源超えしてる幸運',
    }),
    LuckTicket('r14', Rarity.rare, {
      'ko': '비행기 옆자리가 비어있는 행운',
      'en': 'Luck of the middle seat next to you staying empty',
      'ja': '飛行機の隣席が空席の幸運',
    }),
    LuckTicket('r15', Rarity.rare, {
      'ko': '무한리필집에서 확실하게 본전 뽑는 행운',
      'en': 'Luck of beating the buffet at its own game',
      'ja': '食べ放題で確実に元を取る幸運',
    }),
    LuckTicket('r16', Rarity.rare, {
      'ko': '오늘의 첫 손님 할인을 받는 행운',
      'en': 'Luck of getting the first-customer-of-the-day discount',
      'ja': '本日最初のお客様割引を引く幸運',
    }),
    LuckTicket('r17', Rarity.rare, {
      'ko': '길에서 반가운 옛 친구를 우연히 만나는 행운',
      'en': 'Luck of bumping into an old friend you actually like',
      'ja': '道で懐かしい友達に偶然会える幸運',
    }),
    LuckTicket('r18', Rarity.rare, {
      'ko': '사장님이 조용히 서비스를 주시는 행운',
      'en': 'Luck of the owner sliding you something on the house',
      'ja': '大将がそっとサービスをくれる幸運',
    }),
    LuckTicket('r19', Rarity.rare, {
      'ko': '심야에 택시가 잡자마자 오는 행운',
      'en': 'Luck of a cab appearing instantly at 2am',
      'ja': '深夜にタクシーが即つかまる幸運',
    }),
    LuckTicket('r20', Rarity.rare, {
      'ko': '면접관이 내 이야기에 진심으로 웃어주는 행운',
      'en': 'Luck of the interviewer genuinely laughing at your story',
      'ja': '面接官が自分の話にガチ笑いしてくれる幸運',
    }),

    // ────────────────────────────────────────────────────────────
    //  영웅 (12종) — 자랑하고 싶어지는 행운
    // ────────────────────────────────────────────────────────────
    LuckTicket('e01', Rarity.epic, {
      'ko': '경품 이벤트 당첨 문자를 받는 행운 (스팸 아님)',
      'en': 'Luck of a "You won!" text that is not a scam',
      'ja': '懸賞当選の連絡が来る幸運（スパムじゃない）',
    }),
    LuckTicket('e02', Rarity.epic, {
      'ko': '발표가 한 번에 통과되는 행운',
      'en': 'Luck of the presentation passing on the first take',
      'ja': 'プレゼンが一発で通る幸運',
    }),
    LuckTicket('e03', Rarity.epic, {
      'ko': '그 사람에게서 먼저 연락이 오는 행운',
      'en': 'Luck of that person texting you first',
      'ja': 'あの人から先に連絡が来る幸運',
    }),
    LuckTicket('e04', Rarity.epic, {
      'ko': '월급날 전에 예상 못 한 돈이 들어오는 행운',
      'en': 'Luck of surprise money landing before payday',
      'ja': '給料日前に臨時収入が入る幸運',
    }),
    LuckTicket('e05', Rarity.epic, {
      'ko': '여행 기간 내내 날씨가 맑은 행운',
      'en': 'Luck of perfect weather for the entire trip',
      'ja': '旅行中ずっと晴れの幸運',
    }),
    LuckTicket('e06', Rarity.epic, {
      'ko': '주문한 옷이 화보처럼 어울리는 행운',
      'en': 'Luck of the online order fitting like the model pic',
      'ja': 'ネットで買った服がモデル並みに似合う幸運',
    }),
    LuckTicket('e07', Rarity.epic, {
      'ko': '게임에서 천장 찍기 전에 픽업이 뜨는 행운',
      'en': 'Luck of pulling the banner unit way before pity',
      'ja': '天井前にピックアップを引き当てる幸運',
    }),
    LuckTicket('e08', Rarity.epic, {
      'ko': '건강검진 결과가 전부 정상인 행운',
      'en': 'Luck of every checkup result coming back normal',
      'ja': '健康診断がオール正常の幸運',
    }),
    LuckTicket('e09', Rarity.epic, {
      'ko': '잃어버린 물건이 그 자리에 그대로 있는 행운',
      'en': 'Luck of your lost item sitting exactly where you left it',
      'ja': '落とし物がそのままの場所で見つかる幸運',
    }),
    LuckTicket('e10', Rarity.epic, {
      'ko': '최애가 내 댓글에 하트를 눌러주는 행운',
      'en': 'Luck of your fave actually liking your comment',
      'ja': '推しが自分のコメントにいいねする幸運',
    }),
    LuckTicket('e11', Rarity.epic, {
      'ko': '막차 문이 닫히기 직전에 올라타는 행운',
      'en': 'Luck of sliding into the last train as the doors close',
      'ja': '終電にドア閉まる直前で滑り込む幸運',
    }),
    LuckTicket('e12', Rarity.epic, {
      'ko': '살까 말까 했던 주식이 오르는 행운 (샀을 때 한정)',
      'en': 'Luck of that stock going up (only counts if you bought it)',
      'ja': '迷ってた株が上がる幸運（買った場合のみ有効）',
    }),

    // ────────────────────────────────────────────────────────────
    //  전설 (6종) — 인생의 흐름이 바뀌는 행운
    // ────────────────────────────────────────────────────────────
    LuckTicket('l01', Rarity.legendary, {
      'ko': '평생 자랑할 썰이 생기는 행운',
      'en': 'Luck of gaining a story you will tell forever',
      'ja': '一生語れる伝説エピソードが生まれる幸運',
    }),
    LuckTicket('l02', Rarity.legendary, {
      'ko': '인생의 은인을 만나는 행운',
      'en': 'Luck of meeting the person who changes everything',
      'ja': '人生の恩人に出会う幸運',
    }),
    LuckTicket('l03', Rarity.legendary, {
      'ko': '취업이든 이직이든 술술 풀리는 행운',
      'en': 'Luck of the job hunt just... working out',
      'ja': '就活も転職もトントン拍子に進む幸運',
    }),
    LuckTicket('l04', Rarity.legendary, {
      'ko': '소울메이트급 친구가 생기는 행운',
      'en': 'Luck of finding a soulmate-tier friend',
      'ja': 'ソウルメイト級の友達ができる幸運',
    }),
    LuckTicket('l05', Rarity.legendary, {
      'ko': '하는 일마다 타이밍이 맞아떨어지는 행운',
      'en': 'Luck of every timing lining up in your favor',
      'ja': '何をやってもタイミングがハマる幸運',
    }),
    LuckTicket('l06', Rarity.legendary, {
      'ko': '오래 바라던 소원 하나가 이루어지는 행운',
      'en': 'Luck of one long-held wish finally coming true',
      'ja': '長年の願いがひとつ叶う幸運',
    }),

    // ────────────────────────────────────────────────────────────
    //  신화 (2종) — 존재 자체가 전설인 행운
    // ────────────────────────────────────────────────────────────
    LuckTicket('m01', Rarity.mythic, {
      'ko': '오늘 하는 모든 선택이 정답인 행운',
      'en': 'Luck of every single choice today being the right one',
      'ja': '今日の選択が全部正解になる幸運',
    }),
    LuckTicket('m02', Rarity.mythic, {
      'ko': '행운이 행운을 부르는 무한 행운',
      'en': 'Luck of luck attracting more luck, infinitely',
      'ja': '幸運が幸運を呼ぶ無限ループの幸運',
    }),
  ];
}
