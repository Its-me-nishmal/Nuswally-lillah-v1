import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/notification_service.dart';
import '../../theme/jira_theme.dart';
import '../../widgets/heartbeat_tap.dart';

class ObPage5Notifications extends StatefulWidget {
  final VoidCallback onNext;

  const ObPage5Notifications({super.key, required this.onNext});

  @override
  State<ObPage5Notifications> createState() => _ObPage5NotificationsState();
}

class _ObPage5NotificationsState extends State<ObPage5Notifications> {
  bool _notificationsEnabled = true;
  bool _exactAlarmsGranted = false;
  int _alertTiming = 0; // 0 = Exact Adhan, 1 = 10 Mins Before

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Check initial state
  }

  Future<void> _requestPermissions() async {
    HapticFeedback.selectionClick();
    await NotificationService.requestPermissions();
    setState(() => _exactAlarmsGranted = true);
  }

  Future<void> _completeSetup() async {
    HapticFeedback.selectionClick();
    if (_notificationsEnabled) {
      await NotificationService.requestPermissions();
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // Title
                        Text(
                          'Prayer Notifications',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF0F6FC),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Receive precise Adhan alerts so you never miss a prayer.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF8B949E),
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 1. Master Toggle Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _notificationsEnabled ? JiraTheme.primaryBlue.withValues(alpha: 0.6) : const Color(0xFF30363D),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F242C),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _notificationsEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
                                  color: _notificationsEnabled ? JiraTheme.primaryBlue : const Color(0xFF8B949E),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Enable Adhan Alerts',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFF0F6FC),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Automatic calls for all 5 daily prayers',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: const Color(0xFF8B949E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _notificationsEnabled,
                                activeTrackColor: JiraTheme.primaryBlue,
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _notificationsEnabled = val);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 2. Exact Alarms & Background Permission Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF30363D)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1F242C),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.alarm_on_rounded,
                                      color: JiraTheme.secondaryGreen,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Exact Alarms & Battery Exemption',
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFF0F6FC),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Prevents Android from delaying Adhan alerts',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF8B949E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              HeartbeatTap(
                                onTap: _requestPermissions,
                                child: Container(
                                  width: double.infinity,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _exactAlarmsGranted
                                        ? JiraTheme.secondaryGreen.withValues(alpha: 0.15)
                                        : const Color(0xFF1F242C),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _exactAlarmsGranted ? JiraTheme.secondaryGreen : const Color(0xFF30363D),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _exactAlarmsGranted ? 'PERMISSIONS GRANTED ✓' : 'ALLOW EXACT ALARMS',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: _exactAlarmsGranted ? JiraTheme.secondaryGreen : const Color(0xFF93C5FD),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 3. Alert Mode
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF30363D)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ALERT TIMING',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.8,
                                  color: const Color(0xFF8B949E),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildTimingOption(0, 'Exact Adhan on Prayer Time', 'Play full call to prayer at the solar moment'),
                              const SizedBox(height: 8),
                              _buildTimingOption(1, 'Gentle 10-Minute Reminder', 'Soft chime notification before prayer time'),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Bottom Action Button
                        HeartbeatTap(
                          onTap: _completeSetup,
                          child: Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              color: JiraTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: JiraTheme.primaryBlue.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'CONTINUE TO FINISH',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimingOption(int index, String title, String subtitle) {
    final isSelected = _alertTiming == index;

    return HeartbeatTap(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _alertTiming = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1F242C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? JiraTheme.primaryBlue : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
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
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF8B949E),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? JiraTheme.primaryBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? JiraTheme.primaryBlue : const Color(0xFF64748B),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Center(child: Icon(Icons.check, size: 11, color: Colors.white))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
