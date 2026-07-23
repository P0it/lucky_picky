@Tags(['brand-assets'])
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luckypicky/theme/app_theme.dart';
import 'package:luckypicky/widgets/clover_paths.dart';
import 'package:luckypicky/widgets/logo_wordmark.dart';

/// 브랜드 PNG 생성기.
///
/// 클로버는 `clover_paths.dart` 의 Dart 경로로만 존재해서 스플래시·아이콘에 쓸
/// 이미지 파일이 없다. 앱 안의 마크와 모양이 어긋나지 않도록, 별도 그림을 그리는
/// 대신 같은 경로를 그대로 렌더링해 PNG 로 굽는다.
///
/// 실행: flutter test test/export_brand_assets_test.dart
/// (일반 테스트가 아니라 애셋 생성 스크립트다. `--exclude-tags brand-assets` 로 제외 가능.)
void main() {
  const outDir = 'assets/brand';

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Directory(outDir).createSync(recursive: true);
    // flutter test 는 pubspec 폰트를 자동으로 올리지 않아 글리프가 네모로 그려진다.
    final loader = FontLoader(LogoWordmark.family)
      ..addFont(Future.value(
        File('assets/fonts/Fredoka.ttf').readAsBytesSync().buffer.asByteData(),
      ));
    await loader.load();
  });

  test('스플래시용 클로버 + 워드마크 (투명 배경)', () async {
    await _write('$outDir/clover_splash.png', 1024,
        cloverRatio: 0.52, wordmark: true);
  });

  test('Android 12+ 스플래시 아이콘 (안전 영역 준수)', () async {
    // 960px 캔버스에서 콘텐츠는 안쪽 640px 안에 들어와야 잘리지 않는다.
    await _write('$outDir/clover_android12.png', 960, cloverRatio: 0.58);
  });

  test('앱 아이콘 (흰 배경)', () async {
    await _write('$outDir/app_icon.png', 1024,
        cloverRatio: 0.62, background: AppColors.white);
  });

  test('적응형 아이콘 전경 (투명 배경, 안전 영역 준수)', () async {
    // 적응형 아이콘은 바깥 33% 가 마스크로 잘려나간다.
    await _write('$outDir/app_icon_foreground.png', 1024, cloverRatio: 0.46);
  });
}

/// 정사각 캔버스 가운데에 클로버를 [cloverRatio] 비율로 그려 PNG 로 저장한다.
/// [wordmark] 가 true 면 클로버 아래에 "Lucky Picky" 워드마크를 함께 그린다.
Future<void> _write(
  String path,
  int size, {
  required double cloverRatio,
  Color? background,
  bool wordmark = false,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final canvasSize = size.toDouble();

  if (background != null) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize, canvasSize),
      Paint()..color = background,
    );
  }

  final cloverExtent = canvasSize * cloverRatio;
  final wordmarkSize = canvasSize * 0.145;
  final gap = wordmark ? canvasSize * 0.07 : 0.0;
  final wordmarkHeight = wordmark ? wordmarkSize * 1.3 : 0.0;

  // 클로버 + (워드마크) 를 하나의 덩어리로 보고 세로 가운데 정렬한다.
  final blockTop = (canvasSize - (cloverExtent + gap + wordmarkHeight)) / 2;

  // viewBox(120) 안에서 클로버가 차지하는 실제 영역에 맞춰 배치한다.
  // viewBox 를 그대로 쓰면 자체 여백 때문에 마크가 지나치게 작아진다.
  final bounds = _cloverBounds();
  final scale = cloverExtent / math.max(bounds.width, bounds.height);
  canvas.save();
  canvas.translate(canvasSize / 2, blockTop + cloverExtent / 2);
  canvas.scale(scale);
  canvas.translate(-bounds.center.dx, -bounds.center.dy);
  _paintClover(canvas);
  canvas.restore();

  if (wordmark) {
    _paintWordmark(
      canvas,
      fontSize: wordmarkSize,
      center: Offset(
        canvasSize / 2,
        blockTop + cloverExtent + gap + wordmarkHeight / 2,
      ),
    );
  }

  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();

  expect(File(path).lengthSync(), greaterThan(0));
}

/// `LogoWordmark` 와 동일한 사양(단색 + 페이크 볼드)으로 워드마크를 그린다.
void _paintWordmark(Canvas canvas,
    {required double fontSize, required Offset center}) {
  final base = LogoWordmark.style(fontSize);

  // 자간은 마지막 글자 뒤에도 붙어 글자 덩어리가 왼쪽으로 치우친다. 절반만큼 되민다.
  final trackingShift = Offset(fontSize * LogoWordmark.trackingRatio / 2, 0);

  void draw(TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: LogoWordmark.text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      center - Offset(tp.width / 2, tp.height / 2) + trackingShift,
    );
  }

  draw(base.copyWith(
    foreground: Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = fontSize * LogoWordmark.boldenRatio
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.accent,
  ));
  draw(base.copyWith(color: AppColors.accent));
}

/// 잎 4장을 viewBox 좌표계로 변환해 하나의 path 로 합친다.
Path _leavesPath() {
  final heart = heartPath();
  final combined = Path();
  const sc = 1.8;
  for (final a in kLeafAngles) {
    final m = Matrix4.identity()
      ..translateByDouble(60.0, 58.0, 0, 1)
      ..rotateZ(a * math.pi / 180)
      ..translateByDouble(0.0, 0.5, 0, 1)
      ..scaleByDouble(sc * 0.92, sc * 1.12, 1, 1)
      ..translateByDouble(-12.0, -21.35, 0, 1);
    combined.addPath(heart, Offset.zero, matrix4: m.storage);
  }
  return combined;
}

/// 잎 + 줄기(선 굵기 포함)를 감싸는 실제 경계.
Rect _cloverBounds() {
  const halfStroke = 3.6 / 2;
  return _leavesPath()
      .getBounds()
      .expandToInclude(stemPath().getBounds().inflate(halfStroke));
}

/// `CloverMark` 의 _MarkPainter 와 동일한 지오메트리 (줄기 포함, viewBox 좌표계).
void _paintClover(Canvas canvas) {
  final paint = Paint()
    ..color = AppColors.accent
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  canvas.drawPath(
    stemPath(),
    Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true,
  );

  final heart = heartPath();
  const sc = 1.8;
  for (final a in kLeafAngles) {
    canvas.save();
    canvas.translate(60, 58);
    canvas.rotate(a * math.pi / 180);
    canvas.translate(0, 0.5);
    canvas.scale(sc * 0.92, sc * 1.12);
    canvas.translate(-12, -21.35);
    canvas.drawPath(heart, paint);
    canvas.restore();
  }
}
