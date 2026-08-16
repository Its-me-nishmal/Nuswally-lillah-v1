import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/jira_theme.dart';
import '../widgets/heartbeat_tap.dart';

class DhikrPhrase {
  final String id;
  final String arabic;
  final String transliteration;
  final String translation;
  final int defaultTarget;
  final bool isCustom;

  const DhikrPhrase({
    this.id = '',
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.defaultTarget,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'arabic': arabic,
        'transliteration': transliteration,
        'translation': translation,
        'defaultTarget': defaultTarget,
        'isCustom': isCustom,
      };

  factory DhikrPhrase.fromJson(Map<String, dynamic> json) => DhikrPhrase(
        id: (json['id'] ?? '').toString(),
        arabic: (json['arabic'] ?? '').toString(),
        transliteration: (json['transliteration'] ?? '').toString(),
        translation: (json['translation'] ?? '').toString(),
        defaultTarget: (json['defaultTarget'] as num?)?.toInt() ?? 33,
        isCustom: json['isCustom'] == true,
      );
}

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  static const String _spTipSeenKey = 'has_seen_tasbeeh_tip';
  static const String _spCustomDhikrKey = 'custom_tasbeeh_phrases_json';

  int _counter = 0;
  int _target = 33; // 33, 99, 100, custom, or 0 for infinity
  int _totalToday = 0;
  int _currentLap = 1;
  int _streakDays = 7;
  bool _hapticEnabled = true;
  bool _soundEnabled = true;
  int _selectedPhraseIndex = 0;

  final List<DhikrPhrase> _defaultPhrases = const [
    DhikrPhrase(
      id: 'subhanallah',
      arabic: 'سُبْحَانَ اللَّهِ',
      transliteration: 'SubhanAllah',
      translation: 'Glory be to Allah',
      defaultTarget: 33,
    ),
    DhikrPhrase(
      id: 'alhamdulillah',
      arabic: 'الْحَمْدُ لِلَّهِ',
      transliteration: 'Alhamdulillah',
      translation: 'Praise be to Allah',
      defaultTarget: 33,
    ),
    DhikrPhrase(
      id: 'allahuakbar',
      arabic: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allahu Akbar',
      translation: 'Allah is the Greatest',
      defaultTarget: 34,
    ),
    DhikrPhrase(
      id: 'astaghfirullah',
      arabic: 'أَسْتَغْفِرُ اللَّهَ',
      transliteration: 'Astaghfirullah',
      translation: 'I seek forgiveness from Allah',
      defaultTarget: 100,
    ),
    DhikrPhrase(
      id: 'lailahaillallah',
      arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ',
      transliteration: 'La ilaha illallah',
      translation: 'There is no deity but Allah',
      defaultTarget: 100,
    ),
    DhikrPhrase(
      id: 'salawat',
      arabic: 'اللَّهُمَّ صَلِّ عَلَىٰ سَيِّدِنَا مُحَمَّدٍ',
      transliteration: 'Allahumma Salli Ala Sayyidina Muhammad',
      translation: 'O Allah, send blessings upon our Master Muhammad',
      defaultTarget: 100,
    ),
    DhikrPhrase(
      id: 'subhanallahi_bihamdihi',
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      transliteration: 'SubhanAllahi wa bihamdihi',
      translation: 'Glory be to Allah and His praise',
      defaultTarget: 100,
    ),
    DhikrPhrase(
      id: 'hasbunallah',
      arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      transliteration: "HasbunAllahu wa ni'mal wakeel",
      translation: 'Allah is sufficient for us',
      defaultTarget: 100,
    ),
  ];

  List<DhikrPhrase> _allPhrases = [];

  @override
  void initState() {
    super.initState();
    _allPhrases = List.from(_defaultPhrases);
    _loadTasbeehData();
  }

