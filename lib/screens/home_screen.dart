import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';
import 'quran_screen.dart';
import 'haddad_screen.dart';
import 'tasbeeh_screen.dart';
import 'settings_screen.dart';
import 'location_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _startSplashTimer();
    _checkLocation();
  }

  void _checkLocation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PrayerProvider>();
      if (!provider.hasLocationSet) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const LocationSelectionScreen(),
          ),
        );
      }
    });
  }

  void _startSplashTimer() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              image: const DecorationImage(
                image: AssetImage('assets/images/islamic_bg.png'),
                opacity: 0.05,
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _buildModernAppBar(context),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: const [
                          _NextPrayerHero(),
                          SizedBox(height: 10),
                          _QuickToolActions(),
                          SizedBox(height: 30),
                          _PrayerList(),
                          _ModernFooter(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showSplash) _PrayerSplashOverlay(onDismiss: () {
            setState(() => _showSplash = false);
          }),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Selector<PrayerProvider, String>(
      selector: (_, provider) =>
          '${provider.selectedLocation?.name ?? "Select Location"}, ${provider.selectedLocation?.district ?? ""}',
      builder: (context, locationName, child) {
        return Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nuswally Lillah',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          locationName,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    ),
                    child: Icon(Icons.settings_outlined, size: 20, color: colorScheme.primary.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NextPrayerHero extends StatelessWidget {
  const _NextPrayerHero();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<PrayerProvider>(
      builder: (context, provider, child) {
        final duration = provider.timeToNextPrayer;
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        final seconds = duration.inSeconds.remainder(60);
        final isActive = provider.isPrayerActive;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              if (isActive)
                const _BlinkingLiveIcon(isPrayerTime: true)
              else
                Text(
                  'NEXT PRAYER',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                (isActive ? provider.activePrayerName : provider.nextPrayerName).toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isActive ? colorScheme.secondary : colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    isActive 
                        ? DateFormat('hh:mm').format(DateTime.now())
                        : '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}',
                    style: GoogleFonts.outfit(
                      fontSize: 56,
                      fontWeight: FontWeight.w300,
                      color: colorScheme.onSurface,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isActive 
                        ? DateFormat('ss').format(DateTime.now())
                        : seconds.toString().padLeft(2, '0'),
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w200,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              if (!isActive)
                Text(
                  'COUNTDOWN',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    letterSpacing: 1.5,
                  ),
                )
              else
                 Text(
                  'CURRENT TIME',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                    letterSpacing: 1.5,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickToolActions extends StatelessWidget {
  const _QuickToolActions();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildToolButton(
            context,
            'Holy Quran',
            Icons.menu_book_rounded,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuranScreen()),
            ),
          ),
          const SizedBox(width: 12),
          _buildToolButton(
            context,
            'Tasbih',
            Icons.fingerprint_rounded,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TasbeehScreen()),
            ),
          ),
          const SizedBox(width: 12),
          _buildToolButton(
            context,
            'Haddad',
            Icons.auto_stories_rounded,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HaddadScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerList extends StatelessWidget {
  const _PrayerList();

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerProvider>(
      builder: (context, provider, child) {
        if (provider.todayPrayerTimes == null) return const SizedBox();

        final times = [
          _PrayerItem('Fajr', provider.todayPrayerTimes!.fajr, Icons.wb_twilight_rounded),
          _PrayerItem('Sunrise', provider.todayPrayerTimes!.sunrise, Icons.wb_sunny_rounded),
          _PrayerItem('Dhuhr', provider.todayPrayerTimes!.dhuhr, Icons.wb_sunny_rounded),
          _PrayerItem('Asr', provider.todayPrayerTimes!.asr, Icons.wb_cloudy_rounded),
          _PrayerItem('Maghrib', provider.todayPrayerTimes!.maghrib, Icons.nights_stay_rounded),
          _PrayerItem('Isha', provider.todayPrayerTimes!.isha, Icons.nightlight_round),
        ];

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: times.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = times[index];
            final isNext = provider.nextPrayerName == item.name;
            return _PrayerRow(item: item, isNext: isNext);
          },
        );
      },
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final _PrayerItem item;
  final bool isNext;

  const _PrayerRow({required this.item, required this.isNext});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isNext
            ? colorScheme.secondary.withValues(alpha: 0.1)
            : (isDark ? colorScheme.surfaceContainerHighest : Colors.white),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isNext ? colorScheme.secondary : colorScheme.primary.withValues(alpha: 0.05),
          width: isNext ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(item.icon, color: isNext ? colorScheme.secondary : colorScheme.primary, size: 20),
              const SizedBox(width: 15),
              Text(
                item.name,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          Text(
            item.time,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isNext ? colorScheme.secondary : colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerItem {
  final String name;
  final String time;
  final IconData icon;
  _PrayerItem(this.name, this.time, this.icon);
}

class _ModernFooter extends StatelessWidget {
  const _ModernFooter();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(height: 1, width: 30, color: colorScheme.primary.withValues(alpha: 0.1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Nishmal Vadakara',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary.withValues(alpha: 0.3),
                letterSpacing: 1,
              ),
            ),
          ),
          Container(height: 1, width: 30, color: colorScheme.primary.withValues(alpha: 0.1)),
        ],
      ),
    );
  }
}

class _BlinkingLiveIcon extends StatefulWidget {
  final bool isPrayerTime;
  const _BlinkingLiveIcon({required this.isPrayerTime});

  @override
  State<_BlinkingLiveIcon> createState() => _BlinkingLiveIconState();
}

class _BlinkingLiveIconState extends State<_BlinkingLiveIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = widget.isPrayerTime ? colorScheme.secondary : Colors.greenAccent;

    return FadeTransition(
      opacity: _controller,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: activeColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              'LIVE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: activeColor, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowingBackground extends StatefulWidget {
  const _GlowingBackground();
  @override
  State<_GlowingBackground> createState() => _GlowingBackgroundState();
}

class _GlowingBackgroundState extends State<_GlowingBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -100 + (50 * (1 + _controller.value)),
              right: -100,
              child: _GlowCircle(color: colorScheme.primary.withValues(alpha: 0.15), size: 300),
            ),
            Positioned(
              bottom: -50,
              left: -100 + (30 * _controller.value),
              child: _GlowCircle(color: colorScheme.secondary.withValues(alpha: 0.1), size: 400),
            ),
          ],
        );
      },
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])),
    );
  }
}

class _PrayerSplashOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  const _PrayerSplashOverlay({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bismillah',
              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              'Beginning with the name of Allah',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
