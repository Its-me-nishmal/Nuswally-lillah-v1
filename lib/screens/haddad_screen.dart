import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/haddad_item.dart';
import '../providers/theme_provider.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/jira_header.dart';
import '../widgets/jira_screen.dart';

class HaddadScreen extends StatefulWidget {
  const HaddadScreen({super.key});

  @override
  State<HaddadScreen> createState() => _HaddadScreenState();
}

class _HaddadScreenState extends State<HaddadScreen> {
  List<HaddadItem> _items = [];
  bool _isLoading = true;
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  int _currentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/haddad.json',
      );
      final data = await json.decode(response) as List;
      setState(() {
        _items = data.map((json) => HaddadItem.fromJson(json)).toList();
        _isLoading = false;
        _currentCount = _items.isNotEmpty ? _items[0].count : 0;
      });
    } catch (e) {
      debugPrint("Error loading Haddad data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _next() {
    if (_currentIndex < _items.length - 1) {
      HapticFeedback.mediumImpact();
      setState(() {
        _currentIndex++;
        _currentCount = _items[_currentIndex].count;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      HapticFeedback.mediumImpact();
      setState(() {
        _currentIndex--;
        _currentCount = _items[_currentIndex].count;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _decrementCount() {
    if (_currentCount > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentCount--;
      });
      if (_currentCount == 0) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 300), _next);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return JiraScreen(
      child: _isLoading
          ? Center(child: CircularProgressIndicator(color: tp.primaryAccent))
          : Column(
              children: [
                _buildAppBar(context, tp),
                _buildProgressBar(tp),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _buildItemView(item, tp);
                    },
                  ),
                ),
                _buildBottomControls(tp),
              ],
            ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeProvider tp) {
    return JiraHeader(
      title: 'Ratib al-Haddad',
      subtitle: 'VERSE ${_currentIndex + 1} OF ${_items.length}',
      actions: [
        HeartbeatTap(
          onTap: _showAboutDialog,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tp.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tp.borderColor, width: 1.0),
            ),
            child: Center(
              child: Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: tp.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAboutDialog() {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tp.containerColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tp.primaryAccent.withValues(alpha: 0.1)),
        ),
        title: Text(
          'About Ratib al-Haddad',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: tp.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            'The Ratib al-Haddad is a famous collection of prayers and supplications compiled by Imam al-Habib Abdullah bin Alawi al-Haddad. It is traditionally recited after the Isha prayer for protection, spiritual elevation, and divine blessings.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: tp.textSecondary,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'DISMISS',
              style: GoogleFonts.outfit(
                color: tp.primaryAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ThemeProvider tp) {
    double progress = _items.isEmpty ? 0 : (_currentIndex + 1) / _items.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Stack(
        children: [
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: tp.borderColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(
                  color: tp.primaryAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemView(HaddadItem item, ThemeProvider tp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: tp.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tp.primaryAccent.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  item.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'HafsFont',
                    fontSize: 26,
                    height: 2.0,
                    color: tp.primaryAccent,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 1,
                  width: 60,
                  color: tp.primaryAccent.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 24),
                Text(
                  item.translation,
                  textAlign: TextAlign.center,
                  // Outfit ships no italic; Inter italic matches the other
                  // translation lines in the app.
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: tp.textSecondary,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (item.count > 1)
            HeartbeatTap(
              onTap: _decrementCount,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tp.surfaceColor,
                  border: Border.all(
                    color: tp.primaryAccent.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 114,
                      height: 114,
                      child: CircularProgressIndicator(
                        value: _currentCount / item.count,
                        strokeWidth: 4,
                        backgroundColor: tp.borderColor.withValues(alpha: 0.4),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          tp.primaryAccent,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentCount.toString(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 36,
                            fontWeight: FontWeight.w200,
                            color: tp.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'OF ${item.count}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tp.textSecondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 130),
        ],
      ),
    );
  }

  Widget _buildBottomControls(ThemeProvider tp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(
            icon: Icons.arrow_back_rounded,
            onPressed: _currentIndex > 0 ? _previous : null,
            enabled: _currentIndex > 0,
            tp: tp,
          ),
          _buildMainActionButton(tp),
          _buildNavButton(
            icon: Icons.arrow_forward_rounded,
            onPressed: _currentIndex < _items.length - 1 ? _next : null,
            enabled: _currentIndex < _items.length - 1,
            tp: tp,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool enabled,
    required ThemeProvider tp,
  }) {
    return HeartbeatTap(
      onTap: onPressed ?? () {},
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? tp.surfaceColor : tp.containerColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? tp.borderColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 18,
            color: enabled ? tp.textPrimary : tp.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionButton(ThemeProvider tp) {
    bool isLast = _currentIndex == _items.length - 1;
    bool needsCount =
        _items.isNotEmpty &&
        _items[_currentIndex].count > 1 &&
        _currentCount > 0;

    return HeartbeatTap(
      onTap: needsCount
          ? _decrementCount
          : (isLast ? () => Navigator.pop(context) : _next),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        decoration: BoxDecoration(
          color: tp.primaryAccent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          needsCount ? 'TAP TO COUNT' : (isLast ? 'FINISH' : 'NEXT'),
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: tp.backgroundBottom,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
