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
  String get tabDex => '幸運図鑑';

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
  String gachaFreePull(int left, int total) {
    return '広告を見て無料ガチャ（$left/$total）';
  }

  @override
  String get gachaFreePullNone => '無料ガチャは明日また回復します';

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
  String get dexTitle => '幸運図鑑';

  @override
  String get dexSubtitle => '引いた幸運がここに集まります';

  @override
  String dexProgress(int owned, int total) {
    return '$owned/$total コンプ';
  }

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
  String get languageSheetTitle => '言語';

  @override
  String get languageSystem => 'システム設定に従う';
}
