import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/haddad_item.dart';

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
      final String response = await rootBundle.loadString('assets/data/haddad.json');
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
    final colorScheme = Theme.of(context).colorScheme;

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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildAppBar(context),
                    _buildProgressBar(),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return _buildItemView(item);
                        },
                      ),
                    ),
                    _buildBottomControls(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary),
          ),
          Column(
            children: [
              Text(
                'Ratib al-Haddad',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                '${_currentIndex + 1} / ${_items.length}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              // Show info or settings
            },
            icon: Icon(Icons.info_outline_rounded, color: colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final colorScheme = Theme.of(context).colorScheme;
    double progress = _items.isEmpty ? 0 : (_currentIndex + 1) / _items.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Stack(
        children: [
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 6,
            width: MediaQuery.of(context).size.width * progress,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemView(HaddadItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  item.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: 'HafsFont',
                    fontSize: 28,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.1),
                        colorScheme.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    height: 2,
                    width: 50,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  item.translation,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          if (item.count > 1)
            GestureDetector(
              onTap: _decrementCount,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _currentCount / item.count,
                      strokeWidth: 8,
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _currentCount.toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        'REMAINING',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: colorScheme.primary.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
             const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(
            icon: Icons.arrow_back_rounded,
            onPressed: _currentIndex > 0 ? _previous : null,
            enabled: _currentIndex > 0,
          ),
          _buildMainActionButton(),
          _buildNavButton(
            icon: Icons.arrow_forward_rounded,
            onPressed: _currentIndex < _items.length - 1 ? _next : null,
            enabled: _currentIndex < _items.length - 1,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback? onPressed, required bool enabled}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: enabled ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: enabled ? colorScheme.primary : Colors.grey.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildMainActionButton() {
    final colorScheme = Theme.of(context).colorScheme;
    bool isLast = _currentIndex == _items.length - 1;
    bool needsCount = _items.isNotEmpty && _items[_currentIndex].count > 1 && _currentCount > 0;

    return GestureDetector(
      onTap: needsCount ? _decrementCount : (isLast ? () => Navigator.pop(context) : _next),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          needsCount ? 'TAP TO COUNT' : (isLast ? 'FINISH' : 'NEXT'),
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
