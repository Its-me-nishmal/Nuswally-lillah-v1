import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/adhkaar.dart';
import '../providers/adhkaar_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/heartbeat_tap.dart';
import 'dua_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/home_design.dart';

class AdhkaarDuasScreen extends StatelessWidget {
  final AdhkaarSubCategory sub;

  const AdhkaarDuasScreen({super.key, required this.sub});

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final tp = context.watch<ThemeProvider>();
    final isDark = tp.isDarkMode;
    final isMl = tp.isMalayalam;
    final bundle = context.watch<AdhkaarProvider>().bundle;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const double kTopBarHeight = 56.0;

    if (bundle == null) {
      return Scaffold(
        backgroundColor: tp.backgroundTop,
        body: Center(child: CircularProgressIndicator(color: tp.primaryAccent)),
      );
    }

    final duas = sub.duaIds
        .map((id) => bundle.duas[id])
        .whereType<Dua>()
        .toList();

    final titleHeader = isMl
        ? sub.title
        : (sub.titleEn.isNotEmpty ? sub.titleEn : sub.title);

    return Scaffold(
      backgroundColor: tp.backgroundTop,
      body: Stack(
        children: [
          // Background Gradient & Subtle Pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [tp.backgroundTop, tp.backgroundBottom],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.035,
              child: Image.asset(
                'assets/images/islamic_bg.webp',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

          // Scrollable Content
          Positioned.fill(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                topInset + kTopBarHeight + 12,
                16,
                bottomInset + 24,
              ),
              children: [
                // Chapter Banner
                if (sub.titleArabic.trim().isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: tp.surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: tp.borderColor, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.25 : 0.03,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          sub.titleArabic,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'HafsFont',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? HomeDesign.goldText(isDark)
                                : tp.primaryAccent,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isMl
                              ? '${duas.length} പ്രാർത്ഥനകൾ'
                              : '${duas.length} Authentic Supplications',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: tp.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Duas List
                ...duas.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DuaCard(
                      dua: entry.value,
                      index: entry.key + 1,
                      isMl: isMl,
                    ),
                  );
                }),
              ],
            ),
          ),

          // Fixed Frosted 56px Top Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + kTopBarHeight,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(top: topInset),
                  decoration: BoxDecoration(
                    color: tp.backgroundTop.withValues(
                      alpha: isDark ? 0.85 : 0.90,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: tp.borderColor.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Container(
                    height: 56.0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Circular Back Button
                        HeartbeatTap(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: tp.surfaceColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: tp.borderColor,
                                width: 0.8,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: tp.textPrimary,
                                size: 16,
                              ),
                            ),
                          ),
                        ),

                        // Center Title
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  titleHeader,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: tp.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${duas.length} Invocations',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: tp.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Count Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tp.primaryAccent.withValues(
                              alpha: isDark ? 0.12 : 0.14,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tp.primaryAccent.withValues(
                                alpha: isDark ? 0.25 : 0.35,
                              ),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${duas.length}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: tp.primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  final Dua dua;
  final int index;
  final bool isMl;

  const _DuaCard({required this.dua, required this.index, required this.isMl});

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final tp = context.watch<ThemeProvider>();
    final isDark = tp.isDarkMode;

    return HeartbeatTap(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DuaDetailScreen(dua: dua)),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: tp.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tp.borderColor, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Number Badge + Repeat Count + Bookmark/Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: tp.primaryAccent.withValues(
                      alpha: isDark ? 0.12 : 0.14,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: tp.primaryAccent.withValues(
                        alpha: isDark ? 0.25 : 0.35,
                      ),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'DUA ${index.toString().padLeft(2, '0')}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tp.primaryAccent,
                    ),
                  ),
                ),
                if (dua.hint.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? context.cardTop : context.cardBottom,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? context.hairline : context.cardBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          size: 12,
                          color: tp.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dua.hint,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: tp.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Arabic Calligraphy
            Text(
              dua.dua,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'HafsFont',
                fontSize: 20,
                color: context.textPrimary,
                height: 1.7,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),

            // Translation
            Text(
              isMl && dua.trans.isNotEmpty
                  ? dua.trans
                  : (dua.descEn.isNotEmpty ? dua.descEn : dua.transli),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: tp.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Reference Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dua.ref.isNotEmpty ? dua.ref : 'Authentic Supplication',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: tp.primaryAccent,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: tp.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
