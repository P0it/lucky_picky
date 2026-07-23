import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabGacha.
  ///
  /// In en, this message translates to:
  /// **'Gacha'**
  String get tabGacha;

  /// No description provided for @tabFortune.
  ///
  /// In en, this message translates to:
  /// **'Fortune'**
  String get tabFortune;

  /// No description provided for @tabDex.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get tabDex;

  /// No description provided for @tabArchive.
  ///
  /// In en, this message translates to:
  /// **'My Record'**
  String get tabArchive;

  /// No description provided for @homeStatusEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start a new four-leaf clover.\nFour good deeds fill all its leaves.'**
  String get homeStatusEmpty;

  /// No description provided for @homeStatusComplete.
  ///
  /// In en, this message translates to:
  /// **'Your four-leaf clover is complete! 🍀'**
  String get homeStatusComplete;

  /// No description provided for @homeStatusProgress.
  ///
  /// In en, this message translates to:
  /// **'{leaves} leaves gathered.\n{remaining} more good deeds to complete the clover!'**
  String homeStatusProgress(int leaves, int remaining);

  /// No description provided for @homeRecordButton.
  ///
  /// In en, this message translates to:
  /// **'Record today\'s good deed'**
  String get homeRecordButton;

  /// No description provided for @recordTitle.
  ///
  /// In en, this message translates to:
  /// **'What kind deed did you do?'**
  String get recordTitle;

  /// No description provided for @recordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Even a small deed becomes a clover leaf.'**
  String get recordSubtitle;

  /// No description provided for @recordHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. I held the elevator door for someone.'**
  String get recordHint;

  /// No description provided for @recordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save and fill a leaf'**
  String get recordSubmit;

  /// No description provided for @toastCloverComplete.
  ///
  /// In en, this message translates to:
  /// **'Your four-leaf clover is complete 🍀'**
  String get toastCloverComplete;

  /// No description provided for @toastLeafFilled.
  ///
  /// In en, this message translates to:
  /// **'You filled a leaf'**
  String get toastLeafFilled;

  /// No description provided for @archiveTitle.
  ///
  /// In en, this message translates to:
  /// **'My Good Deeds'**
  String get archiveTitle;

  /// No description provided for @archiveStatLeaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves filled'**
  String get archiveStatLeaves;

  /// No description provided for @archiveStatClovers.
  ///
  /// In en, this message translates to:
  /// **'Clovers born'**
  String get archiveStatClovers;

  /// No description provided for @archiveStatPulls.
  ///
  /// In en, this message translates to:
  /// **'Lucks pulled'**
  String get archiveStatPulls;

  /// No description provided for @archiveTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get archiveTimeline;

  /// No description provided for @archiveCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get archiveCalendar;

  /// No description provided for @archiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records yet.'**
  String get archiveEmpty;

  /// No description provided for @historyPullDone.
  ///
  /// In en, this message translates to:
  /// **'[Luck pulled] {text}'**
  String historyPullDone(String text);

  /// No description provided for @historyLeafDelta.
  ///
  /// In en, this message translates to:
  /// **'🍃 Leaf +{count}'**
  String historyLeafDelta(int count);

  /// No description provided for @historyCoinDelta.
  ///
  /// In en, this message translates to:
  /// **'🪙 Coin -{count}'**
  String historyCoinDelta(int count);

  /// No description provided for @historyCustomMade.
  ///
  /// In en, this message translates to:
  /// **'[Charm made] {text}'**
  String historyCustomMade(String text);

  /// No description provided for @historyCloverDelta.
  ///
  /// In en, this message translates to:
  /// **'🍀 Clover -{count}'**
  String historyCloverDelta(int count);

  /// No description provided for @historyFreePull.
  ///
  /// In en, this message translates to:
  /// **'🍀 Free pull'**
  String get historyFreePull;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonConfirm;

  /// No description provided for @gachaTitle.
  ///
  /// In en, this message translates to:
  /// **'Lucky Gacha'**
  String get gachaTitle;

  /// No description provided for @gachaCoinCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String gachaCoinCount(int count);

  /// No description provided for @gachaPull.
  ///
  /// In en, this message translates to:
  /// **'Pull with a coin'**
  String get gachaPull;

  /// No description provided for @gachaNotEnough.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins'**
  String get gachaNotEnough;

  /// No description provided for @gachaAdCoin.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad · get a coin ({left}/{total})'**
  String gachaAdCoin(int left, int total);

  /// No description provided for @gachaAdCoinNone.
  ///
  /// In en, this message translates to:
  /// **'Coins are back tomorrow'**
  String get gachaAdCoinNone;

  /// No description provided for @gachaRatesButton.
  ///
  /// In en, this message translates to:
  /// **'Drop rates'**
  String get gachaRatesButton;

  /// No description provided for @gachaTapCapsule.
  ///
  /// In en, this message translates to:
  /// **'Tap the capsule to open it!'**
  String get gachaTapCapsule;

  /// No description provided for @ratesTitle.
  ///
  /// In en, this message translates to:
  /// **'Drop rates'**
  String get ratesTitle;

  /// No description provided for @ratesDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'* Luck effects are not scientifically proven,\nbut the good mood definitely is.'**
  String get ratesDisclaimer;

  /// No description provided for @resultNew.
  ///
  /// In en, this message translates to:
  /// **'NEW!'**
  String get resultNew;

  /// No description provided for @resultDup.
  ///
  /// In en, this message translates to:
  /// **'Duplicate ×{count}'**
  String resultDup(int count);

  /// No description provided for @resultMaterial.
  ///
  /// In en, this message translates to:
  /// **'Enhance material +1'**
  String get resultMaterial;

  /// No description provided for @resultConfirm.
  ///
  /// In en, this message translates to:
  /// **'Nice'**
  String get resultConfirm;

  /// No description provided for @resultRerollAd.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad · pull again'**
  String get resultRerollAd;

  /// No description provided for @customSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Lucky charms you made'**
  String get customSectionTitle;

  /// No description provided for @customSectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Write your own luck — clovers from good deeds turn into a card'**
  String get customSectionEmpty;

  /// No description provided for @customCreateCta.
  ///
  /// In en, this message translates to:
  /// **'Make a charm'**
  String get customCreateCta;

  /// No description provided for @customCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Write your own luck'**
  String get customCreateTitle;

  /// No description provided for @customCreateHint.
  ///
  /// In en, this message translates to:
  /// **'Something you\'d like to come true'**
  String get customCreateHint;

  /// No description provided for @customCreateCounter.
  ///
  /// In en, this message translates to:
  /// **'{used}/{max}'**
  String customCreateCounter(int used, int max);

  /// No description provided for @customCreateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Make it ({cost} clover)'**
  String customCreateConfirm(int cost);

  /// No description provided for @customCreateAdNote.
  ///
  /// In en, this message translates to:
  /// **'You\'ll watch a short ad, then your card appears'**
  String get customCreateAdNote;

  /// No description provided for @customCreateNoClovers.
  ///
  /// In en, this message translates to:
  /// **'You need {cost} clover — record a good deed first'**
  String customCreateNoClovers(int cost);

  /// No description provided for @customCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t make it just now — your clover is untouched'**
  String get customCreateFailed;

  /// No description provided for @customCreated.
  ///
  /// In en, this message translates to:
  /// **'Your luck is made'**
  String get customCreated;

  /// No description provided for @customEnhance.
  ///
  /// In en, this message translates to:
  /// **'Enhance ({cost} clovers)'**
  String customEnhance(int cost);

  /// No description provided for @customEnhanceMax.
  ///
  /// In en, this message translates to:
  /// **'Fully enhanced'**
  String get customEnhanceMax;

  /// No description provided for @customEnhanceNoClovers.
  ///
  /// In en, this message translates to:
  /// **'Not enough clovers'**
  String get customEnhanceNoClovers;

  /// No description provided for @customBadge.
  ///
  /// In en, this message translates to:
  /// **'MADE'**
  String get customBadge;

  /// No description provided for @dexTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get dexTitle;

  /// No description provided for @dexSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every luck you\'ve pulled lives here'**
  String get dexSubtitle;

  /// No description provided for @dexEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your collection is empty — go pull your first luck!'**
  String get dexEmpty;

  /// No description provided for @dexPlus.
  ///
  /// In en, this message translates to:
  /// **'+{plus}'**
  String dexPlus(int plus);

  /// No description provided for @dexOwnedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} cards'**
  String dexOwnedCount(int count);

  /// No description provided for @dexRarityCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String dexRarityCount(int count);

  /// No description provided for @forgeEnhanceCta.
  ///
  /// In en, this message translates to:
  /// **'Enhance'**
  String get forgeEnhanceCta;

  /// No description provided for @forgeReforgeCta.
  ///
  /// In en, this message translates to:
  /// **'Reforge'**
  String get forgeReforgeCta;

  /// No description provided for @forgeStepTarget.
  ///
  /// In en, this message translates to:
  /// **'Pick a card to enhance'**
  String get forgeStepTarget;

  /// No description provided for @forgeStepMaterial.
  ///
  /// In en, this message translates to:
  /// **'Pick the cards to burn'**
  String get forgeStepMaterial;

  /// No description provided for @forgeStepReforge.
  ///
  /// In en, this message translates to:
  /// **'Pick {need} cards to melt down'**
  String forgeStepReforge(int need);

  /// No description provided for @forgeNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get forgeNext;

  /// No description provided for @forgeRunEnhance.
  ///
  /// In en, this message translates to:
  /// **'Enhance ({have}/{need})'**
  String forgeRunEnhance(int have, int need);

  /// No description provided for @forgeRunReforge.
  ///
  /// In en, this message translates to:
  /// **'Reforge ({have}/{need})'**
  String forgeRunReforge(int have, int need);

  /// No description provided for @forgeRate.
  ///
  /// In en, this message translates to:
  /// **'{rate}% success'**
  String forgeRate(int rate);

  /// No description provided for @forgeRateHint.
  ///
  /// In en, this message translates to:
  /// **'Same card +15%p · higher tier +10%p · lower tier -10%p'**
  String get forgeRateHint;

  /// No description provided for @forgeWarn.
  ///
  /// In en, this message translates to:
  /// **'Materials burn even if it fails'**
  String get forgeWarn;

  /// No description provided for @forgeReforgeHint.
  ///
  /// In en, this message translates to:
  /// **'You get the highest tier among the materials, with a {rate}% chance to tier up'**
  String forgeReforgeHint(int rate);

  /// No description provided for @forgeNoEnhanceable.
  ///
  /// In en, this message translates to:
  /// **'No card can be enhanced yet'**
  String get forgeNoEnhanceable;

  /// No description provided for @forgeNotEnoughCards.
  ///
  /// In en, this message translates to:
  /// **'You need at least {need} cards'**
  String forgeNotEnoughCards(int need);

  /// No description provided for @forgeNoMaterial.
  ///
  /// In en, this message translates to:
  /// **'No other card to use as material'**
  String get forgeNoMaterial;

  /// No description provided for @forgeRejected.
  ///
  /// In en, this message translates to:
  /// **'That card can\'t go in right now — refreshing your collection 🍀'**
  String get forgeRejected;

  /// No description provided for @forgeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Enhanced!'**
  String get forgeSuccess;

  /// No description provided for @forgeSuccessPlus.
  ///
  /// In en, this message translates to:
  /// **'+{plus}'**
  String forgeSuccessPlus(int plus);

  /// No description provided for @forgeFail.
  ///
  /// In en, this message translates to:
  /// **'It didn\'t take…'**
  String get forgeFail;

  /// No description provided for @forgeFailHint.
  ///
  /// In en, this message translates to:
  /// **'The materials are gone, but your luck isn\'t'**
  String get forgeFailHint;

  /// No description provided for @forgeReforged.
  ///
  /// In en, this message translates to:
  /// **'A new luck came out'**
  String get forgeReforged;

  /// No description provided for @forgeUpgraded.
  ///
  /// In en, this message translates to:
  /// **'Tier up!'**
  String get forgeUpgraded;

  /// No description provided for @forgeConfirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get forgeConfirm;

  /// No description provided for @forgeCardBase.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get forgeCardBase;

  /// No description provided for @ticketTitle.
  ///
  /// In en, this message translates to:
  /// **'Luck Ticket'**
  String get ticketTitle;

  /// No description provided for @ticketOwnedCopies.
  ///
  /// In en, this message translates to:
  /// **'Owned ×{count}'**
  String ticketOwnedCopies(int count);

  /// No description provided for @ticketLevel.
  ///
  /// In en, this message translates to:
  /// **'Lv.{level}'**
  String ticketLevel(int level);

  /// No description provided for @ticketBoost.
  ///
  /// In en, this message translates to:
  /// **'Luck ×{mult} amplified'**
  String ticketBoost(int mult);

  /// No description provided for @ticketEnhance.
  ///
  /// In en, this message translates to:
  /// **'Enhance ({have}/{need})'**
  String ticketEnhance(int have, int need);

  /// No description provided for @ticketEnhanceMax.
  ///
  /// In en, this message translates to:
  /// **'Fully enhanced'**
  String get ticketEnhanceMax;

  /// No description provided for @toastEnhanced.
  ///
  /// In en, this message translates to:
  /// **'Luck ×{mult} amplified! ✨'**
  String toastEnhanced(int mult);

  /// No description provided for @ticketFirstPulled.
  ///
  /// In en, this message translates to:
  /// **'Pulled on {date}'**
  String ticketFirstPulled(String date);

  /// No description provided for @ticketTagline.
  ///
  /// In en, this message translates to:
  /// **'luck you earn by doing good'**
  String get ticketTagline;

  /// No description provided for @ticketShareText.
  ///
  /// In en, this message translates to:
  /// **'Look what I pulled 🍀 \"{text}\"\nMay this luck reach you too.\n\nLuckyPicky — luck you earn by doing good'**
  String ticketShareText(String text);

  /// No description provided for @talismanPortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get talismanPortrait;

  /// No description provided for @talismanSquare.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get talismanSquare;

  /// No description provided for @talismanSave.
  ///
  /// In en, this message translates to:
  /// **'Save to album'**
  String get talismanSave;

  /// No description provided for @talismanShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get talismanShare;

  /// No description provided for @toastSavedToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Saved to your photo album 🍀'**
  String get toastSavedToAlbum;

  /// No description provided for @talismanSaveFail.
  ///
  /// In en, this message translates to:
  /// **'Photo access permission is needed to save.'**
  String get talismanSaveFail;

  /// No description provided for @talismanRetry.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a moment.'**
  String get talismanRetry;

  /// No description provided for @errorNeedConnection.
  ///
  /// In en, this message translates to:
  /// **'Internet connection is needed. Please try again.'**
  String get errorNeedConnection;

  /// No description provided for @fortuneTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Luck Meter'**
  String get fortuneTitle;

  /// No description provided for @fortuneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Luck isn\'t given — you catch it.'**
  String get fortuneSubtitle;

  /// No description provided for @fortuneGaugeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap at the right moment to catch your luck!'**
  String get fortuneGaugeHint;

  /// No description provided for @fortuneStartCta.
  ///
  /// In en, this message translates to:
  /// **'Start the luck meter'**
  String get fortuneStartCta;

  /// No description provided for @fortuneCta.
  ///
  /// In en, this message translates to:
  /// **'Now...!?'**
  String get fortuneCta;

  /// No description provided for @fortuneAdviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s good deed'**
  String get fortuneAdviceLabel;

  /// No description provided for @fortuneScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s luck meter'**
  String get fortuneScoreLabel;

  /// No description provided for @fortuneScorePoints.
  ///
  /// In en, this message translates to:
  /// **'{score} pts'**
  String fortuneScorePoints(int score);

  /// No description provided for @fortuneRetryAd.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad · one more try'**
  String get fortuneRetryAd;

  /// No description provided for @fortuneTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow to catch a new one 🍀'**
  String get fortuneTomorrow;

  /// No description provided for @fortuneDeedCheer.
  ///
  /// In en, this message translates to:
  /// **'Your {count} good deeds are cheering for you'**
  String fortuneDeedCheer(int count);

  /// No description provided for @fortuneLuckyColor.
  ///
  /// In en, this message translates to:
  /// **'Lucky color'**
  String get fortuneLuckyColor;

  /// No description provided for @fortuneLuckyNumber.
  ///
  /// In en, this message translates to:
  /// **'Lucky number'**
  String get fortuneLuckyNumber;

  /// No description provided for @fortuneLuckyItem.
  ///
  /// In en, this message translates to:
  /// **'Lucky item'**
  String get fortuneLuckyItem;

  /// No description provided for @fortuneShareText.
  ///
  /// In en, this message translates to:
  /// **'My luck meter today: {score}/100 🍀\nCatch yours too.\n\nLuckyPicky — luck you earn by doing good'**
  String fortuneShareText(int score);

  /// No description provided for @languageSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSheetTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system settings'**
  String get languageSystem;

  /// No description provided for @loadingErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect'**
  String get loadingErrorTitle;

  /// No description provided for @loadingErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Please check your network connection'**
  String get loadingErrorBody;

  /// No description provided for @loadingRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get loadingRetry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
