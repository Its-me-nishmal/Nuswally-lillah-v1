import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nuswally_lillah/providers/adhkaar_provider.dart';
import 'package:nuswally_lillah/providers/journal_provider.dart';
import 'package:nuswally_lillah/providers/prayer_provider.dart';
import 'package:nuswally_lillah/providers/quran_provider.dart';
import 'package:nuswally_lillah/providers/theme_provider.dart';
import 'package:nuswally_lillah/screens/notification_settings_screen.dart';
import 'package:nuswally_lillah/screens/settings_screen.dart';

Widget _host(Widget child) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => PrayerProvider()),
    ChangeNotifierProvider(create: (_) => JournalProvider()),
    ChangeNotifierProvider(create: (_) => QuranProvider()),
    ChangeNotifierProvider(create: (_) => AdhkaarProvider()),
  ],
  child: MaterialApp(debugShowCheckedModeBanner: false, home: child),
);

/// Theming verification harness.
///
/// These render real screens so dark/light theming can be eyeballed. They are
/// skipped in normal runs because the providers reach for platform plugins
/// (flutter_local_notifications, just_audio) that do not exist under
/// `flutter test`, which fails the test *after* the golden is written.
///
/// To regenerate and inspect the images:
///   1. set `_manualOnly = false` below
///   2. flutter test on this file, with --update-goldens
///   3. look at test/goldens/*.png (ignore the reported failure)
const bool _manualOnly = true;

void main() {
  setUp(() {
    // Fonts are bundled under assets/google_fonts/, so no network is needed.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  for (final dark in [true, false]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('settings renders in $mode', (tester) async {
      SharedPreferences.setMockInitialValues({'is_app_dark_mode': dark});
      tester.view.physicalSize = const Size(360 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const SettingsScreen()));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      tester.takeException(); // platform channels are unavailable in tests

      await expectLater(
        find.byType(SettingsScreen),
        matchesGoldenFile('goldens/settings_$mode.png'),
      );
    }, skip: _manualOnly);

    testWidgets('notification settings renders in $mode', (tester) async {
      SharedPreferences.setMockInitialValues({'is_app_dark_mode': dark});
      tester.view.physicalSize = const Size(360 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const NotificationSettingsScreen()));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      tester.takeException();

      await expectLater(
        find.byType(NotificationSettingsScreen),
        matchesGoldenFile('goldens/notifications_$mode.png'),
      );
    }, skip: _manualOnly);
  }
}
