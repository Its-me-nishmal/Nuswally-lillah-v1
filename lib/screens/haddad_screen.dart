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
    return Scaffold(
      backgroundColor: const Color(0xFF051424),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFF082038),
              Color(0xFF051424),
            ],
            radius: 1.3,
            center: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF5EEAD4)))
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
    final activeColor = const Color(0xFF5EEAD4);
    final normalColor = const Color(0xFFD4E4FA);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
          Column(
            children: [
              Text(
                'Ratib al-Haddad',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'VERSE ${_currentIndex + 1} OF ${_items.length}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: activeColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF122131),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: activeColor.withValues(alpha: 0.1)),
                  ),
                  title: Text(
                    'About Ratib al-Haddad',
                    style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.bold,
                      color: normalColor,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Text(
                      'The Ratib al-Haddad is a famous collection of prayers and supplications compiled by Imam al-Habib Abdullah bin Alawi al-Haddad. It is traditionally recited after the Isha prayer for protection, spiritual elevation, and divine blessings.',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        color: normalColor.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'DISMISS',
                        style: GoogleFonts.hankenGrotesk(
                          color: activeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    double progress = _items.isEmpty ? 0 : (_currentIndex + 1) / _items.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Stack(
        children: [
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            width: MediaQuery.of(context).size.width * progress - 48,
            decoration: BoxDecoration(
              color: const Color(0xFF5EEAD4),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5EEAD4).withValues(alpha: 0.3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemView(HaddadItem item) {
    final activeColor = const Color(0xFF5EEAD4);
    final normalColor = const Color(0xFFD4E4FA);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF122131),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: activeColor.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
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
                    fontSize: 26,
                    height: 2.0,
                    color: Color(0xFF5EEAD4),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 1,
                  width: 60,
                  color: activeColor.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 24),
                Text(
                  item.translation,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    color: normalColor.withValues(alpha: 0.7),
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (item.count > 1)
            GestureDetector(
              onTap: _decrementCount,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0C1D2F).withValues(alpha: 0.6),
                  border: Border.all(color: activeColor.withValues(alpha: 0.08), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.04),
                      blurRadius: 20,
                    ),
                  ],
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
                        backgroundColor: Colors.white.withValues(alpha: 0.02),
                        valueColor: AlwaysStoppedAnimation<Color>(activeColor),
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
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'OF ${item.count}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: activeColor.withValues(alpha: 0.5),
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

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
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
    final activeColor = const Color(0xFF5EEAD4);
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF122131) : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: enabled ? activeColor.withValues(alpha: 0.08) : Colors.transparent,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.15)),
      ),
    );
  }

  Widget _buildMainActionButton() {
    final activeColor = const Color(0xFF5EEAD4);
    bool isLast = _currentIndex == _items.length - 1;
    bool needsCount = _items.isNotEmpty && _items[_currentIndex].count > 1 && _currentCount > 0;

    return GestureDetector(
      onTap: needsCount ? _decrementCount : (isLast ? () => Navigator.pop(context) : _next),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF144F4B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activeColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          needsCount ? 'TAP TO COUNT' : (isLast ? 'FINISH' : 'NEXT'),
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
