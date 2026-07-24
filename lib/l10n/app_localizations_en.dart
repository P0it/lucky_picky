// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabHome => 'Home';

  @override
  String get tabGacha => 'Gacha';

  @override
  String get tabFortune => 'Fortune';

  @override
  String get tabDex => 'Collection';

  @override
  String get tabArchive => 'My Record';

  @override
  String get homeStatusEmpty =>
      'Start a new four-leaf clover.\nFour good deeds fill all its leaves.';

  @override
  String get homeStatusComplete => 'Your four-leaf clover is complete! 🍀';

  @override
  String homeStatusProgress(int leaves, int remaining) {
    return '$leaves leaves gathered.\n$remaining more good deeds to complete the clover!';
  }

  @override
  String get homeRecordButton => 'Record today\'s good deed';

  @override
  String get recordTitle => 'What kind deed did you do?';

  @override
  String get recordSubtitle => 'Even a small deed becomes a clover leaf.';

  @override
  String get recordHint => 'e.g. I held the elevator door for someone.';

  @override
  String get recordSubmit => 'Save and fill a leaf';

  @override
  String get toastCloverComplete => 'Your four-leaf clover is complete 🍀';

  @override
  String get toastLeafFilled => 'You filled a leaf';

  @override
  String get archiveTitle => 'My Good Deeds';

  @override
  String get archiveStatLeaves => 'Leaves filled';

  @override
  String get archiveStatClovers => 'Clovers born';

  @override
  String get archiveStatPulls => 'Lucks pulled';

  @override
  String get archiveTimeline => 'Timeline';

  @override
  String get archiveCalendar => 'Calendar';

  @override
  String get archiveEmpty => 'No records yet.';

  @override
  String historyPullDone(String text) {
    return '[Luck pulled] $text';
  }

  @override
  String historyLeafDelta(int count) {
    return '🍃 Leaf +$count';
  }

  @override
  String historyCoinDelta(int count) {
    return '🪙 Coin -$count';
  }

  @override
  String historyCustomMade(String text) {
    return '[Charm made] $text';
  }

  @override
  String historyCloverDelta(int count) {
    return '🍀 Clover -$count';
  }

  @override
  String get historyFreePull => '🍀 Free pull';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'OK';

  @override
  String get gachaTitle => 'Lucky Gacha';

  @override
  String gachaCoinCount(int count) {
    return '$count';
  }

  @override
  String get gachaPull => 'Pull with a coin';

  @override
  String get gachaNotEnough => 'Not enough coins';

  @override
  String gachaAdCoin(int left, int total) {
    return 'Watch an ad · get a coin ($left/$total)';
  }

  @override
  String get gachaAdCoinNone => 'Coins are back tomorrow';

  @override
  String get gachaRatesButton => 'Drop rates';

  @override
  String get gachaTapCapsule => 'Tap the capsule to open it!';

  @override
  String get ratesTitle => 'Drop rates';

  @override
  String get ratesDisclaimer =>
      '* Luck effects are not scientifically proven,\nbut the good mood definitely is.';

  @override
  String get resultNew => 'NEW!';

  @override
  String resultDup(int count) {
    return 'Duplicate ×$count';
  }

  @override
  String get resultMaterial => 'Enhance material +1';

  @override
  String get resultConfirm => 'Claim lucky card';

  @override
  String get resultRerollAd => 'Watch an ad · pull again';

  @override
  String get customSectionTitle => 'Lucky charms you made';

  @override
  String get customSectionEmpty =>
      'Write your own luck — clovers from good deeds turn into a card';

  @override
  String get customCreateCta => 'Make a charm';

  @override
  String get customCreateTitle => 'Write your own luck';

  @override
  String get customCreateHint => 'Something you\'d like to come true';

  @override
  String customCreateCounter(int used, int max) {
    return '$used/$max';
  }

  @override
  String customCreateConfirm(int cost) {
    return 'Make it ($cost clover)';
  }

  @override
  String get customCreateAdNote =>
      'You\'ll watch a short ad, then your card appears';

  @override
  String customCreateNoClovers(int cost) {
    return 'You need $cost clover — record a good deed first';
  }

  @override
  String get customCreateFailed =>
      'Couldn\'t make it just now — your clover is untouched';

  @override
  String get customCreated => 'Your luck is made';

  @override
  String customEnhance(int cost) {
    return 'Enhance ($cost clovers)';
  }

  @override
  String get customEnhanceMax => 'Fully enhanced';

  @override
  String get customEnhanceNoClovers => 'Not enough clovers';

  @override
  String get customBadge => 'MADE';

  @override
  String get dexTitle => 'Collection';

  @override
  String get dexSubtitle => 'Every luck you\'ve pulled lives here';

  @override
  String get dexEmpty => 'Your collection is empty — go pull your first luck!';

  @override
  String dexPlus(int plus) {
    return '+$plus';
  }

  @override
  String dexOwnedCount(int count) {
    return '$count cards';
  }

  @override
  String dexRarityCount(int count) {
    return '$count';
  }

  @override
  String get forgeEnhanceCta => 'Enhance';

  @override
  String get forgeReforgeCta => 'Reforge';

  @override
  String get forgeStepTarget => 'Pick a card to enhance';

  @override
  String get forgeStepMaterial => 'Pick the cards to burn';

  @override
  String forgeStepReforge(int need) {
    return 'Pick $need cards to melt down';
  }

  @override
  String get forgeNext => 'Next';

  @override
  String forgeRunEnhance(int have, int need) {
    return 'Enhance ($have/$need)';
  }

  @override
  String forgeRunReforge(int have, int need) {
    return 'Reforge ($have/$need)';
  }

  @override
  String forgeRate(int rate) {
    return '$rate% success';
  }

  @override
  String get forgeRateHint =>
      'Same card +15%p · higher tier +10%p · lower tier -10%p';

  @override
  String get forgeWarn => 'Materials burn even if it fails';

  @override
  String forgeReforgeHint(int rate) {
    return 'You get the highest tier among the materials, with a $rate% chance to tier up';
  }

  @override
  String get forgeNoEnhanceable => 'No card can be enhanced yet';

  @override
  String forgeNotEnoughCards(int need) {
    return 'You need at least $need cards';
  }

  @override
  String get forgeNoMaterial => 'No other card to use as material';

  @override
  String get forgeRejected =>
      'That card can\'t go in right now — refreshing your collection 🍀';

  @override
  String get forgeSuccess => 'Enhanced!';

  @override
  String forgeSuccessPlus(int plus) {
    return '+$plus';
  }

  @override
  String get forgeFail => 'It didn\'t take…';

  @override
  String get forgeFailHint => 'The materials are gone, but your luck isn\'t';

  @override
  String get forgeReforged => 'A new luck came out';

  @override
  String get forgeUpgraded => 'Tier up!';

  @override
  String get forgeConfirm => 'OK';

  @override
  String get forgeCardBase => 'Base';

  @override
  String get ticketTitle => 'Luck Ticket';

  @override
  String ticketOwnedCopies(int count) {
    return 'Owned ×$count';
  }

  @override
  String ticketLevel(int level) {
    return 'Lv.$level';
  }

  @override
  String ticketBoost(int mult) {
    return 'Luck ×$mult amplified';
  }

  @override
  String ticketEnhance(int have, int need) {
    return 'Enhance ($have/$need)';
  }

  @override
  String get ticketEnhanceMax => 'Fully enhanced';

  @override
  String toastEnhanced(int mult) {
    return 'Luck ×$mult amplified! ✨';
  }

  @override
  String ticketFirstPulled(String date) {
    return 'Pulled on $date';
  }

  @override
  String get ticketTagline => 'luck you earn by doing good';

  @override
  String ticketShareText(String text) {
    return 'Look what I pulled 🍀 \"$text\"\nMay this luck reach you too.\n\nLuckyPicky — luck you earn by doing good';
  }

  @override
  String get talismanPortrait => 'Portrait';

  @override
  String get talismanSquare => 'Square';

  @override
  String get talismanSave => 'Save to album';

  @override
  String get talismanShare => 'Share';

  @override
  String get toastSavedToAlbum => 'Saved to your photo album 🍀';

  @override
  String get talismanSaveFail => 'Photo access permission is needed to save.';

  @override
  String get talismanRetry => 'Please try again in a moment.';

  @override
  String get errorNeedConnection =>
      'Internet connection is needed. Please try again.';

  @override
  String get fortuneTitle => 'Today\'s Luck Meter';

  @override
  String get fortuneSubtitle => 'Luck isn\'t given — you catch it.';

  @override
  String get fortuneGaugeHint => 'Tap at the right moment to catch your luck!';

  @override
  String get fortuneStartCta => 'Start the luck meter';

  @override
  String get fortuneCta => 'Now...!?';

  @override
  String get fortuneAdviceLabel => 'Today\'s good deed';

  @override
  String get fortuneScoreLabel => 'Today\'s luck meter';

  @override
  String fortuneScorePoints(int score) {
    return '$score pts';
  }

  @override
  String get fortuneRetryAd => 'Watch an ad · one more try';

  @override
  String get fortuneTomorrow => 'Come back tomorrow to catch a new one 🍀';

  @override
  String fortuneDeedCheer(int count) {
    return 'Your $count good deeds are cheering for you';
  }

  @override
  String get fortuneLuckyColor => 'Lucky color';

  @override
  String get fortuneLuckyNumber => 'Lucky number';

  @override
  String get fortuneLuckyItem => 'Lucky item';

  @override
  String fortuneShareText(int score) {
    return 'My luck meter today: $score/100 🍀\nCatch yours too.\n\nLuckyPicky — luck you earn by doing good';
  }

  @override
  String get languageSheetTitle => 'Language';

  @override
  String get languageSystem => 'Follow system settings';

  @override
  String get recoveryTitle => 'Keep your luck safe';

  @override
  String get recoverySubtitle =>
      'Switch phones or delete the app — this code brings your luck back.';

  @override
  String get recoveryMyCodeLabel => 'My recovery code';

  @override
  String get recoveryShowCode => 'Show my recovery code';

  @override
  String get recoveryCodeSaveHint =>
      'Screenshot this code or keep it somewhere safe.';

  @override
  String get recoveryCopy => 'Copy';

  @override
  String get recoveryCopied => 'Recovery code copied';

  @override
  String get recoveryRestoreLabel => 'Restore with a code';

  @override
  String get recoveryRestoreHint => 'e.g. brave tunafish sleepy spaghetti';

  @override
  String get recoveryRestoreCta => 'Restore with this code';

  @override
  String get recoveryRestored => 'Your luck is back 🍀';

  @override
  String get recoveryNotFound => 'Code not found. Please double-check it.';

  @override
  String get loadingErrorTitle => 'Couldn\'t connect';

  @override
  String get loadingErrorBody => 'Please check your network connection';

  @override
  String get loadingRetry => 'Try again';
}