  Future<void> _loadTasbeehData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load custom phrases
    final customRaw = prefs.getString(_spCustomDhikrKey);
    final List<DhikrPhrase> customPhrases = [];
    if (customRaw != null && customRaw.isNotEmpty) {
      try {
        final decoded = json.decode(customRaw) as List<dynamic>;
        customPhrases.addAll(
            decoded.map((e) => DhikrPhrase.fromJson(e as Map<String, dynamic>)));
      } catch (e) {
        debugPrint('Error loading custom tasbeeh: $e');
      }
    }

    final hasSeenTip = prefs.getBool(_spTipSeenKey) ?? false;

    if (mounted) {
      setState(() {
        _allPhrases = [..._defaultPhrases, ...customPhrases];
        _counter = prefs.getInt('tasbeeh_counter') ?? 0;
        _target = prefs.getInt('tasbeeh_target') ?? 33;
        _totalToday = prefs.getInt('tasbeeh_total_today') ?? 165;
        _currentLap = prefs.getInt('tasbeeh_current_lap') ?? 1;
        _streakDays = prefs.getInt('tasbeeh_streak_days') ?? 7;
        _hapticEnabled = prefs.getBool('tasbeeh_haptic') ?? true;
        _soundEnabled = prefs.getBool('tasbeeh_sound') ?? true;
        _selectedPhraseIndex = (prefs.getInt('tasbeeh_phrase_idx') ?? 0)
            .clamp(0, _allPhrases.length - 1);
      });

      // Show tip automatically on first opening
      if (!hasSeenTip) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showTasbeehTipDialog(context, autoOpened: true);
          }
        });
      }
    }
  }

  Future<void> _saveTasbeehData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbeeh_counter', _counter);
    await prefs.setInt('tasbeeh_target', _target);
    await prefs.setInt('tasbeeh_total_today', _totalToday);
    await prefs.setInt('tasbeeh_current_lap', _currentLap);
    await prefs.setBool('tasbeeh_haptic', _hapticEnabled);
    await prefs.setBool('tasbeeh_sound', _soundEnabled);
    await prefs.setInt('tasbeeh_phrase_idx', _selectedPhraseIndex);

    // Save custom phrases
    final customPhrases = _allPhrases.where((p) => p.isCustom).toList();
    final customJson = json.encode(customPhrases.map((e) => e.toJson()).toList());
    await prefs.setString(_spCustomDhikrKey, customJson);
  }

  void _onIncrement() {
    if (_soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }

    setState(() {
      _counter++;
      _totalToday++;

      if (_target > 0) {
        if (_counter >= _target) {
          _counter = 0;
          _currentLap++;
          if (_hapticEnabled) {
            HapticFeedback.heavyImpact();
          }
        }
      }
    });

    _saveTasbeehData();
  }

  void _onReset() {
    if (_hapticEnabled) {
      HapticFeedback.mediumImpact();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF30363D)),
        ),
        title: Text(
          'Reset Counter',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800, color: const Color(0xFFF0F6FC)),
        ),
        content: Text(
          'Reset current Dhikr count and lap back to 0?',
          style:
              GoogleFonts.inter(color: const Color(0xFF8B949E), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                  color: const Color(0xFF8B949E), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _counter = 0;
                _currentLap = 1;
              });
              _saveTasbeehData();
              if (_hapticEnabled) {
                HapticFeedback.heavyImpact();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomDhikrDialog(BuildContext context) {
    HapticFeedback.selectionClick();
    final arabicCtrl = TextEditingController();
    final transliterationCtrl = TextEditingController();
    final translationCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '100');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
            decoration: const BoxDecoration(
              color: Color(0xFF161B22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: Color(0xFF30363D), width: 1),
                left: BorderSide(color: Color(0xFF30363D), width: 1),
                right: BorderSide(color: Color(0xFF30363D), width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF484F58),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'Add Custom Dhikr / Dua',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF0F6FC),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Personalize your digital Tasbeeh with your favorite Adhkaar',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF8B949E),
                  ),
                ),
                const SizedBox(height: 16),

                // Arabic Input
                _buildInputField(
                  controller: arabicCtrl,
                  label: 'Arabic Text (Optional)',
                  hint: 'e.g. يَا حَيُّ يَا قَيُّومُ',
                  isArabic: true,
                ),
                const SizedBox(height: 12),

                // Transliteration
                _buildInputField(
                  controller: transliterationCtrl,
                  label: 'Transliteration / Name',
                  hint: 'e.g. Ya Hayyu Ya Qayyum',
                ),
                const SizedBox(height: 12),

                // Meaning
                _buildInputField(
                  controller: translationCtrl,
                  label: 'Meaning / Translation',
                  hint: 'e.g. O Ever-Living, O Sustainer',
                ),
                const SizedBox(height: 12),

                // Target
                _buildInputField(
                  controller: targetCtrl,
                  label: 'Target Count (0 for ∞ unlimited)',
                  hint: 'e.g. 100',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 22),

                // Save Button
                HeartbeatTap(
                  onTap: () {
                    final name = transliterationCtrl.text.trim();
                    if (name.isEmpty) return;

                    final targetVal = int.tryParse(targetCtrl.text.trim()) ?? 100;
                    final newPhrase = DhikrPhrase(
                      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      arabic: arabicCtrl.text.trim().isNotEmpty
                          ? arabicCtrl.text.trim()
                          : name,
                      transliteration: name,
                      translation: translationCtrl.text.trim(),
                      defaultTarget: targetVal,
                      isCustom: true,
                    );

                    setState(() {
                      _allPhrases.add(newPhrase);
                      _selectedPhraseIndex = _allPhrases.length - 1;
                      _target = targetVal;
                      _counter = 0;
                      _currentLap = 1;
                    });

                    _saveTasbeehData();
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: JiraTheme.secondaryGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'Save & Select Dhikr',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isArabic = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFC9D1D9),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D121D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: isArabic
                ? const TextStyle(
                    fontFamily: 'HafsFont',
                    fontSize: 16,
                    color: Color(0xFFF0F6FC),
                  )
                : GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFF0F6FC),
                  ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF64748B)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
      ],
    );
  }

  void _showTasbeehTipDialog(BuildContext context, {bool autoOpened = false}) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFF30363D), width: 1),
              left: BorderSide(color: Color(0xFF30363D), width: 1),
              right: BorderSide(color: Color(0xFF30363D), width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF484F58),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Glowing Orb Emblem
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: JiraTheme.secondaryGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: JiraTheme.secondaryGreen.withValues(alpha: 0.4),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.fingerprint_rounded,
                    color: JiraTheme.secondaryGreen,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Tasbeeh & Dhikr Guide',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF0F6FC),
                ),
              ),
              const SizedBox(height: 8),

              // Hadith Quote
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D121D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'أَحَبُّ الْكَلَامِ إِلَى اللَّهِ أَرْبَعٌ: سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'HafsFont',
                        fontSize: 15.5,
                        color: Color(0xFF93C5FD),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '“The dearest words to Allah are four: SubhanAllah, Alhamdulillah, La ilaha illallah, and Allahu Akbar.”',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFFC9D1D9),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '— Sahih Muslim 2137',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8B949E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Feature Highlights
              _buildTipRow(
                icon: Icons.touch_app_rounded,
                iconColor: const Color(0xFF60A5FA),
                title: 'Haptic Counting',
                subtitle:
                    'Tap anywhere on the giant glowing orb to count with tactile vibration feedback.',
              ),
              const SizedBox(height: 10),

              _buildTipRow(
                icon: Icons.add_circle_outline_rounded,
                iconColor: JiraTheme.secondaryGreen,
                title: 'Custom Dhikr & Salawat',
                subtitle:
                    'Tap the “+ Custom” pill to add your own prayers with customized target counts.',
              ),
              const SizedBox(height: 10),

              _buildTipRow(
                icon: Icons.track_changes_rounded,
                iconColor: const Color(0xFFFBBF24),
                title: 'Targets & Infinity Mode (∞)',
                subtitle:
                    'Switch between 33, 99, 100, or unlimited count (∞) using the quick selector bar.',
              ),
              const SizedBox(height: 22),

              // Action Button
              HeartbeatTap(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(_spTipSeenKey, true);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: JiraTheme.secondaryGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Got It • Begin Tasbeeh',
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF0F6FC),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF8B949E),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPhrase = _selectedPhraseIndex < _allPhrases.length
        ? _allPhrases[_selectedPhraseIndex]
        : _allPhrases.first;

    final progress = _target > 0 ? (_counter / _target).clamp(0.0, 1.0) : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: Stack(
        children: [
          // 1. Ambient Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0B0E14),
                  Color(0xFF0D121D),
                  Color(0xFF070A10),
                ],
              ),
            ),
          ),

          // 2. Central Soft Ambient Radial Aura
          Positioned(
            top: MediaQuery.of(context).size.height * 0.38,
            left: -30,
            right: -30,
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    JiraTheme.secondaryGreen.withValues(alpha: 0.09),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Main Minimalist Screen Layout
          SafeArea(
            child: Column(
              children: [
                // Minimal Top Bar
                _buildTopBar(),

                const SizedBox(height: 6),

                // Horizontal Dhikr Selector Pills + Add Custom Button
                _buildDhikrSelectorPills(),

                const Spacer(flex: 2),

                // Active Dhikr Calligraphy & Details
                _buildActiveDhikrHeader(currentPhrase),

                const Spacer(flex: 3),

                // Hero Centerpiece: Circular Counter Orb with Heartbeat Pulse
                _buildCounterOrb(progress),

                const Spacer(flex: 4),

                // Sleek Quick Controls Row (Reset, Target Segment, Lap)
                _buildQuickControls(),

                const SizedBox(height: 14),

                // Minimalist Bottom Stats Subtitle
                _buildMinimalBottomStats(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Minimal Top Bar
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Circular Back Button
          HeartbeatTap(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: Color(0xFFF0F6FC),
                ),
              ),
            ),
          ),

          // Center Title with Green Glowing Orb Indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: JiraTheme.secondaryGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: JiraTheme.secondaryGreen.withValues(alpha: 0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'DIGITAL TASBEEH',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF0F6FC),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          // Right Controls Cluster (Tip Bulb, Sound & Vibration toggles)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tip Button
              HeartbeatTap(
                onTap: () => _showTasbeehTipDialog(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Sound Toggle
              HeartbeatTap(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _soundEnabled = !_soundEnabled);
                  _saveTasbeehData();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: Center(
                    child: Icon(
                      _soundEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      size: 16,
                      color: _soundEnabled
                          ? const Color(0xFFF0F6FC)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Vibration Toggle
              HeartbeatTap(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _hapticEnabled = !_hapticEnabled);
                  _saveTasbeehData();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.vibration_rounded,
                      size: 16,
                      color: _hapticEnabled
                          ? JiraTheme.secondaryGreen
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Horizontal Dhikr Selector Pills with "+ Custom" Button
  Widget _buildDhikrSelectorPills() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _allPhrases.length + 1, // Extra + 1 for Add button
        itemBuilder: (context, index) {
          // Add Custom Dhikr Button
          if (index == _allPhrases.length) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: HeartbeatTap(
                onTap: () => _showAddCustomDhikrDialog(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: JiraTheme.secondaryGreen.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: JiraTheme.secondaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Custom',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: JiraTheme.secondaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final phrase = _allPhrases[index];
          final isSelected = _selectedPhraseIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: HeartbeatTap(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedPhraseIndex = index;
                  _target = phrase.defaultTarget;
                  _counter = 0;
                  _currentLap = 1;
                });
                _saveTasbeehData();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFA4C6FB)
                      : const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFA4C6FB)
                        : const Color(0xFF30363D),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    phrase.defaultTarget > 0
                        ? '${phrase.transliteration} (${phrase.defaultTarget})'
                        : phrase.transliteration,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF0B0E14)
                          : const Color(0xFFF0F6FC),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Active Dhikr Calligraphy Header
  Widget _buildActiveDhikrHeader(DhikrPhrase phrase) {
    final targetLabel = _target == 0 ? '∞' : '$_target';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sacred Arabic Calligraphy
          Text(
            phrase.arabic,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'HafsFont',
              fontSize: 30,
              fontWeight: FontWeight.normal,
              color: Color(0xFFC7D2FE),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),

          // Transliteration
          Text(
            phrase.transliteration,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (phrase.translation.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              phrase.translation,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8B949E),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Minimalist Status Subtitle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Text(
              'Lap $_currentLap  •  Target $targetLabel  •  Total $_totalToday',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8B949E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hero Counter Orb (250px with HeartbeatTap pulse)
  Widget _buildCounterOrb(double progress) {
    return HeartbeatTap(
      onTap: _onIncrement,
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF30363D),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: JiraTheme.secondaryGreen.withValues(alpha: 0.15),
              blurRadius: 32,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular Progress Ring
            CustomPaint(
              size: const Size(250, 250),
              painter: _TasbeehProgressRingPainter(
                progress: progress,
                strokeWidth: 6.0,
                trackColor: const Color(0xFF1E293B).withValues(alpha: 0.5),
                progressColor: JiraTheme.secondaryGreen,
              ),
            ),

            // Giant Number & Subtitle
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_counter',
                  style: GoogleFonts.outfit(
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'TAP TO COUNT',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF8B949E),
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Minimalist Quick Controls Strip
  Widget _buildQuickControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Reset Button
          HeartbeatTap(
            onTap: _onReset,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: const Center(
                child: Icon(
                  Icons.restart_alt_rounded,
                  size: 20,
                  color: Color(0xFFF0F6FC),
                ),
              ),
            ),
          ),

          // Center Target Segment Switcher
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTargetSegment(33, '33'),
                _buildTargetSegment(99, '99'),
                _buildTargetSegment(100, '100'),
                _buildTargetSegment(0, '∞'),
              ],
            ),
          ),

          // Right Lap Flag Button
          HeartbeatTap(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _counter = 0;
                _currentLap++;
              });
              _saveTasbeehData();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: const Center(
                child: Icon(
                  Icons.outlined_flag_rounded,
                  size: 20,
                  color: Color(0xFFF0F6FC),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSegment(int value, String label) {
    final isSelected = _target == value;

    return HeartbeatTap(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _target = value;
          _counter = 0;
        });
        _saveTasbeehData();
      },
      child: Container(
        width: 38,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? JiraTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF8B949E),
            ),
          ),
        ),
      ),
    );
  }

  // Minimal Bottom Stats
  Widget _buildMinimalBottomStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.local_fire_department_rounded,
            size: 14, color: JiraTheme.secondaryGreen),
        const SizedBox(width: 4),
        Text(
          '$_totalToday / 500 Daily Goal',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8B949E),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
            color: Color(0xFF30363D),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$_streakDays Day Streak 🔥',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF93C5FD),
          ),
        ),
      ],
    );
  }
}

// Custom Painter for the Smooth Circular Progress Ring with Glowing Tip Dot
class _TasbeehProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  _TasbeehProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

    // Foreground progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Tip Glowing Dot
    final endAngle = -math.pi / 2 + sweepAngle;
    final dotCenter = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );

    final dotGlowPaint = Paint()
      ..color = progressColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(dotCenter, 5, dotGlowPaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _TasbeehProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
