// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get tabHome => '홈';

  @override
  String get tabGacha => '뽑기';

  @override
  String get tabDex => '행운 도감';

  @override
  String get tabArchive => '나의 기록';

  @override
  String get homeStatusEmpty => '새 네잎클로버를 시작해요.\n4번의 선행이면 잎이 가득 차요.';

  @override
  String get homeStatusComplete => '네잎클로버가 완성됐어요! 🍀';

  @override
  String homeStatusProgress(int leaves, int remaining) {
    return '잎이 $leaves개 모였어요.\n$remaining번 더 선행을 베풀면 클로버가 완성돼요!';
  }

  @override
  String get homeRecordButton => '오늘의 선행 기록하기';

  @override
  String get recordTitle => '어떤 선행을 베푸셨나요?';

  @override
  String get recordSubtitle => '작은 선행도 클로버의 잎이 됩니다.';

  @override
  String get recordHint => '예: 엘리베이터 문을 잡아주었습니다.';

  @override
  String get recordSubmit => '기록 완료하고 잎 채우기';

  @override
  String get toastCloverComplete => '네잎클로버가 완성됐어요 🍀';

  @override
  String get toastLeafFilled => '잎을 채웠어요';

  @override
  String get archiveTitle => '나의 선행 기록';

  @override
  String get archiveStatLeaves => '총 채운 잎';

  @override
  String get archiveStatClovers => '탄생한 클로버';

  @override
  String get archiveStatPulls => '뽑은 행운';

  @override
  String get archiveTimeline => '타임라인';

  @override
  String get archiveCalendar => '캘린더';

  @override
  String get archiveEmpty => '아직 기록이 없어요.';

  @override
  String historyPullDone(String text) {
    return '[행운 뽑기] $text';
  }

  @override
  String historyLeafDelta(int count) {
    return '🍃 잎 +$count';
  }

  @override
  String historyCloverDelta(int count) {
    return '🍀 클로버 -$count';
  }

  @override
  String get historyFreePull => '🍀 무료 뽑기';

  @override
  String get commonCancel => '취소';

  @override
  String get commonConfirm => '확인';

  @override
  String get gachaTitle => '행운 뽑기';

  @override
  String get gachaOwnedLabel => '보유한 클로버';

  @override
  String gachaCloverCount(int count) {
    return '$count개';
  }

  @override
  String get gachaPull => '클로버로 뽑기';

  @override
  String get gachaNotEnough => '클로버가 부족해요';

  @override
  String gachaFreePull(int left, int total) {
    return '광고 보고 무료 뽑기 ($left/$total)';
  }

  @override
  String get gachaFreePullNone => '무료 뽑기는 내일 다시 채워져요';

  @override
  String get gachaRatesButton => '확률 정보';

  @override
  String get gachaTapCapsule => '캡슐을 탭해서 열어보세요!';

  @override
  String get ratesTitle => '획득 확률';

  @override
  String get ratesDisclaimer => '※ 행운의 효능은 과학적으로 증명되지 않았지만,\n기분이 좋아지는 건 확실합니다.';

  @override
  String get resultNew => 'NEW!';

  @override
  String resultDup(int count) {
    return '중복 ×$count';
  }

  @override
  String get resultMaterial => '강화 재료 +1';

  @override
  String get resultConfirm => '좋아요';

  @override
  String get resultRerollAd => '광고 보고 한 번 더';

  @override
  String get dexTitle => '행운 도감';

  @override
  String get dexSubtitle => '뽑은 행운들이 이곳에 모여요';

  @override
  String dexProgress(int owned, int total) {
    return '$owned/$total 수집';
  }

  @override
  String get ticketTitle => '행운권';

  @override
  String ticketOwnedCopies(int count) {
    return '보유 ×$count';
  }

  @override
  String ticketLevel(int level) {
    return 'Lv.$level';
  }

  @override
  String ticketBoost(int mult) {
    return '행운 ×$mult 증폭';
  }

  @override
  String ticketEnhance(int have, int need) {
    return '강화하기 ($have/$need)';
  }

  @override
  String get ticketEnhanceMax => '최대 강화 완료';

  @override
  String toastEnhanced(int mult) {
    return '행운이 ×$mult 증폭됐어요! ✨';
  }

  @override
  String ticketFirstPulled(String date) {
    return '$date 획득';
  }

  @override
  String get ticketTagline => '선행으로 뽑는 행운';

  @override
  String ticketShareText(String text) {
    return '이런 행운을 뽑았어요 🍀 \"$text\"\n당신에게도 이 행운이 닿기를.\n\nLuckyPicky — 선행으로 뽑는 행운';
  }

  @override
  String get talismanPortrait => '세로형';

  @override
  String get talismanSquare => '정사각형';

  @override
  String get talismanSave => '앨범 저장';

  @override
  String get talismanShare => '공유하기';

  @override
  String get toastSavedToAlbum => '사진 앨범에 저장했어요 🍀';

  @override
  String get talismanSaveFail => '저장하려면 사진 접근 권한이 필요해요.';

  @override
  String get talismanRetry => '잠시 후 다시 시도해 주세요.';

  @override
  String get errorNeedConnection => '인터넷 연결이 필요해요. 다시 시도해 주세요.';

  @override
  String get languageSheetTitle => '언어';

  @override
  String get languageSystem => '시스템 설정 따르기';
}
