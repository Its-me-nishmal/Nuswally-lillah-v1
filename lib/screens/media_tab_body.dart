import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../services/social_links_service.dart';
import '../theme/jira_theme.dart';
import '../widgets/heartbeat_tap.dart';
import 'youtube_player_screen.dart';

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
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: JiraTheme.secondaryGreen,
        ),
      );
    }

    final videos = _filteredVideos;
    final hasFeatured = videos.isNotEmpty;
    final featuredVideo = hasFeatured ? videos.first : null;
    final gridVideos = hasFeatured && videos.length > 1
        ? videos.sublist(1)
        : <SocialLink>[];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 100 + MediaQuery.paddingOf(context).bottom),
      children: [
        // 1. Header Title & Badge
        _buildSectionHeader(),
        const SizedBox(height: 12),

        // 2. Category Filter Chips
        if (_categories.isNotEmpty) ...[
          _buildCategoryFilterBar(),
          const SizedBox(height: 16),
        ],

        // 3. Content Body
        if (videos.isEmpty)
          _buildEmptyState()
        else ...[
          // 4. Featured First Video (Full Width Hero Card)
          if (featuredVideo != null) ...[
            _buildFeaturedHeroCard(featuredVideo),
            const SizedBox(height: 20),
          ],

          // 5. Grid Section Header (if more videos exist)
          if (gridVideos.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'More Episodes & Bayans',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF0F6FC),
                  ),
                ),
                Text(
                  '${gridVideos.length} Videos',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF8B949E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 6. 2-in-a-Row Grid View
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gridVideos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.76, // Elegant proportion for thumb + title + tags
              ),
              itemBuilder: (context, index) {
                final video = gridVideos[index];
                return _buildGridVideoCard(video);
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Islamic Media Hub',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: const Color(0xFFF0F6FC),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tafseer, Lectures, Bayans & Reflections',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFF8B949E),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: JiraTheme.secondaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE HUB',
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: JiraTheme.secondaryGreen,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildCategoryChip('all', 'All Videos'),
          const SizedBox(width: 8),
          for (final cat in _categories) ...[
            _buildCategoryChip(cat.id, cat.name),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String id, String label) {
    final isSelected = _selectedCategoryId == id;

    return HeartbeatTap(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategoryId = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? JiraTheme.secondaryGreen.withValues(alpha: 0.15)
              : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? JiraTheme.secondaryGreen
                : const Color(0xFF30363D),
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color:
                isSelected ? const Color(0xFF34D399) : const Color(0xFF8B949E),
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 1. Featured Full-Width Hero Video Card
  Widget _buildFeaturedHeroCard(SocialLink video) {
    final videoId = YoutubePlayerController.convertUrlToId(video.url);
    final thumbnailUrl = videoId != null
        ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
        : null;

    return HeartbeatTap(
      onTap: () => _openPlayer(video),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF30363D)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 16:9 Full Width Thumbnail
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbnailUrl != null)
                    Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),

                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),

                  // Top Left "Featured" Pill
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: JiraTheme.secondaryGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'FEATURED',
                        style: GoogleFonts.outfit(
                          color: Colors.black,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),

                  // Center Glowing Play Button
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: JiraTheme.secondaryGreen.withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: JiraTheme.secondaryGreen
                                .withValues(alpha: 0.45),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  // Bottom Right Duration Pill
                  if (video.duration.isNotEmpty)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: Color(0xFF93C5FD),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              video.duration,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Video Details Under Thumbnail
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFF0F6FC),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2530),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          video.category,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF93C5FD),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          video.speaker,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF8B949E),
                            fontSize: 12,
                          ),
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
    );
  }

  // 2. Compact 2-in-a-Row Grid Video Card
  Widget _buildGridVideoCard(SocialLink video) {
    final videoId = YoutubePlayerController.convertUrlToId(video.url);
    final thumbnailUrl = videoId != null
        ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
        : null;

    return HeartbeatTap(
      onTap: () => _openPlayer(video),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF262C36)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 16:9 Thumbnail with Duration Badge & Play Button
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbnailUrl != null)
                    Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),

                  // Dark gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),

                  // Play Button
                  Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: JiraTheme.secondaryGreen.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                  // Duration Badge
                  if (video.duration.isNotEmpty)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          video.duration,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Video Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFF0F6FC),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.speaker,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF8B949E),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1F242C),
      child: const Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          color: Color(0xFF8B949E),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.video_library_outlined,
              size: 44,
              color: Color(0xFF484F58),
            ),
            const SizedBox(height: 12),
            Text(
              'No videos in this category',
              style: GoogleFonts.outfit(
                color: const Color(0xFF8B949E),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
