import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
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
  int _target = 33;
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
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final lastDateStr = prefs.getString('tasbeeh_last_active_date');
    int savedStreak = prefs.getInt('tasbeeh_streak_days') ?? 1;
    int todayTotal = prefs.getInt('tasbeeh_total_today') ?? 0;

    if (lastDateStr == null) {
      savedStreak = 1;
      todayTotal = 0;
    } else if (lastDateStr == todayStr) {
      // Same day, keep current counts
    } else {
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null) {
        final diffDays = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;
        if (diffDays == 1) {
          savedStreak += 1;
        } else if (diffDays > 1) {
          savedStreak = 1;
        }
      } else {
        savedStreak = 1;
      }
      todayTotal = 0;
    }

    setState(() {
      _counter = prefs.getInt('tasbeeh_current_counter') ?? 0;
      _target = prefs.getInt('tasbeeh_current_target') ?? 33;
      _totalToday = todayTotal;
      _streakDays = savedStreak;
      _currentLap = prefs.getInt('tasbeeh_current_lap') ?? 1;
      _hapticEnabled = prefs.getBool('tasbeeh_haptic_enabled') ?? true;
      _soundEnabled = prefs.getBool('tasbeeh_sound_enabled') ?? true;
      _selectedPhraseIndex = prefs.getInt('tasbeeh_selected_phrase_idx') ?? 0;

      final customJson = prefs.getString(_spCustomDhikrKey);
      if (customJson != null && customJson.isNotEmpty) {
        try {
          final List decoded = jsonDecode(customJson);
          final customList = decoded.map((e) => DhikrPhrase.fromJson(e)).toList();
          _allPhrases = [..._defaultPhrases, ...customList];
        } catch (_) {}
      }

      if (_selectedPhraseIndex >= _allPhrases.length) {
        _selectedPhraseIndex = 0;
      }
    });

    final hasSeenTip = prefs.getBool(_spTipSeenKey) ?? false;
    if (!hasSeenTip && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTasbeehTipDialog(context);
      });
    }
  }

  Future<void> _saveTasbeehData() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await prefs.setString('tasbeeh_last_active_date', todayStr);
    await prefs.setInt('tasbeeh_streak_days', _streakDays);
    await prefs.setInt('tasbeeh_current_counter', _counter);
    await prefs.setInt('tasbeeh_current_target', _target);
    await prefs.setInt('tasbeeh_total_today', _totalToday);
    await prefs.setInt('tasbeeh_current_lap', _currentLap);
    await prefs.setBool('tasbeeh_haptic_enabled', _hapticEnabled);
    await prefs.setBool('tasbeeh_sound_enabled', _soundEnabled);
    await prefs.setInt('tasbeeh_selected_phrase_idx', _selectedPhraseIndex);

    final customPhrases = _allPhrases.where((p) => p.isCustom).toList();
    if (customPhrases.isNotEmpty) {
      final jsonStr = jsonEncode(customPhrases.map((e) => e.toJson()).toList());
      await prefs.setString(_spCustomDhikrKey, jsonStr);
    }
  }

  void _onIncrement() {
    if (_soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }

    setState(() {
      _counter++;
      _totalToday++;

      if (_target > 0 && _counter >= _target) {
        if (_hapticEnabled) {
          HapticFeedback.heavyImpact();
        }
        _counter = 0;
        _currentLap++;
      } else {
        if (_hapticEnabled) {
          HapticFeedback.lightImpact();
        }
      }
    });

    _saveTasbeehData();
  }

  void _onReset() {
    HapticFeedback.selectionClick();
    final tp = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tp.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tp.borderColor, width: 0.8),
        ),
        title: Text(
          'Reset Counter?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: tp.textPrimary,
          ),
        ),
        content: Text(
          'Do you want to reset the current count to 0? Your daily total will be preserved.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: tp.textSecondary,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: tp.textSecondary,
                fontWeight: FontWeight.w600,
              ),
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
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // Set Custom Goal & Starting Counter Value Dialog
  void _showSetCustomGoalAndCountDialog(BuildContext context, ThemeProvider tp) {
    HapticFeedback.selectionClick();
    final targetCtrl = TextEditingController(text: _target.toString());
    final countCtrl = TextEditingController(text: _counter.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              22,
              14,
              22,
              math.max(MediaQuery.paddingOf(ctx).bottom + 22.0, 40.0),
            ),
            decoration: BoxDecoration(
              color: tp.surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: tp.borderColor, width: 0.8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tp.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Icon(Icons.tune_rounded, color: tp.primaryAccent, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Custom Goal & Starting Count',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: tp.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Set any target (e.g. 167, 313, 1000) or resume from an existing count.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: tp.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Target Input Field
                _buildInputField(
                  controller: targetCtrl,
                  label: 'Target / Goal (Enter 0 for ∞ unlimited)',
                  hint: 'e.g. 167',
                  keyboardType: TextInputType.number,
                  tp: tp,
                ),
                const SizedBox(height: 12),

                // Starting Count Field
                _buildInputField(
                  controller: countCtrl,
                  label: 'Current Starting Count',
                  hint: 'e.g. 0 or 167',
                  keyboardType: TextInputType.number,
                  tp: tp,
                ),
                const SizedBox(height: 16),

                // Quick Presets Chips
                Text(
                  'Quick Presets:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tp.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [33, 99, 100, 167, 313, 500, 1000, 0].map((val) {
                    final label = val == 0 ? '∞ Unlimited' : '$val';
                    return HeartbeatTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        targetCtrl.text = val.toString();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: tp.containerColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: tp.borderColor, width: 0.8),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: tp.primaryAccent,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),

                // Save Action Button
                HeartbeatTap(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final newTarget = int.tryParse(targetCtrl.text.trim()) ?? 33;
                    final newCount = int.tryParse(countCtrl.text.trim()) ?? 0;

                    setState(() {
                      _target = newTarget < 0 ? 0 : newTarget;
                      _counter = newCount < 0 ? 0 : newCount;
                    });
                    _saveTasbeehData();
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: tp.primaryAccent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: tp.primaryAccent.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Apply Target & Count',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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

  void _showAddCustomDhikrDialog(BuildContext context, ThemeProvider tp) {
    HapticFeedback.selectionClick();
    final arabicCtrl = TextEditingController();
    final transliterationCtrl = TextEditingController();
    final translationCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '100');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              22,
              14,
              22,
              math.max(MediaQuery.paddingOf(ctx).bottom + 22.0, 40.0),
            ),
            decoration: BoxDecoration(
              color: tp.surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: tp.borderColor, width: 0.8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tp.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'Add Custom Dhikr / Dua',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: tp.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Personalize your digital Tasbeeh with your favorite Adhkaar',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: tp.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  controller: arabicCtrl,
                  label: 'Arabic Text (Optional)',
                  hint: 'e.g. يَا حَيُّ يَا قَيُّومُ',
                  isArabic: true,
                  tp: tp,
                ),
                const SizedBox(height: 12),

                _buildInputField(
                  controller: transliterationCtrl,
                  label: 'Transliteration / Name',
                  hint: 'e.g. Ya Hayyu Ya Qayyum',
                  tp: tp,
                ),
                const SizedBox(height: 12),

                _buildInputField(
                  controller: translationCtrl,
                  label: 'Meaning / Translation',
                  hint: 'e.g. O Ever-Living, O Sustainer',
                  tp: tp,
                ),
                const SizedBox(height: 12),

                _buildInputField(
                  controller: targetCtrl,
                  label: 'Target Count (0 for ∞ unlimited)',
                  hint: 'e.g. 100 or 167',
                  keyboardType: TextInputType.number,
                  tp: tp,
                ),
                const SizedBox(height: 22),

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
                      color: tp.primaryAccent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: tp.primaryAccent.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Save & Select Dhikr',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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
    required ThemeProvider tp,
    bool isArabic = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: tp.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: tp.containerColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tp.borderColor, width: 0.8),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            style: isArabic
                ? const TextStyle(fontFamily: 'HafsFont', fontSize: 16)
                : GoogleFonts.plusJakartaSans(fontSize: 13.5, color: tp.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: tp.textMuted),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showTasbeehTipDialog(BuildContext context) {
    HapticFeedback.selectionClick();
    final tp = context.read<ThemeProvider>();
    final isDark = tp.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            22,
            14,
            22,
            math.max(MediaQuery.paddingOf(ctx).bottom + 22.0, 40.0),
          ),
          decoration: BoxDecoration(
            color: tp.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: tp.borderColor, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: tp.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tp.primaryAccent.withValues(alpha: isDark ? 0.12 : 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: tp.primaryAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.fingerprint_rounded,
                    color: tp.primaryAccent,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Tasbeeh & Dhikr Guide',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: tp.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151D24) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tp.borderColor, width: 0.8),
                ),
                child: Column(
                  children: [
                    Text(
                      'أَحَبُّ الْكَلَامِ إِلَى اللَّهِ أَرْبَعٌ: سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'HafsFont',
                        fontSize: 15.5,
                        color: isDark ? const Color(0xFFE2E8F0) : tp.primaryAccent,
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
                        color: tp.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '— Sahih Muslim 2137',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: tp.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildTipRow(
                icon: Icons.touch_app_rounded,
                iconColor: tp.primaryAccent,
                title: 'Haptic Counting',
                subtitle: 'Tap anywhere on the giant glowing orb to count with tactile vibration feedback.',
                tp: tp,
              ),
              const SizedBox(height: 10),

              _buildTipRow(
                icon: Icons.tune_rounded,
                iconColor: tp.primaryAccent,
                title: 'Custom Target & Jump Count',
                subtitle: 'Tap on the target bar or status pill to set any custom goal (e.g. 167) or start count.',
                tp: tp,
              ),
              const SizedBox(height: 10),

              _buildTipRow(
                icon: Icons.add_circle_outline_rounded,
                iconColor: tp.primaryAccent,
                title: 'Custom Dhikr & Salawat',
                subtitle: 'Tap the “+ Custom” pill to add your own prayers with customized target counts.',
                tp: tp,
              ),
              const SizedBox(height: 22),

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
                    color: tp.primaryAccent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: tp.primaryAccent.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Got It • Begin Tasbeeh',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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
    required ThemeProvider tp,
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: tp.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: tp.textSecondary,
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
    final tp = context.watch<ThemeProvider>();
    final isDark = tp.isDarkMode;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const double kTopBarHeight = 56.0;

    final currentPhrase = _selectedPhraseIndex < _allPhrases.length
        ? _allPhrases[_selectedPhraseIndex]
        : _allPhrases.first;

    final progress = _target > 0 ? (_counter / _target).clamp(0.0, 1.0) : 1.0;

    return Scaffold(
      backgroundColor: tp.backgroundTop,
      body: Stack(
        children: [
          // Ambient Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [tp.backgroundTop, tp.backgroundBottom],
                ),
              ),
            ),
          ),

          // Central Soft Ambient Teal Aura
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
                    tp.primaryAccent.withValues(alpha: isDark ? 0.12 : 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Layout with Guaranteed Safe Area Clearance
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                topInset + kTopBarHeight + 8,
                16,
                math.max(bottomInset, 16.0),
              ),
              child: Column(
                children: [
                  // Horizontal Dhikr Selector Pills
                  _buildDhikrSelectorPills(tp, isDark),

                  const Spacer(flex: 2),

                  // Active Dhikr Calligraphy & Details (Clickable for Custom Target)
                  _buildActiveDhikrHeader(currentPhrase, tp, isDark),

                  const Spacer(flex: 3),

                  // Hero Circular Counter Orb
                  _buildCounterOrb(progress, tp, isDark),

                  const Spacer(flex: 4),

                  // Quick Controls Row (Reset, Target Segment, Lap)
                  _buildQuickControls(tp, isDark),

                  const SizedBox(height: 14),

                  // Minimalist Bottom Stats
                  _buildMinimalBottomStats(tp),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Fixed Frosted 56px Top Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + kTopBarHeight,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(top: topInset),
                  decoration: BoxDecoration(
                    color: tp.backgroundTop.withValues(alpha: isDark ? 0.85 : 0.90),
                    border: Border(
                      bottom: BorderSide(
                        color: tp.borderColor.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Container(
                    height: 56.0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back Button
                        HeartbeatTap(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: tp.surfaceColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: tp.borderColor, width: 0.8),
                            ),
                            child: Center(
                              child: Icon(Icons.arrow_back_ios_new_rounded, color: tp.textPrimary, size: 16),
                            ),
                          ),
                        ),

                        // Center Title with Glowing Orb
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: tp.primaryAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: tp.primaryAccent.withValues(alpha: 0.8),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'DIGITAL TASBEEH',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: tp.textPrimary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right Controls Cluster (Tip Bulb, Sound, Vibration)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HeartbeatTap(
                              onTap: () => _showTasbeehTipDialog(context),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: tp.surfaceColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: tp.borderColor, width: 0.8),
                                ),
                                child: const Center(
                                  child: Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            HeartbeatTap(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _soundEnabled = !_soundEnabled);
                                _saveTasbeehData();
                              },
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: tp.surfaceColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: tp.borderColor, width: 0.8),
                                ),
                                child: Center(
                                  child: Icon(
                                    _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                                    size: 16,
                                    color: _soundEnabled ? tp.textPrimary : tp.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            HeartbeatTap(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _hapticEnabled = !_hapticEnabled);
                                _saveTasbeehData();
                              },
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: tp.surfaceColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: tp.borderColor, width: 0.8),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.vibration_rounded,
                                    size: 16,
                                    color: _hapticEnabled ? tp.primaryAccent : tp.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Horizontal Dhikr Selector Pills with "+ Custom" Button
  Widget _buildDhikrSelectorPills(ThemeProvider tp, bool isDark) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _allPhrases.length + 1,
        itemBuilder: (context, index) {
          if (index == _allPhrases.length) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: HeartbeatTap(
                onTap: () => _showAddCustomDhikrDialog(context, tp),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: tp.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: tp.primaryAccent.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: tp.primaryAccent),
                      const SizedBox(width: 4),
                      Text(
                        'Custom',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tp.primaryAccent,
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? tp.primaryAccent.withValues(alpha: isDark ? 0.15 : 0.12)
                      : tp.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? tp.primaryAccent : tp.borderColor,
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Text(
                    phrase.defaultTarget > 0
                        ? '${phrase.transliteration} (${phrase.defaultTarget})'
                        : phrase.transliteration,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? tp.primaryAccent : tp.textSecondary,
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

  // Active Dhikr Calligraphy Header (Clickable status to edit target / count)
  Widget _buildActiveDhikrHeader(DhikrPhrase phrase, ThemeProvider tp, bool isDark) {
    final targetLabel = _target == 0 ? '∞' : '$_target';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            phrase.arabic,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'HafsFont',
              fontSize: 28,
              fontWeight: FontWeight.normal,
              color: isDark ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            phrase.transliteration,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: tp.textPrimary,
            ),
          ),
          if (phrase.translation.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              phrase.translation,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: tp.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Clickable Status Badge (Opens Goal / Start Count Sheet)
          HeartbeatTap(
            onTap: () => _showSetCustomGoalAndCountDialog(context, tp),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151D24) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tp.borderColor, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lap $_currentLap  •  Target $targetLabel  •  Total $_totalToday',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tp.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_outlined, size: 12, color: tp.primaryAccent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hero Counter Orb (240px with HeartbeatTap pulse)
  Widget _buildCounterOrb(double progress, ThemeProvider tp, bool isDark) {
    return HeartbeatTap(
      onTap: _onIncrement,
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          color: tp.surfaceColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: tp.borderColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: tp.primaryAccent.withValues(alpha: isDark ? 0.20 : 0.08),
              blurRadius: 32,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(240, 240),
              painter: _TasbeehProgressRingPainter(
                progress: progress,
                strokeWidth: 6.0,
                trackColor: tp.borderColor.withValues(alpha: 0.4),
                progressColor: tp.primaryAccent,
              ),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_counter',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 74,
                    fontWeight: FontWeight.w800,
                    color: tp.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'TAP TO COUNT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: tp.textSecondary,
                    letterSpacing: 1.5,
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
  Widget _buildQuickControls(ThemeProvider tp, bool isDark) {
    final isCustomTarget = _target != 33 && _target != 99 && _target != 100 && _target != 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Reset Button
          HeartbeatTap(
            onTap: _onReset,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tp.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: tp.borderColor, width: 0.8),
              ),
              child: Center(
                child: Icon(
                  Icons.restart_alt_rounded,
                  size: 19,
                  color: tp.textPrimary,
                ),
              ),
            ),
          ),

          // Center Target Segment Switcher with Custom Pencil Button
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: tp.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tp.borderColor, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTargetSegment(33, '33', tp, isDark),
                _buildTargetSegment(99, '99', tp, isDark),
                _buildTargetSegment(100, '100', tp, isDark),
                _buildTargetSegment(0, '∞', tp, isDark),
                // Custom Goal Segment Pill
                HeartbeatTap(
                  onTap: () => _showSetCustomGoalAndCountDialog(context, tp),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCustomTarget
                          ? tp.primaryAccent.withValues(alpha: isDark ? 0.18 : 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: isCustomTarget ? Border.all(color: tp.primaryAccent, width: 0.8) : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCustomTarget)
                          Text(
                            '$_target',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: tp.primaryAccent,
                            ),
                          )
                        else
                          Icon(Icons.edit_outlined, size: 14, color: tp.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lap Flag Button
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tp.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: tp.borderColor, width: 0.8),
              ),
              child: Center(
                child: Icon(
                  Icons.outlined_flag_rounded,
                  size: 19,
                  color: tp.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSegment(int value, String label, ThemeProvider tp, bool isDark) {
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
        width: 36,
        height: 30,
        decoration: BoxDecoration(
          color: isSelected
              ? tp.primaryAccent.withValues(alpha: isDark ? 0.18 : 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: isSelected ? Border.all(color: tp.primaryAccent, width: 0.8) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? tp.primaryAccent : tp.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // Minimal Bottom Stats
  Widget _buildMinimalBottomStats(ThemeProvider tp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.local_fire_department_rounded, size: 14, color: tp.primaryAccent),
        const SizedBox(width: 4),
        Text(
          '$_totalToday / 500 Daily Goal',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: tp.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: tp.borderColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$_streakDays Day Streak 🔥',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: tp.primaryAccent,
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

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

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
