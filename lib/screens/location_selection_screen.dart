import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/prayer_provider.dart';
import '../models/location_model.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen>
    with SingleTickerProviderStateMixin {
  District? _selectedDistrict;
  Location? _selectedLocation;
  int _step = 0;
  bool _isConfirming = false;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _selectDistrict(District d) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDistrict = d;
      _selectedLocation = null;
      _step = 1;
    });
    _slideCtrl.forward(from: 0);
  }

  void _goBackToDistrict() {
    HapticFeedback.lightImpact();
    setState(() {
      _step = 0;
      _selectedLocation = null;
    });
    _slideCtrl.reverse();
  }

  Future<void> _confirmLocation(BuildContext context) async {
    if (_selectedLocation == null || _isConfirming) return;
    setState(() => _isConfirming = true);
    HapticFeedback.mediumImpact();
    final navigator = Navigator.of(context);
    await context.read<PrayerProvider>().selectLocation(_selectedLocation!);
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final accent = theme.primaryAccent;
    final bgTop = theme.backgroundTop;
    final bgBottom = theme.backgroundBottom;
    final cardColor = theme.containerColor;
    final provider = context.watch<PrayerProvider>();
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 680;

    return Scaffold(
      backgroundColor: bgBottom,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Custom AppBar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_step == 1) {
                          _goBackToDistrict();
                        } else {
                          Navigator.pop(context);
                          HapticFeedback.lightImpact();
                        }
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _step == 0 ? 'Select District' : 'Select Area',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Header Section ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_step == 1)
                      GestureDetector(
                        onTap: _goBackToDistrict,
                        child: Row(
                          children: [
                            Icon(Icons.arrow_back_ios_new_rounded,
                                size: 13, color: accent),
                            const SizedBox(width: 4),
                            Text(
                              'Change District',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_step == 1) const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.1),
                            border: Border.all(
                                color: accent.withValues(alpha: 0.25)),
                          ),
                          child:
                              Icon(Icons.location_on_rounded, color: accent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _step == 0
                                    ? 'Select Your District'
                                    : 'Select Your Area',
                                style: GoogleFonts.outfit(
                                  fontSize: isSmall ? 18 : 21,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _step == 0
                                    ? 'Your location ensures precise prayer times'
                                    : 'Areas in ${_selectedDistrict!.name}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.4),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── List Area ──
              Expanded(
                child: _step == 0
                    ? _DistrictGrid(
                        districts: provider.districts,
                        accent: accent,
                        cardColor: cardColor,
                        isSmall: isSmall,
                        onSelect: _selectDistrict,
                      )
                    : SlideTransition(
                        position: _slideAnim,
                        child: _PlaceGrid(
                          locations: _selectedDistrict!.locations,
                          accent: accent,
                          cardColor: cardColor,
                          isSmall: isSmall,
                          selectedLocation: _selectedLocation,
                          onSelect: (loc) {
                            HapticFeedback.lightImpact();
                            setState(() => _selectedLocation = loc);
                          },
                        ),
                      ),
              ),

              // ── Confirm Button ──
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: _step == 1
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(
                            20, 10, 20, MediaQuery.of(context).padding.bottom + 20),
                        child: _ObGlowButton(
                          label: _isConfirming
                              ? 'Saving location...'
                              : 'Confirm My Location',
                          accent: accent,
                          icon: _isConfirming
                              ? Icons.hourglass_top_rounded
                              : Icons.check_circle_rounded,
                          enabled: _selectedLocation != null && !_isConfirming,
                          onTap: () => _confirmLocation(context),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── District Grid ──
class _DistrictGrid extends StatelessWidget {
  final List<District> districts;
  final Color accent;
  final Color cardColor;
  final bool isSmall;
  final ValueChanged<District> onSelect;

  const _DistrictGrid({
    required this.districts,
    required this.accent,
    required this.cardColor,
    required this.isSmall,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final itemW = (constraints.maxWidth - 40 - 12) / 2;
        final itemH = isSmall ? 46.0 : 52.0;
        final ratio = itemW / itemH;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 10,
            childAspectRatio: ratio,
          ),
          itemCount: districts.length,
          itemBuilder: (ctx, i) {
            final d = districts[i];
            return GestureDetector(
              onTap: () => onSelect(d),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cardColor,
                      cardColor.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.12),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined,
                        size: 14, color: accent.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        d.name,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Place Grid ──
class _PlaceGrid extends StatelessWidget {
  final List<Location> locations;
  final Color accent;
  final Color cardColor;
  final bool isSmall;
  final Location? selectedLocation;
  final ValueChanged<Location> onSelect;

  const _PlaceGrid({
    required this.locations,
    required this.accent,
    required this.cardColor,
    required this.isSmall,
    required this.selectedLocation,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final itemW = (constraints.maxWidth - 40 - 12) / 2;
        final itemH = isSmall ? 46.0 : 52.0;
        final ratio = itemW / itemH;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 10,
            childAspectRatio: ratio,
          ),
          itemCount: locations.length,
          itemBuilder: (ctx, i) {
            final loc = locations[i];
            final isSelected = selectedLocation?.id == loc.id;
            return GestureDetector(
              onTap: () => onSelect(loc),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            accent.withValues(alpha: 0.18),
                            cardColor.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            cardColor,
                            cardColor.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? accent
                        : accent.withValues(alpha: 0.12),
                    width: isSelected ? 1.8 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? accent.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.15),
                      blurRadius: isSelected ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, size: 14, color: accent),
                    if (isSelected) const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        loc.name,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? accent
                              : Colors.white.withValues(alpha: 0.85),
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Glow Button ──
class _ObGlowButton extends StatelessWidget {
  final String label;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _ObGlowButton({
    required this.label,
    required this.accent,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.75)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          border: enabled
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: enabled
                    ? Colors.black
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon,
                size: 17,
                color: enabled
                    ? Colors.black
                    : Colors.white.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }
}
