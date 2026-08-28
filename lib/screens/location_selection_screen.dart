import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/location_model.dart';
import '../providers/prayer_provider.dart';
import '../widgets/heartbeat_tap.dart';
import '../theme/app_colors.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  District? _selectedDistrict;
  Location? _selectedLocation;
  int _step = 0;
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
    final nav = Navigator.of(context);
    await context.read<PrayerProvider>().selectLocation(_selectedLocation!);
    if (mounted) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final provider = context.watch<PrayerProvider>();
    final districts = provider.districts;

    return Scaffold(
      backgroundColor: context.pageTop,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  HeartbeatTap(
                    onTap: () {
                      if (_step == 1) {
                        _goBackToDistrict();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.cardTop,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.cardBorder),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: context.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _step == 0
                              ? 'Select Your District'
                              : 'Select Your Area',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          _step == 0
                              ? 'Your location ensures micro-precise prayer times & Qibla.'
                              : '${_selectedDistrict?.name ?? ''} District • ${_selectedDistrict?.locations.length ?? 0} Towns',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: context.textSecondary,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'KERALA DISTRICTS (${districts.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    16 + MediaQuery.paddingOf(context).bottom,
                  ),
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
                          color: context.cardTop,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 16,
                              color: context.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                d.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: context.cardTop,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: context.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _areaSearchQuery = val),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: context.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Search town or village (e.g. Vadakara, Feroke)...',
                            hintStyle: TextStyle(
                              color: context.textMuted,
                              fontSize: 12,
                            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.cardTop,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.accent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: context.accent,
                        size: 20,
                      ),
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
                                color: context.textPrimary,
                              ),
                            ),
                            Text(
                              'Solar calculation method: Kerala Samastha Standard (18°)',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: context.textSecondary,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
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
                              color: context.cardTop,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? context.accent
                                    : context.cardBorder,
                                width: isSelected ? 1.2 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${loc.district} • Solar Calculation Zone',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: context.textSecondary,
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
                                    color: isSelected
                                        ? context.accent
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? context.accent
                                          : context.textMuted,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(
                                            Icons.check,
                                            size: 13,
                                            color: Colors.white,
                                          ),
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
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  children: [
                    HeartbeatTap(
                      onTap: () => _confirmLocation(context),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: context.accent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: context.accent.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
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
                        color: context.textMuted,
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
