import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/location_model.dart';
import '../../providers/prayer_provider.dart';
import '../../theme/jira_theme.dart';
import '../../widgets/heartbeat_tap.dart';

class ObPage2Location extends StatefulWidget {
  final VoidCallback onNext;

  const ObPage2Location({super.key, required this.onNext});

  @override
  State<ObPage2Location> createState() => _ObPage2LocationState();
}

class _ObPage2LocationState extends State<ObPage2Location> {
  District? _selectedDistrict;
  Location? _selectedLocation;
  int _step = 0; // 0 = District Grid, 1 = Area / Town List
  String _areaSearchQuery = '';

  void _selectDistrict(District d) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDistrict = d;
      _selectedLocation = d.locations.isNotEmpty ? d.locations.first : null;
      _step = 1;
      _areaSearchQuery = '';
    });
  }

  void _goBackToDistrict() {
    HapticFeedback.selectionClick();
    setState(() {
      _step = 0;
      _areaSearchQuery = '';
    });
  }

  Future<void> _confirmLocation(BuildContext context) async {
    if (_selectedLocation == null) return;
    HapticFeedback.selectionClick();
    await context.read<PrayerProvider>().selectLocation(_selectedLocation!);
    if (mounted) widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();
    final districts = provider.districts;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Breadcrumb
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (_step == 1) ...[
                    HeartbeatTap(
                      onTap: _goBackToDistrict,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF30363D)),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFFF0F6FC),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _step == 0 ? 'Select Your District' : 'Select Your Area',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF0F6FC),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _step == 0
                              ? 'Your location ensures micro-precise prayer times & Qibla.'
                              : '${_selectedDistrict?.name ?? ''} District • ${_selectedDistrict?.locations.length ?? 0} Towns',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF8B949E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Step 0: 2-Column District Grid
            if (_step == 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'KERALA DISTRICTS (${districts.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      color: const Color(0xFF8B949E),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.7,
                  ),
                  itemCount: districts.length,
                  itemBuilder: (context, index) {
                    final d = districts[index];
                    return HeartbeatTap(
                      onTap: () => _selectDistrict(d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF30363D)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.map_outlined,
                              size: 16,
                              color: JiraTheme.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                d.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF0F6FC),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]
            // Step 1: Area / Town Selection List with Search and Confirmation
            else ...[
              // Live Area Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFF8B949E), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _areaSearchQuery = val),
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Search town or village (e.g. Vadakara, Feroke)...',
                            hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Solar Calculation Info Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: JiraTheme.primaryBlue.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: JiraTheme.primaryBlue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Accurate calculation zones in ${_selectedDistrict?.name ?? ''}',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF0F6FC),
                              ),
                            ),
                            Text(
                              'Solar calculation method: Kerala Samastha Standard (18°)',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: const Color(0xFF8B949E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Town List
              Expanded(
                child: Builder(
                  builder: (context) {
                    final query = _areaSearchQuery.trim().toLowerCase();
                    final allLocs = _selectedDistrict?.locations ?? [];
                    final filtered = allLocs.where((l) {
                      if (query.isEmpty) return true;
                      return l.name.toLowerCase().contains(query);
                    }).toList();

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final loc = filtered[index];
                        final isSelected = _selectedLocation?.id == loc.id;

                        return HeartbeatTap(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedLocation = loc);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? JiraTheme.primaryBlue : const Color(0xFF30363D),
                                width: isSelected ? 1.2 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFF0F6FC),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${loc.district} • Solar Calculation Zone',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFF8B949E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? JiraTheme.primaryBlue : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? JiraTheme.primaryBlue : const Color(0xFF64748B),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(Icons.check, size: 13, color: Colors.white),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Bottom Confirmation Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    HeartbeatTap(
                      onTap: () => _confirmLocation(context),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: JiraTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: JiraTheme.primaryBlue.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'SET AS MY PRAYER LOCATION',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Times will immediately calibrate across all widgets and Adhans',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
