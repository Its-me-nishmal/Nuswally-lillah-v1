import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';
import '../models/location_model.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  District? _selectedDistrict;
  Location? _tempSelectedLocation;
  int _step = 1; // 1: District, 2: Place

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _step == 1 ? 'Select District' : 'Select Place',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: _step == 2 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _step = 1),
            )
          : null,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<PrayerProvider>(
        builder: (context, provider, child) {
          if (_step == 1) {
            return _buildDistrictList(provider, colorScheme, isDark);
          } else {
            return _buildPlaceList(provider, colorScheme, isDark);
          }
        },
      ),
      bottomNavigationBar: _step == 2 
        ? SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: _tempSelectedLocation != null 
                  ? () {
                      context.read<PrayerProvider>().selectLocation(_tempSelectedLocation!);
                      Navigator.of(context).pop();
                    }
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'CONFIRM LOCATION',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          )
        : null,
    );
  }

  Widget _buildDistrictList(PrayerProvider provider, ColorScheme colorScheme, bool isDark) {
    return RadioGroup<int>(
      groupValue: _selectedDistrict?.id,
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedDistrict = provider.districts.firstWhere((d) => d.id == val);
            _step = 2;
            _tempSelectedLocation = null;
          });
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: provider.districts.length,
        itemBuilder: (context, index) {
          final district = provider.districts[index];
          final isSelected = _selectedDistrict?.id == district.id;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : (isDark ? const Color(0xFF1A2626) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.05),
                width: 1.5,
              ),
            ),
            child: RadioListTile<int>(
              value: district.id,
              title: Text(
                district.name,
                style: GoogleFonts.outfit(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              activeColor: colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceList(PrayerProvider provider, ColorScheme colorScheme, bool isDark) {
    if (_selectedDistrict == null) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'Places in ${_selectedDistrict!.name}',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: colorScheme.primary.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: RadioGroup<int>(
            groupValue: _tempSelectedLocation?.id,
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _tempSelectedLocation = _selectedDistrict!.locations.firstWhere((l) => l.id == val);
                });
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _selectedDistrict!.locations.length,
              itemBuilder: (context, index) {
                final location = _selectedDistrict!.locations[index];
                final isSelected = _tempSelectedLocation?.id == location.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.secondary.withValues(alpha: 0.1) : (isDark ? const Color(0xFF1A2626) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? colorScheme.secondary : colorScheme.primary.withValues(alpha: 0.05),
                      width: 1.5,
                    ),
                  ),
                  child: RadioListTile<int>(
                    value: location.id,
                    title: Text(
                      location.name,
                      style: GoogleFonts.outfit(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? colorScheme.secondary : colorScheme.onSurface,
                      ),
                    ),
                    activeColor: colorScheme.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
