import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/quran_provider.dart';
import '../../theme/jira_theme.dart';
import '../heartbeat_tap.dart';

class ReciterPickerSheet extends StatefulWidget {
  const ReciterPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
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
                color: const Color(0xFF30363D),
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
                        color: const Color(0xFFF0F6FC),
                      ),
                    ),
                    Text(
                      'Powered by QuranicAudio • ${allQaris.length} Available Qaris',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF8B949E),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: JiraTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: JiraTheme.primaryBlue.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${allQaris.length} QARIS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF93C5FD),
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
              color: const Color(0xFF1F242C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 18, color: Color(0xFF8B949E)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFF0F6FC)),
                    cursorColor: JiraTheme.primaryBlue,
                    decoration: InputDecoration(
                      hintText: 'Search by reciter name (e.g. Sudais, Mishary)...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
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
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF8B949E)),
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
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8B949E)),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final qari = filtered[index];
                      final isSelected = selectedQari.id == qari.id ||
                          selectedQari.relativePath == qari.relativePath;

                      return HeartbeatTap(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          qp.updateQariObject(qari);
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? JiraTheme.primaryBlue.withValues(alpha: 0.15)
                                : const Color(0xFF1F242C),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? JiraTheme.primaryBlue : const Color(0xFF30363D),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? JiraTheme.primaryBlue
                                      : const Color(0xFF161B22),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.headphones_rounded,
                                  color: isSelected ? Colors.white : const Color(0xFF8B949E),
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
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected
                                            ? JiraTheme.primaryBlue
                                            : const Color(0xFFF0F6FC),
                                      ),
                                    ),
                                    if (qari.arabicName.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        qari.arabicName,
                                        style: const TextStyle(
                                          fontFamily: 'HafsFont',
                                          fontSize: 13,
                                          color: Color(0xFF8B949E),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: JiraTheme.primaryBlue,
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
