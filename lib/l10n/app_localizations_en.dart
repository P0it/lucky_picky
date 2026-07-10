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
  String get tabDex => 'Luck Dex';

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
  String gachaFreePull(int left, int total) {
    return 'Watch an ad · free pull ($left/$total)';
  }

  @override
  String get gachaFreePullNone => 'Free pulls are back tomorrow';

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
  String get dexTitle => 'Luck Dex';

  @override
  String get dexSubtitle => 'Every luck you\'ve pulled lives here';

  @override
  String dexProgress(int owned, int total) {
    return '$owned/$total collected';
  }

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
  String get languageSheetTitle => 'Language';

  @override
  String get languageSystem => 'Follow system settings';
}
