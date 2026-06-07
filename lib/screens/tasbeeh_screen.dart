import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class DhikrPhrase {
  final String arabic;
  final String english;
  final int defaultTarget;

  const DhikrPhrase({
    required this.arabic,
    required this.english,
    required this.defaultTarget,
  });
}

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> with SingleTickerProviderStateMixin {
  int _counter = 0;
  int _target = 33;
  int _totalCount = 0;
  bool _hapticEnabled = true;
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  final List<DhikrPhrase> _phrases = const [
    DhikrPhrase(arabic: 'سُبْحَانَ ٱللَّٰهِ', english: 'Subhanallah', defaultTarget: 33),
    DhikrPhrase(arabic: 'ٱلْحَمْدُ لِلَّٰهِ', english: 'Alhamdulillah', defaultTarget: 33),
    DhikrPhrase(arabic: 'ٱللَّٰهُ أَكْبَرُ', english: 'Allahu Akbar', defaultTarget: 33),
    DhikrPhrase(arabic: 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ', english: 'La ilaha illallah', defaultTarget: 100),
  ];
  
  int _selectedPhraseIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _loadTasbeehData();
  }

  Future<void> _loadTasbeehData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt('tasbeeh_counter') ?? 0;
      _target = prefs.getInt('tasbeeh_target') ?? 33;
      _totalCount = prefs.getInt('tasbeeh_total_count') ?? 0;
      _hapticEnabled = prefs.getBool('tasbeeh_haptic') ?? true;
      _selectedPhraseIndex = prefs.getInt('tasbeeh_phrase_idx') ?? 0;
    });
  }

  Future<void> _saveTasbeehData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbeeh_counter', _counter);
    await prefs.setInt('tasbeeh_target', _target);
    await prefs.setInt('tasbeeh_total_count', _totalCount);
    await prefs.setBool('tasbeeh_haptic', _hapticEnabled);
    await prefs.setInt('tasbeeh_phrase_idx', _selectedPhraseIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _increment() {
    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }
    _controller.forward().then((_) => _controller.reverse());
    setState(() {
      _counter++;
      _totalCount++;
      if (_counter > _target) {
        _counter = 1;
        if (_hapticEnabled) {
          HapticFeedback.heavyImpact();
        }
      } else if (_counter == _target) {
        if (_hapticEnabled) {
          HapticFeedback.mediumImpact();
        }
      }
    });
    _saveTasbeehData();
  }

  void _reset() {
    if (_hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.containerColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: themeProvider.primaryAccent.withValues(alpha: 0.1)),
        ),
        title: Text(
          'Reset Counter',
          style: GoogleFonts.hankenGrotesk(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to reset the current count?',
          style: GoogleFonts.hankenGrotesk(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.hankenGrotesk(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _counter = 0);
              _saveTasbeehData();
              Navigator.pop(context);
            },
            child: Text(
              'RESET',
              style: GoogleFonts.hankenGrotesk(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _changeTarget(int newTarget) {
    setState(() {
      _target = newTarget;
      _counter = 0;
    });
    _saveTasbeehData();
    if (_hapticEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _selectPhrase(int idx) {
    setState(() {
      _selectedPhraseIndex = idx;
      _target = _phrases[idx].defaultTarget;
      _counter = 0;
    });
    _saveTasbeehData();
    if (_hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePhrase = _phrases[_selectedPhraseIndex];
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundBottom,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              themeProvider.backgroundTop,
              themeProvider.backgroundBottom,
            ],
            radius: 1.3,
            center: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, themeProvider),
              const SizedBox(height: 12),
              
              // Preset phrases picker row
              _buildPhrasesPicker(themeProvider),
              
              const Spacer(),
              
              // Meditative Active Phrase display
              Column(
                children: [
                  Text(
                    activePhrase.arabic,
                    style: GoogleFonts.amiri(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.primaryAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activePhrase.english.toUpperCase(),
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Target selections
              _buildTargetSelector(themeProvider),
              
              const Spacer(),
              
              // Central counter ring
              _buildMainCounterRing(themeProvider),
              
              const Spacer(),
              
              // Footer stats
              _buildStatsBar(themeProvider),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
          Text(
            'TASBIH COUNTER',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _hapticEnabled = !_hapticEnabled;
                  });
                  _saveTasbeehData();
                  HapticFeedback.lightImpact();
                },
                icon: Icon(
                  _hapticEnabled ? Icons.vibration_rounded : Icons.phone_android_rounded,
                  color: _hapticEnabled ? themeProvider.primaryAccent : Colors.white.withValues(alpha: 0.3),
                ),
                tooltip: 'Toggle Haptic Feedback',
              ),
              IconButton(
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Reset Count',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhrasesPicker(ThemeProvider themeProvider) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _phrases.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedPhraseIndex;
          return GestureDetector(
            onTap: () => _selectPhrase(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? themeProvider.continueReadingBg.withValues(alpha: 0.4) : themeProvider.containerColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? themeProvider.primaryAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.04),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _phrases[index].english,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTargetSelector(ThemeProvider themeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [33, 99, 100, 1000].map((t) {
        bool isSelected = _target == t;
        return GestureDetector(
          onTap: () => _changeTarget(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? themeProvider.primaryAccent.withValues(alpha: 0.15) : themeProvider.containerColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? themeProvider.primaryAccent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.04),
              ),
            ),
            child: Text(
              t.toString(),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? themeProvider.primaryAccent : Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMainCounterRing(ThemeProvider themeProvider) {
    final progress = _target > 0 ? (_counter / _target).clamp(0.0, 1.0) : 0.0;
    
    return GestureDetector(
      onTap: _increment,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeProvider.containerColor.withValues(alpha: 0.6),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.primaryAccent.withValues(alpha: 0.08 + (_glowAnimation.value * 0.06)),
                    blurRadius: 30 + (_glowAnimation.value * 10),
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(
                  color: themeProvider.primaryAccent.withValues(alpha: 0.08),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sleek dual-colored visual ring tracker
                  SizedBox(
                    width: 248,
                    height: 248,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.03),
                      valueColor: AlwaysStoppedAnimation<Color>(themeProvider.primaryAccent),
                    ),
                  ),
                  
                  // Concentric internal line circle
                  Container(
                    width: 228,
                    height: 228,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.02), width: 1),
                    ),
                  ),
                  
                  // Text elements inside
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _counter.toString(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 76,
                          fontWeight: FontWeight.w100,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeProvider.primaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'GOAL: $_target',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.primaryAccent,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsBar(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: themeProvider.containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMPLETED LOOPS',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (_totalCount ~/ _target).toString(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TOTAL DHIKR TODAY',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _totalCount.toString(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.primaryAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
