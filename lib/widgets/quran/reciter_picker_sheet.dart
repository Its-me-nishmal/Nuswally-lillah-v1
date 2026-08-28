import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/quran_provider.dart';
import '../heartbeat_tap.dart';
import '../../theme/app_colors.dart';

class ReciterPickerSheet extends StatefulWidget {
  const ReciterPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      backgroundColor: context.cardTop,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const ReciterPickerSheet(),
    );
  }

  @override
  State<ReciterPickerSheet> createState() => _ReciterPickerSheetState();
}

class _ReciterPickerSheetState extends State<ReciterPickerSheet> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final qp = context.watch<QuranProvider>();
    final allQaris = qp.qaris;
    final selectedQari = qp.selectedQariObj;

    final query = _searchQuery.trim().toLowerCase();
    final filtered = allQaris.where((q) {
      if (query.isEmpty) return true;
      return q.name.toLowerCase().contains(query) ||
          q.arabicName.contains(query) ||
          q.relativePath.toLowerCase().contains(query);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Reciter (Qari)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      'Powered by QuranicAudio • ${allQaris.length} Available Qaris',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: context.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${allQaris.length} QARIS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: context.accent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Search Bar
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: context.cardBottom,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.cardBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: context.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: context.textPrimary,
                    ),
                    cursorColor: context.accent,
                    decoration: InputDecoration(
                      hintText:
                          'Search by reciter name (e.g. Sudais, Mishary)...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: context.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // List of Qaris
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No reciters match "$_searchQuery"',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: context.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final qari = filtered[index];
                      final isSelected =
                          selectedQari.id == qari.id ||
                          selectedQari.relativePath == qari.relativePath;

                      return HeartbeatTap(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          qp.updateQariObject(qari);
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.accent.withValues(alpha: 0.15)
                                : context.cardBottom,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? context.accent
                                  : context.cardBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? context.accent
                                      : context.cardTop,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.headphones_rounded,
                                  color: isSelected
                                      ? Colors.white
                                      : context.textSecondary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      qari.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? context.accent
                                            : context.textPrimary,
                                      ),
                                    ),
                                    if (qari.arabicName.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        qari.arabicName,
                                        style: TextStyle(
                                          fontFamily: 'HafsFont',
                                          fontSize: 13,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: context.accent,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
