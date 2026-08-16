import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/adhkaar.dart';
import '../providers/adhkaar_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/jira_theme.dart';
import '../widgets/heartbeat_tap.dart';
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
      return const Scaffold(
        backgroundColor: Color(0xFF0B0E14),
        body: Center(child: CircularProgressIndicator(color: JiraTheme.primaryBlue)),
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
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top App Bar
            _buildTopAppBar(context, titleHeader, duas.length),

            // 2. Subcategory Header Banner if Arabic exists
            if (sub.titleArabic.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        sub.titleArabic,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'HafsFont',
                          fontSize: 16,
                          color: Color(0xFF93C5FD),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMl ? '${duas.length} പ്രാർത്ഥനകൾ' : '${duas.length} Authentic Supplications',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF8B949E),
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
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                itemCount: duas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _DuaCard(dua: duas[index], index: index + 1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Frosted circular back button
          HeartbeatTap(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFFF0F6FC),
                size: 20,
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
                  color: const Color(0xFFF0F6FC),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // Count pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1F242C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF93C5FD),
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
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF30363D)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                    color: const Color(0xFF1F242C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF93C5FD),
                      ),
                    ),
                  ),
                ),
                if (dua.hint.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: JiraTheme.secondaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dua.hint,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: JiraTheme.secondaryGreen,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Sacred Arabic Text
            Text(
              dua.dua,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'HafsFont',
                fontSize: 19,
                height: 1.7,
                color: Colors.white,
              ),
            ),

            // Preview Transliteration
            if (dua.transli.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                dua.transli,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Indulekha',
                  fontSize: 12.5,
                  color: Color(0xFF93C5FD),
                  height: 1.45,
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Bottom Chevron Row
            const Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: JiraTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
