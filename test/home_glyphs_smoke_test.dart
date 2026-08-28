import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuswally_lillah/widgets/home/home_glyphs.dart';

void main() {
  testWidgets('home glyphs paint without error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Container(
          color: const Color(0xFF07100D),
          child: Center(
            child: RepaintBoundary(
              child: SizedBox(
                width: 320,
                height: 300,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const MosqueArchGlyph(
                      width: 128,
                      height: 150,
                      gold: Color(0xFFD9A94E),
                      domeColor: Color(0xFF12362B),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        TasbeehGlyph(size: 64, color: Color(0xFFD9A94E)),
                        NinetyNineGlyph(size: 64, color: Color(0xFFD9A94E)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/home_glyphs.png'),
    );
  });
}
