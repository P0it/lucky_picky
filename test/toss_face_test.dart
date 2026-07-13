import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luckypicky/theme/toss_face.dart';

void main() {
  testWidgets('TossEmoji renders the glyph with the TossFace family',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: TossEmoji(TossFace.clover, size: 20)),
    ));

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, TossFace.clover);
    expect(text.style?.fontFamily, TossFace.family);
    expect(text.style?.fontSize, 20);
  });

  test('emoji constants are the agreed codepoints', () {
    expect(TossFace.recycle, '♻️'); // ♻️ 재조합
    expect(TossFace.star, '⭐'); // ⭐ 강화
    expect(TossFace.clover, '\u{1F340}'); // 🍀
    expect(TossFace.boom, '\u{1F4A5}'); // 💥
    expect(TossFace.crown, '\u{1F451}'); // 👑
  });
}
