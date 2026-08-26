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
import 'screens/app_update_screen.dart';
import 'services/notification_service.dart';
import 'theme/jira_theme.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
bool _onboardingComplete = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up notification action routing
  NotificationService.onActionClicked = (actionId, payload) {
    if (payload == 'app_update' || actionId == 'open_update') {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const AppUpdateScreen()),
      );
    }
  };

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
        .then((_) => NotificationService.scheduleDaily6AMUpdateCheck())
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
          displayLarge: GoogleFonts.plusJakartaSans(
            textStyle: baseTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
          ),
          displayMedium: GoogleFonts.plusJakartaSans(
            textStyle: baseTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
          ),
          displaySmall: GoogleFonts.plusJakartaSans(
            textStyle: baseTheme.displaySmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.3),
          ),
          headlineLarge: GoogleFonts.plusJakartaSans(
            textStyle: baseTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
          ),
          headlineMedium: GoogleFonts.plusJakartaSans(
            textStyle: baseTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
          ),
          headlineSmall: GoogleFonts.plusJakartaSans(
            textStyle: baseTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.1),
          ),
          titleLarge: GoogleFonts.plusJakartaSans(
            textStyle: baseTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.1),
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            textStyle: baseTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          titleSmall: GoogleFonts.plusJakartaSans(
            textStyle: baseTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          bodyLarge: GoogleFonts.inter(
            textStyle: baseTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400, height: 1.4),
          ),
          bodyMedium: GoogleFonts.inter(
            textStyle: baseTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400, height: 1.4),
          ),
          bodySmall: GoogleFonts.inter(
            textStyle: baseTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400, height: 1.3),
          ),
          labelLarge: GoogleFonts.inter(
            textStyle: baseTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          labelMedium: GoogleFonts.inter(
            textStyle: baseTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          labelSmall: GoogleFonts.inter(
            textStyle: baseTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
          ),
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
              borderRadius: BorderRadius.circular(JiraTheme.radiusCard),
              side: const BorderSide(color: JiraTheme.darkBorderSubtle, width: 1),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
          ),
          dividerTheme: const DividerThemeData(
            color: JiraTheme.darkBorderSubtle,
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
              borderRadius: BorderRadius.circular(JiraTheme.radiusCard),
              side: const BorderSide(color: JiraTheme.lightBorderSubtle, width: 1),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
          ),
          dividerTheme: const DividerThemeData(
            color: JiraTheme.lightBorderSubtle,
            thickness: 1,
            space: 1,
          ),
        );

        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          title: 'Nuswally Lillah',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: lightThemeData,
          darkTheme: darkThemeData,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(
                  minScaleFactor: 0.85,
                  maxScaleFactor: 1.20,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
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
