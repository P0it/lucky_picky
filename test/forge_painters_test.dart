import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luckypicky/widgets/forge_painters.dart';

void main() {
  test('gauge repaints only when its inputs change', () {
    const a = ForgeGaugePainter(t: 0.5, rate: 0.8, color: Colors.green);
    const b = ForgeGaugePainter(t: 0.6, rate: 0.8, color: Colors.green);
    expect(a.shouldRepaint(a), isFalse);
    expect(a.shouldRepaint(b), isTrue);
  });

  testWidgets('painters draw without throwing across the whole timeline',
      (tester) async {
    for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      await tester.pumpWidget(MaterialApp(
        home: Column(children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: ForgeGaugePainter(t: t, rate: 0.6, color: Colors.green),
            ),
          ),
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: ForgeBurstPainter(t: t, color: Colors.green),
            ),
          ),
          SizedBox(
            width: 200,
            height: 120,
            child: CustomPaint(painter: ForgeCrackPainter(t: t)),
          ),
        ]),
      ));
      expect(tester.takeException(), isNull);
    }
  });
}
