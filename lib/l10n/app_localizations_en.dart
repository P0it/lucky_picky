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
  String get tabDex => 'Lucky Wallet';

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
  String get gachaOwnedLabel => 'Clovers owned';

  @override
  String gachaCloverCount(int count) {
    return '$count';
  }

  @override
  String get gachaPull => 'Pull with a clover';

  @override
  String get gachaNotEnough => 'Not enough clovers';

  @override
  String gachaAdClover(int left, int total) {
    return 'Watch an ad · get a clover ($left/$total)';
  }

  @override
  String get gachaAdCloverNone => 'Ad clovers are back tomorrow';

  @override
  String get gachaAdCloverGained => 'Clover +1! Give the machine a spin';

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
  String get resultConfirm => 'Nice';

  @override
  String get resultRerollAd => 'Watch an ad · pull again';

  @override
  String get dexTitle => 'Lucky Wallet';

  @override
  String get dexSubtitle => 'Every luck you\'ve pulled lives here';

  @override
  String get dexEmpty => 'Your wallet is empty — go pull your first luck!';

  @override
  String get dexEnhanceMax => 'MAX';

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
  String get forgeBack => 'Back';

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
}
