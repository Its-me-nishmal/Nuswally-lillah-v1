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
import 'package:nuswally_lillah/screens/app_update_screen.dart';
import 'package:nuswally_lillah/screens/awraad_screen.dart';
import 'package:nuswally_lillah/screens/developer_profile_screen.dart';
import 'package:nuswally_lillah/screens/haddad_screen.dart';
import 'package:nuswally_lillah/screens/library_tab_body.dart';
import 'package:nuswally_lillah/screens/location_selection_screen.dart';
import 'package:nuswally_lillah/screens/media_tab_body.dart';
import 'package:nuswally_lillah/screens/more_tab_body.dart';
import 'package:nuswally_lillah/screens/names_screen.dart';
import 'package:nuswally_lillah/screens/progress_screen.dart';
import 'package:nuswally_lillah/screens/qibla_screen.dart';
import 'package:nuswally_lillah/screens/quran_tab_body.dart';
import 'package:nuswally_lillah/screens/quranic_duas_screen.dart';
import 'package:nuswally_lillah/screens/tasbeeh_screen.dart';

Widget _host(Widget child) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => PrayerProvider()),
    ChangeNotifierProvider(create: (_) => JournalProvider()),
    ChangeNotifierProvider(create: (_) => QuranProvider()),
    ChangeNotifierProvider(create: (_) => AdhkaarProvider()),
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: child),
  ),
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
  final screens = <String, Widget>{
    'location': const LocationSelectionScreen(),
    'appupdate': const AppUpdateScreen(),
    'qibla': const QiblaScreen(),
    'progress': const ProgressJournalScreen(),
    'names': const NamesScreen(),
    'tasbeeh': const TasbeehScreen(),
    'awraad': const AwraadScreen(),
    'haddad': const HaddadScreen(),
    'quranicduas': const QuranicDuasScreen(),
    'developer': const DeveloperProfileScreen(),
    'qurantab': const QuranTabBody(searchQuery: ''),
    'librarytab': const LibraryTabBody(searchQuery: ''),
    'mediatab': const MediaTabBody(),
    'moretab': const MoreTabBody(),
  };

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({'is_app_dark_mode': false});
  });

  screens.forEach((name, widget) {
    testWidgets('$name in light mode', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(widget));
      // Several frames so AnimatedContainer colour transitions finish; a
      // single long pump captures them mid-flight.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      tester.takeException();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/light_$name.png'),
      );
    }, skip: _manualOnly);
  });
}
