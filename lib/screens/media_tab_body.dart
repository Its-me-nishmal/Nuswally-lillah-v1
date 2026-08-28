import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/social_links_service.dart';
import '../widgets/heartbeat_tap.dart';
import 'youtube_player_screen.dart';
import '../theme/app_colors.dart';

class MediaTabBody extends StatefulWidget {
  final String searchQuery;

  const MediaTabBody({super.key, this.searchQuery = ''});

  @override
  State<MediaTabBody> createState() => _MediaTabBodyState();
}

class _MediaTabBodyState extends State<MediaTabBody> {
  List<VideoCategory> _categories = [];
  List<SocialLink> _allVideos = [];
  String _selectedCategoryId = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final categories = await SocialLinksService.fetchCategories();
    final links = await SocialLinksService.fetchSocialLinks();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _allVideos = links;
      _loading = false;
    });
  }

  List<SocialLink> get _filteredVideos {
    List<SocialLink> list = _allVideos;
    if (_selectedCategoryId != 'all') {
      final cat = _categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () =>
            const VideoCategory(id: '', name: '', icon: '', items: []),
      );
      if (cat.items.isNotEmpty) list = cat.items;
    }

    if (widget.searchQuery.trim().isNotEmpty) {
      final q = widget.searchQuery.trim().toLowerCase();
      list = list.where((v) {
        return v.title.toLowerCase().contains(q) ||
            v.speaker.toLowerCase().contains(q) ||
            v.category.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  void _openPlayer(SocialLink video) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => YoutubePlayerScreen(
          videoUrl: video.url,
          title: video.title,
          category: video.category,
          episode: video.episode,
          speaker: video.speaker,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watchTheme();
    final tp = context.watch<ThemeProvider>();
    final isDark = tp.isDarkMode;

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: tp.primaryAccent,
        ),
      );
    }

    final videos = _filteredVideos;
    final hasFeatured = videos.isNotEmpty;
    final featuredVideo = hasFeatured ? videos.first : null;
    final remainingVideos = hasFeatured && videos.length > 1
        ? videos.sublist(1)
        : <SocialLink>[];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        100 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        // 1. Sleek Filter Capsules Bar
        _buildFilterCapsules(tp, isDark),

        const SizedBox(height: 16),

        // 2. Featured Video / Live Stream Hero Card
        if (featuredVideo != null && widget.searchQuery.trim().isEmpty) ...[
          _buildFeaturedHeroCard(context, featuredVideo, tp, isDark),
          const SizedBox(height: 20),
        ],

        // 3. Section Header
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            'ISLAMIC BROADCASTS & LECTURES (${videos.length})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: tp.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 4. Unified iOS Grouped Card Container for Remaining Videos
        if (videos.isEmpty)
          _buildEmptySearchState(tp)
        else
          Container(
            decoration: BoxDecoration(
              color: tp.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tp.borderColor, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    (widget.searchQuery.trim().isNotEmpty
                            ? videos
                            : remainingVideos)
                        .asMap()
                        .entries
                        .map((entry) {
                          final video = entry.value;
                          final isLast =
                              entry.key ==
                              (widget.searchQuery.trim().isNotEmpty
                                      ? videos.length
                                      : remainingVideos.length) -
                                  1;

                          return Column(
                            children: [
                              _buildVideoRowItem(context, video, tp, isDark),
                              if (!isLast) _buildHairlineDivider(isDark),
                            ],
                          );
                        })
                        .toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterCapsules(ThemeProvider tp, bool isDark) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategoryId == cat.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: HeartbeatTap(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategoryId = cat.id);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? tp.primaryAccent.withValues(alpha: isDark ? 0.14 : 0.12)
                      : tp.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? tp.primaryAccent.withValues(
                            alpha: isDark ? 0.35 : 0.4,
                          )
                        : tp.borderColor,
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Text(
                    cat.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? tp.primaryAccent : tp.textSecondary,
                      letterSpacing: 0.1,
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

  Widget _buildFeaturedHeroCard(
    BuildContext context,
    SocialLink video,
    ThemeProvider tp,
    bool isDark,
  ) {
    return HeartbeatTap(
      onTap: () => _openPlayer(video),
      child: Container(
        decoration: BoxDecoration(
          color: tp.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tp.borderColor, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Thumbnail with Islamic Teal Play Glow
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      video.effectiveThumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark ? context.cardTop : context.cardBorder,
                        child: Center(
                          child: Icon(
                            Icons.mosque_rounded,
                            size: 48,
                            color: tp.primaryAccent.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tp.primaryAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fiber_manual_record_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            video.category.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        video.episode.trim().toLowerCase().startsWith('ep')
                            ? video.episode.trim()
                            : 'EP ${video.episode}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: tp.primaryAccent.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: tp.primaryAccent.withValues(alpha: 0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Title & Speaker Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: tp.textPrimary,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: tp.primaryAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          video.speaker,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: tp.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoRowItem(
    BuildContext context,
    SocialLink video,
    ThemeProvider tp,
    bool isDark,
  ) {
    return HeartbeatTap(
      onTap: () => _openPlayer(video),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: Colors.transparent,
        child: Row(
          children: [
            // Left Thumbnail with Play Badge
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 50,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        video.effectiveThumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: isDark ? context.cardTop : context.cardBorder,
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: tp.primaryAccent,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.25),
                        child: Center(
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: tp.primaryAccent.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Video Title & Meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: tp.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        video.speaker,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: tp.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(color: tp.textMuted, fontSize: 10),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        video.episode.trim().toLowerCase().startsWith('ep')
                            ? video.episode.trim()
                            : 'EP ${video.episode}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: tp.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right_rounded, size: 20, color: tp.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildHairlineDivider(bool isDark) {
    return Container(
      height: 1.0,
      margin: const EdgeInsets.only(left: 102),
      color: isDark ? context.hairline : context.cardBorder,
    );
  }

  Widget _buildEmptySearchState(ThemeProvider tp) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.video_library_outlined, size: 40, color: tp.textMuted),
            const SizedBox(height: 12),
            Text(
              'No broadcasts found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tp.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
