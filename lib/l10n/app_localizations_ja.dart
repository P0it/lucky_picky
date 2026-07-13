// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get tabHome => 'ホーム';

  @override
  String get tabGacha => 'ガチャ';

  @override
  String get tabFortune => '運勢';

  @override
  String get tabDex => '幸運の財布';

  @override
  String get tabArchive => 'わたしの記録';

  @override
  String get homeStatusEmpty => '新しい四つ葉のクローバーを始めましょう。\n4つの善い行いで葉が満ちます。';

  @override
  String get homeStatusComplete => '四つ葉のクローバーが完成しました！🍀';

  @override
  String homeStatusProgress(int leaves, int remaining) {
    return '葉が$leaves枚集まりました。\nあと$remaining回の善い行いでクローバーが完成します！';
  }

  @override
  String get homeRecordButton => '今日の善い行いを記録する';

  @override
  String get recordTitle => 'どんな善い行いをしましたか？';

  @override
  String get recordSubtitle => '小さな行いも、クローバーの葉になります。';

  @override
  String get recordHint => '例：エレベーターのドアを押さえてあげました。';

  @override
  String get recordSubmit => '記録して葉を満たす';

  @override
  String get toastCloverComplete => '四つ葉のクローバーが完成しました 🍀';

  @override
  String get toastLeafFilled => '葉を満たしました';

  @override
  String get archiveTitle => 'わたしの善行記録';

  @override
  String get archiveStatLeaves => '満たした葉';

  @override
  String get archiveStatClovers => '生まれたクローバー';

  @override
  String get archiveStatPulls => '引いた幸運';

  @override
  String get archiveTimeline => 'タイムライン';

  @override
  String get archiveCalendar => 'カレンダー';

  @override
  String get archiveEmpty => 'まだ記録がありません。';

  @override
  String historyPullDone(String text) {
    return '［幸運ガチャ］$text';
  }

  @override
  String historyLeafDelta(int count) {
    return '🍃 葉 +$count';
  }

  @override
  String historyCloverDelta(int count) {
    return '🍀 クローバー -$count';
  }

  @override
  String get historyFreePull => '🍀 無料ガチャ';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonConfirm => 'OK';

  @override
  String get gachaTitle => '幸運ガチャ';

  @override
  String get gachaOwnedLabel => '保有クローバー';

  @override
  String gachaCloverCount(int count) {
    return '$count個';
  }

  @override
  String get gachaPull => 'クローバーで引く';

  @override
  String get gachaNotEnough => 'クローバーが足りません';

  @override
  String gachaAdClover(int left, int total) {
    return '広告を見てクローバーをもらう（$left/$total）';
  }

  @override
  String get gachaAdCloverNone => '広告クローバーは明日また回復します';

  @override
  String get gachaAdCloverGained => 'クローバー +1！マシンを回してみましょう';

  @override
  String get gachaRatesButton => '提供割合';

  @override
  String get gachaTapCapsule => 'カプセルをタップして開けよう！';

  @override
  String get ratesTitle => '提供割合';

  @override
  String get ratesDisclaimer => '※ 幸運の効能は科学的に証明されていませんが、\n気分が上がるのは確実です。';

  @override
  String get resultNew => 'NEW!';

  @override
  String resultDup(int count) {
    return 'かぶり ×$count';
  }

  @override
  String get resultMaterial => '強化素材 +1';

  @override
  String get resultConfirm => 'いいね';

  @override
  String get resultRerollAd => '広告を見てもう1回';

  @override
  String get dexTitle => '幸運の財布';

  @override
  String get dexSubtitle => '引いた幸運がここに集まります';

  @override
  String get dexEmpty => 'お財布はまだ空っぽ — 最初の幸運を引いてみましょう！';

  @override
  String get dexEnhanceMax => 'MAX';

  @override
  String dexPlus(int plus) {
    return '+$plus';
  }

  @override
  String dexOwnedCount(int count) {
    return '$count枚 所持';
  }

  @override
  String dexRarityCount(int count) {
    return '$count枚';
  }

  @override
  String get forgeEnhanceCta => '強化する';

  @override
  String get forgeReforgeCta => '再構成';

  @override
  String get forgeStepTarget => '強化するカードを選んでください';

  @override
  String get forgeStepMaterial => '素材にするカードを選んでください';

  @override
  String forgeStepReforge(int need) {
    return '溶かすカードを$need枚選んでください';
  }

  @override
  String get forgeNext => '次へ';

  @override
  String get forgeBack => '戻る';

  @override
  String forgeRunEnhance(int have, int need) {
    return '強化する ($have/$need)';
  }

  @override
  String forgeRunReforge(int have, int need) {
    return '再構成する ($have/$need)';
  }

  @override
  String forgeRate(int rate) {
    return '成功確率 $rate%';
  }

  @override
  String get forgeRateHint => '同じカード +15%p ・ 上位等級 +10%p ・ 下位等級 -10%p';

  @override
  String get forgeWarn => '失敗しても素材は消えます';

  @override
  String forgeReforgeHint(int rate) {
    return '素材の中で最も高い等級で出て、$rate%の確率で一段階上がります';
  }

  @override
  String get forgeNoEnhanceable => '強化できるカードがありません';

  @override
  String forgeNotEnoughCards(int need) {
    return 'カードが$need枚以上必要です';
  }

  @override
  String get forgeNoMaterial => '素材にできるカードがありません';

  @override
  String get forgeSuccess => '強化成功！';

  @override
  String forgeSuccessPlus(int plus) {
    return '+$plus';
  }

  @override
  String get forgeFail => '強化失敗…';

  @override
  String get forgeFailHint => '素材は消えましたが、幸運はまだ残っています';

  @override
  String get forgeReforged => '新しい幸運が出ました';

  @override
  String get forgeUpgraded => '等級が上がりました！';

  @override
  String get forgeConfirm => '確認';

  @override
  String get ticketTitle => '幸運チケット';

  @override
  String ticketOwnedCopies(int count) {
    return '所持 ×$count';
  }

  @override
  String ticketLevel(int level) {
    return 'Lv.$level';
  }

  @override
  String ticketBoost(int mult) {
    return '幸運 ×$mult 増幅';
  }

  @override
  String ticketEnhance(int have, int need) {
    return '強化する（$have/$need）';
  }

  @override
  String get ticketEnhanceMax => '最大強化済み';

  @override
  String toastEnhanced(int mult) {
    return '幸運が ×$mult 増幅されました！✨';
  }

  @override
  String ticketFirstPulled(String date) {
    return '$date 獲得';
  }

  @override
  String get ticketTagline => '善い行いで引く幸運';

  @override
  String ticketShareText(String text) {
    return 'こんな幸運を引きました 🍀「$text」\nこの幸運があなたにも届きますように。\n\nLuckyPicky — 善い行いで引く幸運';
  }

  @override
  String get talismanPortrait => '縦型';

  @override
  String get talismanSquare => '正方形';

  @override
  String get talismanSave => 'アルバムに保存';

  @override
  String get talismanShare => 'シェアする';

  @override
  String get toastSavedToAlbum => '写真アルバムに保存しました 🍀';

  @override
  String get talismanSaveFail => '保存するには写真へのアクセス許可が必要です。';

  @override
  String get talismanRetry => 'しばらくしてからもう一度お試しください。';

  @override
  String get errorNeedConnection => 'インターネット接続が必要です。もう一度お試しください。';

  @override
  String get fortuneTitle => '今日のラッキー指数';

  @override
  String get fortuneSubtitle => '運はもらうものじゃなく、掴むもの。';

  @override
  String get fortuneGaugeHint => '好きな瞬間にタップして運を掴もう！';

  @override
  String get fortuneStartCta => '運メーターを回す';

  @override
  String get fortuneCta => '今しかない…!?';

  @override
  String get fortuneAdviceLabel => '今日の善行おすすめ';

  @override
  String get fortuneScoreLabel => '今日のラッキー指数';

  @override
  String fortuneScorePoints(int score) {
    return '$score点';
  }

  @override
  String get fortuneRetryAd => '広告を見てもう1回掴む';

  @override
  String get fortuneTomorrow => 'また明日、新しい運を掴みに来てね 🍀';

  @override
  String fortuneDeedCheer(int count) {
    return 'これまでの善行$count個が応援しています';
  }

  @override
  String get fortuneLuckyColor => 'ラッキーカラー';

  @override
  String get fortuneLuckyNumber => 'ラッキーナンバー';

  @override
  String get fortuneLuckyItem => 'ラッキーアイテム';

  @override
  String fortuneShareText(int score) {
    return '今日のわたしのラッキー指数は$score点 🍀\nきみも掴んでみて。\n\nLuckyPicky — 善い行いで引く幸運';
  }

  @override
  String get languageSheetTitle => '言語';

  @override
  String get languageSystem => 'システム設定に従う';
}
