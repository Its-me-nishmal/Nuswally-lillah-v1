import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/prayer_time_model.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/home_design.dart';
import '../../utils/prayer_time_format.dart';
import 'home_glyphs.dart';

/// Next-prayer hero card: gold-framed, with a mosque arch motif, a live
/// countdown pill and a contextual "how far away" line.
class NextPrayerHeroCard extends StatefulWidget {
  const NextPrayerHeroCard({super.key});

  @override
  State<NextPrayerHeroCard> createState() => _NextPrayerHeroCardState();
}

class _NextPrayerHeroCardState extends State<NextPrayerHeroCard> {
  Timer? _localTimer;

  /// Only the countdown pill and the proximity line listen to this, so the
  /// second-by-second tick never rebuilds the whole card.
  final ValueNotifier<Duration> _remaining = ValueNotifier(Duration.zero);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRemaining());
    _localTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _syncRemaining(),
    );
  }

  void _syncRemaining() {
    if (!mounted) return;
    _remaining.value = context.read<PrayerProvider>().timeToNextPrayer;
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    _remaining.dispose();
    super.dispose();
  }

  String? _rawTime(PrayerTime times, String prayerName) => switch (prayerName) {
    'Fajr' => times.fajr,
    'Sunrise' => times.sunrise,
    'Dhuhr' => times.dhuhr,
    'Asr' => times.asr,
    'Maghrib' => times.maghrib,
    'Isha' => times.isha,
    _ => null,
  };

  String _getPrayerTime(PrayerTime? times, String prayerName) {
    if (times == null) return '--:--';
    final raw = _rawTime(times, prayerName);
    return raw == null ? '--:--' : formatPrayerTime(prayerName, raw);
  }

  String _countdownLabel(Duration duration) {
    if (duration.isNegative) return 'in 00h 00m 00s';
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return 'in ${hours}h ${minutes}m ${seconds}s';
  }

  /// Congregation time for the next prayer: its start plus the user's Iqamah
  /// offset. Returns null when there is no Iqamah for it (Sunrise).
  String? _iqamahLabel(
    PrayerTime? times,
    String prayerName,
    int offsetMinutes,
  ) {
    if (times == null || prayerName == 'Sunrise') return null;
    final raw = _rawTime(times, prayerName);
    if (raw == null) return null;
    final parsed = parsePrayerTime24(prayerName, raw);
    if (parsed == null) return null;

    final total = parsed.hour * 60 + parsed.minute + offsetMinutes;
    final wrapped = ((total % 1440) + 1440) % 1440;
    return format24(wrapped ~/ 60, wrapped % 60);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    // PrayerProvider notifies once a second for its countdown; selecting only
    // the fields that actually change here keeps the card off that path.
    return Selector<PrayerProvider, (String, PrayerTime?, int)>(
      selector: (_, provider) => (
        provider.nextPrayerName,
        provider.todayPrayerTimes,
        provider.iqamahOffsets[provider.nextPrayerName] ?? 0,
      ),
      builder: (context, data, child) {
        final nextPrayer = data.$1.isNotEmpty ? data.$1 : 'Fajr';
        final nextTimeStr = _getPrayerTime(data.$2, nextPrayer);
        final iqamahStr = _iqamahLabel(data.$2, nextPrayer, data.$3);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: HomeDesign.cardGradient(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: HomeDesign.goldLineStrong(isDark),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: HomeDesign.shadow(isDark),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Decorative arch, clipped to the card's right edge. Kept
                // narrow (72dp) so the text columns still fit on a 360dp phone.
                Positioned(
                  right: -4,
                  top: 6,
                  bottom: 0,
                  child: MosqueArchGlyph(
                    width: 72,
                    height: 132,
                    gold: HomeDesign.gold,
                    domeColor: isDark
                        ? const Color(0xFF12362B)
                        : const Color(0xFFDCEDE5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 13, 88, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: NEXT PRAYER label + live countdown pill.
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: themeProvider.primaryAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'NEXT PRAYER',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.9,
                                color: themeProvider.accentText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Row 2: prayer name (shrinks to fit) + start time.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                nextPrayer.toUpperCase(),
                                maxLines: 1,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                  height: 1.05,
                                  color: themeProvider.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            nextTimeStr,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              // Darkened in light mode so the most important
                              // number on the screen stays legible.
                              color: themeProvider.accentText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Row 3: tagline + how far away it is.
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              HomeDesign.prayerTagline(nextPrayer),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: themeProvider.textSecondary,
                              ),
                            ),
                          ),
                          if (iqamahStr != null) ...[
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.groups_rounded,
                                  size: 13,
                                  color: HomeDesign.gold,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Iqamah $iqamahStr',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: HomeDesign.goldText(isDark),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Live countdown pill + gold underscore accent.
                      Row(
                        children: [
                          ValueListenableBuilder<Duration>(
                            valueListenable: _remaining,
                            builder: (context, remaining, _) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: HomeDesign.goldWash(isDark),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: HomeDesign.goldLine(isDark),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                _countdownLabel(remaining),
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: themeProvider.textPrimary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: HomeDesign.gold.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
