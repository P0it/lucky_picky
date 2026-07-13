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
  String get tabFortune => '운세';

  @override
  String get tabDex => '행운 지갑';

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
  String gachaAdClover(int left, int total) {
    return '광고 보고 클로버 받기 ($left/$total)';
  }

  @override
  String get gachaAdCloverNone => '광고 클로버는 내일 다시 채워져요';

  @override
  String get gachaAdCloverGained => '클로버 +1! 머신을 돌려보세요';

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
  String get dexTitle => '행운 지갑';

  @override
  String get dexSubtitle => '뽑은 행운들이 이곳에 모여요';

  @override
  String get dexEmpty => '지갑이 텅 비었어요 — 첫 행운을 뽑으러 가볼까요?';

  @override
  String get dexEnhanceMax => 'MAX';

  @override
  String dexPlus(int plus) {
    return '+$plus';
  }

  @override
  String dexOwnedCount(int count) {
    return '$count장 보유';
  }

  @override
  String dexRarityCount(int count) {
    return '$count장';
  }

  @override
  String get forgeEnhanceCta => '강화하기';

  @override
  String get forgeReforgeCta => '재조합';

  @override
  String get forgeStepTarget => '강화할 카드를 고르세요';

  @override
  String get forgeStepMaterial => '재료로 태울 카드를 고르세요';

  @override
  String forgeStepReforge(int need) {
    return '갈아 넣을 카드 $need장을 고르세요';
  }

  @override
  String get forgeNext => '다음';

  @override
  String get forgeBack => '뒤로';

  @override
  String forgeRunEnhance(int have, int need) {
    return '강화하기 ($have/$need)';
  }

  @override
  String forgeRunReforge(int have, int need) {
    return '재조합하기 ($have/$need)';
  }

  @override
  String forgeRate(int rate) {
    return '성공 확률 $rate%';
  }

  @override
  String get forgeRateHint => '같은 카드 +15%p · 상위 등급 +10%p · 하위 등급 -10%p';

  @override
  String get forgeWarn => '실패해도 재료는 사라져요';

  @override
  String forgeReforgeHint(int rate) {
    return '재료 중 가장 높은 등급으로 나오고, $rate% 확률로 한 등급 올라가요';
  }

  @override
  String get forgeNoEnhanceable => '강화할 수 있는 카드가 없어요';

  @override
  String forgeNotEnoughCards(int need) {
    return '카드가 $need장 이상 있어야 해요';
  }

  @override
  String get forgeNoMaterial => '재료로 쓸 다른 카드가 없어요';

  @override
  String get forgeSuccess => '강화 성공!';

  @override
  String forgeSuccessPlus(int plus) {
    return '+$plus';
  }

  @override
  String get forgeFail => '강화 실패…';

  @override
  String get forgeFailHint => '재료는 사라졌지만, 행운은 아직 남아 있어요';

  @override
  String get forgeReforged => '새 행운이 나왔어요';

  @override
  String get forgeUpgraded => '등급이 올랐어요!';

  @override
  String get forgeConfirm => '확인';

  @override
  String get forgeCardBase => '무강화';

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
  String get fortuneTitle => '오늘의 행운지수';

  @override
  String get fortuneSubtitle => '행운은 받는 게 아니라 잡는 것.';

  @override
  String get fortuneGaugeHint => '원하는 순간에 탭해서 행운을 잡으세요!';

  @override
  String get fortuneStartCta => '행운 게이지 돌리기';

  @override
  String get fortuneCta => '지금이니..!?';

  @override
  String get fortuneAdviceLabel => '오늘의 선행 추천';

  @override
  String get fortuneScoreLabel => '오늘의 행운지수';

  @override
  String fortuneScorePoints(int score) {
    return '$score점';
  }

  @override
  String get fortuneRetryAd => '광고 보고 한 번 더 잡기';

  @override
  String get fortuneTomorrow => '내일 새로운 행운을 잡으러 오세요 🍀';

  @override
  String fortuneDeedCheer(int count) {
    return '지금까지의 선행 $count개가 응원하고 있어요';
  }

  @override
  String get fortuneLuckyColor => '행운의 색';

  @override
  String get fortuneLuckyNumber => '행운의 숫자';

  @override
  String get fortuneLuckyItem => '행운의 아이템';

  @override
  String fortuneShareText(int score) {
    return '오늘 내 행운지수 $score점 🍀\n너도 잡아봐.\n\nLuckyPicky — 선행으로 뽑는 행운';
  }

  @override
  String get languageSheetTitle => '언어';

  @override
  String get languageSystem => '시스템 설정 따르기';
}
