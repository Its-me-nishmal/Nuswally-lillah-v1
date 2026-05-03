import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/quran_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          image: const DecorationImage(
            image: AssetImage('assets/images/islamic_bg.png'),
            opacity: 0.03,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 8),
                    _buildSectionLabel(context, 'APPEARANCE'),
                    const SizedBox(height: 12),
                    _buildThemeCard(context, isDark),
                    const SizedBox(height: 24),
                    _buildSectionLabel(context, 'QURAN'),
                    const SizedBox(height: 12),
                    _buildFontSizeCard(context, isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Text(
            'Settings',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.5,
        color: colorScheme.primary.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();

    final options = [
      (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
      (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
    ];

    return _buildCard(
      context,
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                'Theme',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: options.map((option) {
              final (mode, icon, label) = option;
              final isSelected = themeProvider.themeMode == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => themeProvider.setTheme(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          icon,
                          color: isSelected ? Colors.white : colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeCard(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final quranProvider = context.watch<QuranProvider>();

    return _buildCard(
      context,
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.format_size_rounded, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Arabic Font Size',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${quranProvider.fontSize.toInt()}px',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
            style: TextStyle(
              fontFamily: 'HafsFont',
              fontSize: quranProvider.fontSize,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          Slider(
            value: quranProvider.fontSize,
            min: 20,
            max: 50,
            divisions: 15,
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.primary.withValues(alpha: 0.15),
            onChanged: (value) => quranProvider.updateFontSize(value),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Small', style: GoogleFonts.outfit(fontSize: 11, color: colorScheme.primary.withValues(alpha: 0.4))),
              Text('Large', style: GoogleFonts.outfit(fontSize: 11, color: colorScheme.primary.withValues(alpha: 0.4))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isDark, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.06),
        ),
      ),
      child: child,
    );
  }
}
