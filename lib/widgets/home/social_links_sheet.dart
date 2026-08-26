import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../providers/theme_provider.dart';
import '../../screens/youtube_player_screen.dart';
import '../../services/social_links_service.dart';
import '../../theme/jira_theme.dart';

class SocialLinksSheet extends StatefulWidget {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SocialLinksSheet(),
    );
  }

  const SocialLinksSheet({super.key});

  @override
  State<SocialLinksSheet> createState() => _SocialLinksSheetState();
}

class _SocialLinksSheetState extends State<SocialLinksSheet> {
  List<VideoCategory>? _categories;
  List<SocialLink>? _allLinks;
  String _selectedCategoryId = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categories = await SocialLinksService.fetchCategories();
    final links = await SocialLinksService.fetchSocialLinks();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _allLinks = links;
      _loading = false;
    });
  }

  Future<void> _open(SocialLink link) async {
    if (link.platform == 'youtube' &&
        YoutubePlayerController.convertUrlToId(link.url) != null) {
      final navigator = Navigator.of(context);
      navigator.pop();
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => YoutubePlayerScreen(
            videoUrl: link.url,
            title: link.title,
            category: link.category,
            episode: link.episode,
            speaker: link.speaker,
          ),
        ),
      );
      return;
    }

    final uri = Uri.parse(link.url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }


  List<SocialLink> get _filteredLinks {
    if (_allLinks == null) return [];
    if (_selectedCategoryId == 'all') return _allLinks!;
    final category = _categories?.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => VideoCategory(id: '', name: '', icon: '', items: []),
    );
    return category?.items ?? _allLinks!;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final surface = isDark ? const Color(0xFF161B22) : Colors.white;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? const Color(0xFF30363D)
                  : const Color(0xFFD0D7DE),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Islamic Media & Lectures',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F2328),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: JiraTheme.secondaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: JiraTheme.secondaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${_filteredLinks.length} Items',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_categories != null && _categories!.length > 1)
                _buildCategoryFilterPills(isDark),
              const SizedBox(height: 8),
              Flexible(child: _buildBody(isDark)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterPills(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _buildFilterChip(
            id: 'all',
            label: 'All Media',
            isSelected: _selectedCategoryId == 'all',
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          for (final cat in _categories!) ...[
            _buildFilterChip(
              id: cat.id,
              label: cat.name,
              isSelected: _selectedCategoryId == cat.id,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String id,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategoryId = id;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? JiraTheme.secondaryGreen.withValues(alpha: 0.15)
                  : JiraTheme.primary50)
              : (isDark ? const Color(0xFF1F242C) : const Color(0xFFF1F3F5)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? JiraTheme.secondaryGreen
                : (isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? const Color(0xFF34D399) : JiraTheme.primaryBlue)
                : (isDark ? const Color(0xFF8B949E) : const Color(0xFF626F86)),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(JiraTheme.secondaryGreen),
            ),
          ),
        ),
      );
    }

    final links = _filteredLinks;
    if (links.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No content available in this category',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF8B949E) : const Color(0xFF626F86),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: links.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        return _LinkTile(link: links[i], onTap: () => _open(links[i]));
      },
    );
  }
}

class _LinkTile extends StatelessWidget {
  final SocialLink link;
  final VoidCallback onTap;

  const _LinkTile({required this.link, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F242C) : const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: link.platform == 'youtube'
                      ? const Color(0xFFFF0033).withValues(alpha: 0.12)
                      : JiraTheme.secondaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  link.platform == 'youtube'
                      ? Icons.play_circle_fill_rounded
                      : Icons.link_rounded,
                  color: link.platform == 'youtube'
                      ? const Color(0xFFFF0033)
                      : JiraTheme.secondaryGreen,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (link.category.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                                  : JiraTheme.successGreenBgLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${link.category} • ${link.episode}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : JiraTheme.secondary700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      link.title.isNotEmpty ? link.title : 'Lecture / Media',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F2328),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${link.speaker} • ${link.views}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF8B949E)
                            : const Color(0xFF626F86),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B22) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
                  ),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFF34D399) : JiraTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
