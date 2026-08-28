import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_update_service.dart';
import '../theme/app_colors.dart';

class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({super.key});

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  AppUpdateInfo? _updateInfo;
  bool _loading = true;
  bool _checkingOnline = false;

  @override
  void initState() {
    super.initState();
    _loadUpdateInfo();
  }

  Future<void> _loadUpdateInfo() async {
    final info = await AppUpdateService.fetchUpdateInfo();
    if (!mounted) return;
    setState(() {
      _updateInfo = info;
      _loading = false;
    });
  }

  Future<void> _checkLiveUpdates() async {
    setState(() {
      _checkingOnline = true;
    });
    HapticFeedback.lightImpact();

    final info = await AppUpdateService.fetchUpdateInfo(forceRemote: true);
    if (!mounted) return;

    setState(() {
      _updateInfo = info;
      _checkingOnline = false;
    });

    final hasUpdate = AppUpdateService.isUpdateAvailable(info);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: context.cardTop,
        content: Text(
          hasUpdate
              ? 'New version ${info?.versionName} is available!'
              : 'You are using the latest version of Nuswally Lillah.',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _downloadUpdate() async {
    if (_updateInfo == null || _updateInfo!.downloadUrl.isEmpty) return;
    HapticFeedback.selectionClick();
    final success = await AppUpdateService.launchDownload(
      _updateInfo!.downloadUrl,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open download link'),
          backgroundColor: context.cardTop,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final isUpdateAvailable = AppUpdateService.isUpdateAvailable(_updateInfo);

    return Scaffold(
      backgroundColor: context.pageTop,
      appBar: AppBar(
        backgroundColor: context.pageTop,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'App Updates',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: context.accent,
                ),
              )
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  // 1. Version Hero Card
                  _buildVersionHeroCard(isUpdateAvailable),
                  const SizedBox(height: 16),

                  // 2. What's New & Changelog Details Card
                  if (_updateInfo != null) _buildDetailedChangelogCard(),
                  const SizedBox(height: 24),

                  // 3. Action Buttons
                  if (isUpdateAvailable) ...[
                    ElevatedButton.icon(
                      onPressed: _downloadUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        'Download & Update (v${_updateInfo!.versionName})',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Check for Updates Button
                  OutlinedButton.icon(
                    onPressed: _checkingOnline ? null : _checkLiveUpdates,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textPrimary,
                      side: BorderSide(color: context.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _checkingOnline
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.accent,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: Text(
                      _checkingOnline
                          ? 'Checking for updates...'
                          : 'Check for Updates',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Widget _buildVersionHeroCard(bool isUpdateAvailable) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardTop,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUpdateAvailable
              ? context.accent.withValues(alpha: 0.5)
              : context.cardBorder,
          width: isUpdateAvailable ? 1.3 : 1,
        ),
      ),
      child: Row(
        children: [
          // App Icon
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.mosque_rounded, color: context.accent, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nuswally Lillah',
                  style: GoogleFonts.outfit(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Installed: v${AppUpdateService.currentVersionName}',
                  style: GoogleFonts.inter(
                    color: context.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isUpdateAvailable
                        ? context.accent.withValues(alpha: 0.15)
                        : context.cardBottom,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUpdateAvailable
                          ? context.accent.withValues(alpha: 0.4)
                          : context.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUpdateAvailable
                            ? Icons.new_releases_rounded
                            : Icons.check_circle_rounded,
                        size: 13,
                        color: isUpdateAvailable
                            ? context.accent
                            : context.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          isUpdateAvailable
                              ? 'Update Available: v${_updateInfo?.versionName}'
                              : 'Latest version installed',
                          style: TextStyle(
                            color: isUpdateAvailable
                                ? context.accent
                                : context.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedChangelogCard() {
    final info = _updateInfo!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardTop,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Release Highlights",
                style: GoogleFonts.outfit(
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (info.releaseDate.isNotEmpty)
                Text(
                  info.releaseDate,
                  style: GoogleFonts.inter(
                    color: context.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (info.title.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              info.title,
              style: GoogleFonts.outfit(
                color: context.accent,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (info.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              info.description,
              style: GoogleFonts.inter(
                color: context.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],

          // 1. New Features
          if (info.features.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionHeader(
              icon: Icons.auto_awesome_rounded,
              iconColor: context.accent,
              title: "What's New",
            ),
            const SizedBox(height: 8),
            for (final item in info.features)
              _buildBulletItem(item, context.accent),
          ],

          // 2. Improvements
          if (info.improvements.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSectionHeader(
              icon: Icons.bolt_rounded,
              iconColor: context.accent,
              title: "Improvements & Performance",
            ),
            const SizedBox(height: 8),
            for (final item in info.improvements)
              _buildBulletItem(item, context.accent),
          ],

          // 3. Bug Fixes
          if (info.bugFixes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSectionHeader(
              icon: Icons.build_circle_outlined,
              iconColor: context.gold,
              title: "Bug Fixes",
            ),
            const SizedBox(height: 8),
            for (final item in info.bugFixes)
              _buildBulletItem(item, context.gold),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: context.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletItem(String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: context.textPrimary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
