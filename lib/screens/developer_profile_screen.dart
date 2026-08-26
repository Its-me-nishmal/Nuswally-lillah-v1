import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/jira_theme.dart';
import '../widgets/heartbeat_tap.dart';

class DeveloperProfileScreen extends StatelessWidget {
  const DeveloperProfileScreen({super.key});

  Future<void> _launchExternalUrl(BuildContext context, String urlString) async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        _copyToClipboard(context, urlString, 'URL');
      }
    } catch (_) {
      if (context.mounted) {
        _copyToClipboard(context, urlString, 'URL');
      }
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    HapticFeedback.selectionClick();
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Nuswally Lillah App Support'},
    );
    try {
      final launched = await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        _copyToClipboard(context, email, 'Email');
      }
    } catch (_) {
      if (context.mounted) {
        _copyToClipboard(context, email, 'Email');
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  HeartbeatTap(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF30363D)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFFF0F6FC),
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    'DEVELOPER PROFILE',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      color: const Color(0xFFF0F6FC),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance
                ],
              ),
            ),

            // 2. Scrollable Content
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.paddingOf(context).bottom),
                children: [
                  // Hero Profile Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFF30363D)),
                      boxShadow: [
                        BoxShadow(
                          color: JiraTheme.primaryBlue.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar Photo
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: JiraTheme.primaryBlue,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: JiraTheme.primaryBlue.withValues(alpha: 0.4),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/developer.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF1F242C),
                                child: const Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 48,
                                    color: Color(0xFF93C5FD),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Name
                        Text(
                          'Muhammed Nishmal',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF0F6FC),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Alias / Handle Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: JiraTheme.primaryBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: JiraTheme.primaryBlue.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'Cipher Nichu • @Its-me-nishmal',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF93C5FD),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Location Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: JiraTheme.secondaryGreen,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Vadakara, Kozhikode, Kerala, India',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF8B949E),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Bio
                        Text(
                          'Full-Stack Developer, Systems Builder & AI Solutions Architect. Dedicated to crafting elegant, ultra-performant Islamic applications and community tools with precision and Ihsan.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF8B949E),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section: CONNECT & REPOSITORIES
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'CONNECT & REPOSITORIES',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: const Color(0xFF8B949E),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // GitHub Tile
                  _buildLinkTile(
                    context: context,
                    icon: Icons.code_rounded,
                    iconColor: const Color(0xFF93C5FD),
                    title: 'GitHub Profile',
                    subtitle: 'github.com/Its-me-nishmal',
                    badge: 'OPEN GITHUB',
                    onTap: () => _launchExternalUrl(context, 'https://github.com/Its-me-nishmal'),
                  ),

                  const SizedBox(height: 10),

                  // Email Tile
                  _buildLinkTile(
                    context: context,
                    icon: Icons.mail_outline_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    title: 'Developer Support Email',
                    subtitle: 'dev.nishmal@gmail.com',
                    badge: 'SEND EMAIL',
                    onTap: () => _launchEmail(context, 'dev.nishmal@gmail.com'),
                  ),

                  const SizedBox(height: 10),

                  // Vadakara Location Tile
                  _buildLinkTile(
                    context: context,
                    icon: Icons.place_outlined,
                    iconColor: const Color(0xFFFB923C),
                    title: 'Origin / Hometown',
                    subtitle: 'Vadakara, North Malabar, Kerala',
                    badge: 'VADAKARA',
                    onTap: () {},
                  ),

                  const SizedBox(height: 24),

                  // Section: TECH STACK & EXPERTISE
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'TECH STACK & EXPERTISE',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: const Color(0xFF8B949E),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tech Stack Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Flutter / Dart',
                      'Next.js',
                      'Node.js',
                      'TypeScript',
                      'Python',
                      'AWS & Cloud',
                      'AI & LLMs',
                      'Automation Systems',
                    ].map((tech) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF30363D)),
                        ),
                        child: Text(
                          tech,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF93C5FD),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 36),

                  // Footer Duas & Barakah
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'جَزَاكَ ٱللَّٰهُ خَيْرًا',
                          style: TextStyle(
                            fontFamily: 'HafsFont',
                            fontSize: 20,
                            color: Color(0xFF93C5FD),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Nuswally Lillah • Crafted with Ihsan in Vadakara',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return HeartbeatTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1F242C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
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
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
