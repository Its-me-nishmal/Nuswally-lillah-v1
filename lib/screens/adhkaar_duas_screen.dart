import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/adhkaar.dart';
import '../providers/adhkaar_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/jira_theme.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/jira_screen.dart';
import 'dua_detail_screen.dart';

class AdhkaarDuasScreen extends StatelessWidget {
  final AdhkaarSubCategory sub;

  const AdhkaarDuasScreen({super.key, required this.sub});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isMl = tp.isMalayalam;
    final bundle = context.watch<AdhkaarProvider>().bundle;

    if (bundle == null) {
      return JiraScreen(
        child: Center(
          child: CircularProgressIndicator(color: tp.primaryAccent),
        ),
      );
    }

    final duas = sub.duaIds
        .map((id) => bundle.duas[id])
        .whereType<Dua>()
        .toList();

    final titleHeader = isMl
        ? sub.title
        : (sub.titleEn.isNotEmpty ? sub.titleEn : sub.title);

    return JiraScreen(
      child: Column(
        children: [
          // 1. Top App Bar
          _buildTopAppBar(context, tp, titleHeader, duas.length),

          // 2. Subcategory Header Banner if Arabic exists
          if (sub.titleArabic.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: tp.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tp.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      sub.titleArabic,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'HafsFont',
                        fontSize: 16,
                        color: tp.primaryAccent,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMl ? '${duas.length} പ്രാർത്ഥനകൾ' : '${duas.length} Authentic Supplications',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: tp.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 6),

          // 3. Duas List
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 6, 16, 24 + MediaQuery.paddingOf(context).bottom),
              itemCount: duas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _DuaCard(dua: duas[index], index: index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, ThemeProvider tp, String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Frosted circular back button
          HeartbeatTap(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tp.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: tp.borderColor),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: tp.textPrimary,
                size: 18,
              ),
            ),
          ),

          // Title
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: tp.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // Count pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tp.containerColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tp.borderColor),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: tp.primaryAccent,
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

  const _DuaCard({required this.dua, required this.index});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return HeartbeatTap(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DuaDetailScreen(dua: dua),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tp.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tp.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Number Index + Arabic Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tp.containerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: tp.primaryAccent,
                      ),
                    ),
                  ),
                ),
                if (dua.hint.isNotEmpty)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: JiraTheme.secondaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dua.hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: JiraTheme.secondaryGreen,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Arabic Calligraphy snippet
            if (dua.dua.isNotEmpty)
              Text(
                dua.dua,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'HafsFont',
                  fontSize: 20,
                  height: 1.45,
                  color: tp.textPrimary,
                ),
              ),

            if (dua.transli.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                dua.transli,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: tp.textSecondary,
                  height: 1.35,
                ),
              ),
            ],

            if (dua.ref.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 12,
                    color: tp.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dua.ref,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: tp.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
