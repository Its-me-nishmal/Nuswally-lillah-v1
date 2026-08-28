import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Guards against a real bug class: a *surface* or *border* token used as a
/// text colour.
///
/// `#E2E8F0` served double duty in this codebase — light-mode border and
/// dark-mode off-white text — so a colour-token migration mapped 14 text
/// colours onto `context.cardBorder`, dropping the Arabic surah names to
/// 3.4:1 contrast. This test fails if that ever creeps back.
void main() {
  test('no surface/border token is used as a text colour', () {
    // Every token here describes a *surface* or a *hairline*. None of them is
    // meant to carry text: goldLine/cardBorderStrong measured 3.5:1 on the
    // Quran reader's calligraphy before this list was widened.
    const forbidden = [
      'cardBorder',
      'cardBorderStrong',
      'cardTop',
      'cardBottom',
      'hairline',
      'pageTop',
      'pageBottom',
      'accentLine',
      'accentSoft',
      'goldWash',
      'goldLine',
      'goldLineStrong',
    ];
    final styleStart = RegExp(r'(?:TextStyle|GoogleFonts\.\w+)\(');
    final offenders = <String>[];

    for (final entry in Directory('lib').listSync(recursive: true)) {
      if (entry is! File || !entry.path.endsWith('.dart')) continue;
      final source = entry.readAsStringSync();

      for (final match in styleStart.allMatches(source)) {
        // Walk to the matching close paren of the style constructor.
        var i = match.end - 1;
        var depth = 0;
        while (i < source.length) {
          final c = source[i];
          if (c == '(') {
            depth++;
          } else if (c == ')') {
            depth--;
            if (depth == 0) break;
          } else if (c == "'") {
            i++;
            while (i < source.length && source[i] != "'") {
              if (source[i] == r'\') i++;
              i++;
            }
          }
          i++;
        }
        final block = source.substring(match.start, i.clamp(0, source.length));
        for (final token in forbidden) {
          final pattern = RegExp('color:[^,)]*(?:context|HomeDesign)\\.$token\\b');
          if (pattern.hasMatch(block)) {
            final line = source.substring(0, match.start).split('\n').length;
            offenders.add('${entry.path}:$line uses context.$token as text');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Surface/border tokens are not legible as text.\n${offenders.join('\n')}',
    );
  });
}
