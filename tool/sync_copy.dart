// ════════════════════════════════════════════════════════════════
//  문구 동기화 — dart 파일(원본) → Supabase copy_lines (배달 경로).
//
//  문구의 소스 오브 트루스는 lib/config/daily_quotes.dart 와 fortune_pool.dart 다.
//  로컬에서 편집하고, PR로 리뷰하고, git에 이력이 남는다.
//  이 스크립트는 그 목록을 서버에 그대로 미러링해서, 유저가 앱 업데이트 없이
//  새 문구를 보게 한다. (앱은 서버 문구가 없으면 번들 문구로 폴백 — CopyBook)
//
//  실행:
//    SUPABASE_URL=https://xxx.supabase.co \
//    SUPABASE_SERVICE_ROLE_KEY=... \
//    dart run tool/sync_copy.dart [--dry-run]
//
//  머지 시 .github/workflows/sync-copy.yml 이 자동으로 실행한다.
//  --dry-run 은 서버에 쓰지 않고 반영될 내용만 출력한다.
//
//  주의: 이 스크립트는 Flutter 런타임 없이 도는 순수 dart다.
//  그래서 문구 파일(daily_quotes.dart, fortune_copy.dart)은 dart:ui 에 의존하면
//  안 된다. 행운의 색(Color)이 fortune_pool.dart 에 따로 남아 있는 이유다.
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:luckypicky/config/daily_quotes.dart';
import 'package:luckypicky/config/fortune_copy.dart';

const _langs = ['ko', 'en', 'ja'];

void main(List<String> args) async {
  final dryRun = args.contains('--dry-run');

  final rows = <Map<String, dynamic>>[
    for (final lang in _langs) ...[
      for (final text in DailyQuotes.poolFor(lang))
        {'surface': 'daily_quote', 'lang': lang, 'grade': null, 'text': text},
      for (final text in FortuneCopy.advicePool(lang))
        {'surface': 'fortune_advice', 'lang': lang, 'grade': null, 'text': text},
      for (var grade = 0; grade < 4; grade++)
        for (final text in FortuneCopy.overallPool(lang, grade))
          {
            'surface': 'fortune_overall',
            'lang': lang,
            'grade': grade,
            'text': text,
          },
    ],
  ];

  _report(rows);

  if (dryRun) {
    stdout.writeln('\n--dry-run: 서버에 쓰지 않고 종료합니다.');
    return;
  }

  final url = Platform.environment['SUPABASE_URL'];
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (url == null || url.isEmpty || key == null || key.isEmpty) {
    stderr.writeln(
      '환경변수 SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY 가 필요합니다.\n'
      '(내용만 확인하려면 --dry-run 을 붙이세요.)',
    );
    exit(1);
  }

  // 통째로 교체한다. 문구 목록의 원본은 dart 파일이므로, 서버는 항상 그 스냅샷이어야
  // 한다. 부분 갱신을 하면 dart 에서 지운 문구가 서버에 남아 계속 노출된다.
  //
  // 삭제 → 삽입 사이의 짧은 순간에 앱이 조회하면 빈 목록을 받을 수 있는데,
  // 그때는 앱이 번들 문구로 폴백하므로 사고가 아니다(문구가 잠깐 예전 것으로 보일 뿐).
  await _request(
    'DELETE',
    '$url/rest/v1/copy_lines?id=gt.0',
    key,
    expected: {200, 204},
  );
  await _request(
    'POST',
    '$url/rest/v1/copy_lines',
    key,
    body: rows,
    expected: {200, 201},
  );

  stdout.writeln('\n동기화 완료: ${rows.length}줄을 서버에 반영했습니다.');
}

void _report(List<Map<String, dynamic>> rows) {
  stdout.writeln('반영할 문구 ${rows.length}줄');
  for (final lang in _langs) {
    final of = rows.where((r) => r['lang'] == lang);
    final daily = of.where((r) => r['surface'] == 'daily_quote').length;
    final advice = of.where((r) => r['surface'] == 'fortune_advice').length;
    final overall = of.where((r) => r['surface'] == 'fortune_overall').length;
    stdout.writeln(
      '  $lang — 홈 문구 $daily / 총운 $overall / 선행 조언 $advice',
    );
  }
}

Future<void> _request(
  String method,
  String url,
  String key, {
  Object? body,
  required Set<int> expected,
}) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl(method, Uri.parse(url));
    req.headers
      ..set('apikey', key)
      ..set('Authorization', 'Bearer $key')
      ..set('Content-Type', 'application/json')
      ..set('Prefer', 'return=minimal');
    if (body != null) req.write(jsonEncode(body));

    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    if (!expected.contains(res.statusCode)) {
      stderr.writeln('$method $url 실패 (${res.statusCode}): $text');
      exit(1);
    }
  } finally {
    client.close();
  }
}
