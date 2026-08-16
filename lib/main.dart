import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/prayer_provider.dart';
import 'providers/quran_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/adhkaar_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/jira_theme.dart';

bool _onboardingComplete = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (_) {}

  try {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  } catch (_) {}

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
        ChangeNotifierProvider(create: (_) => QuranProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => AdhkaarProvider()),
      ],
      child: AzanApp(onboardingComplete: _onboardingComplete),
    ),
  );

  // Initialize notification service without blocking the first frame.
  unawaited(
    NotificationService.init()
        .timeout(const Duration(seconds: 5), onTimeout: () {})
        .catchError((e) => debugPrint('NotificationService init error: $e')),
  );

  // Enable sticky immersive overlay styling
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );
}

class AzanApp extends StatelessWidget {
  final bool onboardingComplete;
  const AzanApp({super.key, required this.onboardingComplete});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;

        final baseTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
        final interTheme = GoogleFonts.interTextTheme(baseTheme);
        final textTheme = interTheme.copyWith(
          displayLarge: GoogleFonts.outfit(textStyle: baseTheme.displayLarge),
          displayMedium: GoogleFonts.outfit(textStyle: baseTheme.displayMedium),
          displaySmall: GoogleFonts.outfit(textStyle: baseTheme.displaySmall),
          headlineLarge: GoogleFonts.outfit(textStyle: baseTheme.headlineLarge),
          headlineMedium: GoogleFonts.outfit(textStyle: baseTheme.headlineMedium),
          headlineSmall: GoogleFonts.outfit(textStyle: baseTheme.headlineSmall),
          titleLarge: GoogleFonts.outfit(textStyle: baseTheme.titleLarge),
          titleMedium: GoogleFonts.outfit(textStyle: baseTheme.titleMedium),
          titleSmall: GoogleFonts.outfit(textStyle: baseTheme.titleSmall),
        );

        const pageTransitionsTheme = PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ObsidianFadePageTransitionsBuilder(),
            TargetPlatform.iOS: ObsidianFadePageTransitionsBuilder(),
            TargetPlatform.windows: ObsidianFadePageTransitionsBuilder(),
            TargetPlatform.macOS: ObsidianFadePageTransitionsBuilder(),
            TargetPlatform.linux: ObsidianFadePageTransitionsBuilder(),
          },
        );

        final darkThemeData = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: JiraTheme.darkBackground,
          pageTransitionsTheme: pageTransitionsTheme,
          colorScheme: const ColorScheme.dark(
            primary: JiraTheme.primaryBlue,
            secondary: JiraTheme.secondaryGreen,
            tertiary: JiraTheme.tertiaryOrange,
            surface: JiraTheme.darkSurface,
            surfaceContainerHighest: JiraTheme.darkContainer,
            onSurface: JiraTheme.darkTextPrimary,
            outline: JiraTheme.darkBorder,
          ),
          textTheme: textTheme,
          cardTheme: CardThemeData(
            elevation: 0,
            color: JiraTheme.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(JiraTheme.radiusMedium),
              side: const BorderSide(color: JiraTheme.darkBorder, width: 1),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
          ),
          dividerTheme: const DividerThemeData(
            color: JiraTheme.darkBorder,
            thickness: 1,
            space: 1,
          ),
        );

        final lightThemeData = ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: JiraTheme.lightBackground,
          pageTransitionsTheme: pageTransitionsTheme,
          colorScheme: const ColorScheme.light(
            primary: JiraTheme.primaryBlue,
            secondary: JiraTheme.secondaryGreen,
            tertiary: JiraTheme.tertiaryOrange,
            surface: JiraTheme.lightSurface,
            surfaceContainerHighest: JiraTheme.lightContainer,
            onSurface: JiraTheme.lightTextPrimary,
            outline: JiraTheme.lightBorder,
          ),
          textTheme: textTheme,
          cardTheme: CardThemeData(
            elevation: 0,
            color: JiraTheme.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(JiraTheme.radiusMedium),
              side: const BorderSide(color: JiraTheme.lightBorder, width: 1),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
          ),
          dividerTheme: const DividerThemeData(
            color: JiraTheme.lightBorder,
            thickness: 1,
            space: 1,
          ),
        );

        return MaterialApp(
          title: 'Nuswally Lillah',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: lightThemeData,
          darkTheme: darkThemeData,
          home: SplashScreen(onboardingComplete: onboardingComplete),
        );
      },
    );
  }
}

/// Clean Smooth Fade-In Page Transition Builder (no blink-through)
class ObsidianFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const ObsidianFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curvedAnimation,
      child: child,
    );
  }
}
