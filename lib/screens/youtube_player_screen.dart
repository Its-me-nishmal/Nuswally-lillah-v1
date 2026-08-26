import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../theme/jira_theme.dart';

class YoutubePlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final String? category;
  final String? episode;
  final String? speaker;

  const YoutubePlayerScreen({
    super.key,
    required this.videoUrl,
    this.title,
    this.category,
    this.episode,
    this.speaker,
  });

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _subscription;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Allow rotation between portrait and landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final id = YoutubePlayerController.convertUrlToId(widget.videoUrl);
    if (id == null || id.isEmpty) {
      _hasError = true;
      return;
    }

    _controller = YoutubePlayerController.fromVideoId(
      videoId: id,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );

    _subscription = _controller!.listen((value) {
      if (mounted && value.hasError && !_hasError) {
        setState(() => _hasError = true);
      }
    });
  }

  @override
  void dispose() {
    // Restore portrait-only lock and system UI when leaving player
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _subscription?.cancel();
    final controller = _controller;
    if (controller != null) {
      unawaited(controller.close());
    }
    super.dispose();
  }

  Future<void> _openExternally() async {
    final launched = await launchUrl(
      Uri.parse(widget.videoUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open YouTube')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final displayTitle = widget.title?.trim().isNotEmpty == true
        ? widget.title!
        : 'Islamic Lecture';
    final speaker = widget.speaker ?? 'Nuswally Lillah';
    final category = widget.category ?? 'Media';

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        if (isLandscape) {
          // Hide system bars for immersive landscape fullscreen
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: controller == null || _hasError
                  ? _buildFallbackCard()
                  : YoutubePlayer(
                      controller: controller,
                      backgroundColor: Colors.black,
                    ),
            ),
          );
        }

        // Restore system bars in portrait mode
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

        return Scaffold(
          backgroundColor: const Color(0xFF0B0E14),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0B0E14),
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              category,
              style: const TextStyle(
                color: Color(0xFFF0F6FC),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                onPressed: _openExternally,
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                color: const Color(0xFF8B949E),
                tooltip: 'Open in YouTube',
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 16:9 YouTube Player Frame
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.black,
                    child: controller == null || _hasError
                        ? _buildFallbackCard()
                        : YoutubePlayer(
                            controller: controller,
                            backgroundColor: Colors.black,
                          ),
                  ),
                ),

                // Video Title & Details
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom),
                    children: [
                      Text(
                        displayTitle,
                        style: const TextStyle(
                          color: Color(0xFFF0F6FC),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        speaker,
                        style: const TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: _openExternally,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF30363D)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Color(0xFFFF0033),
                          size: 20,
                        ),
                        label: const Text(
                          'Watch in YouTube App',
                          style: TextStyle(
                            fontSize: 13.5,
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
        );
      },
    );
  }

  Widget _buildFallbackCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_circle_outline_rounded,
              color: Color(0xFF8B949E),
              size: 44,
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap below to watch on YouTube',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _openExternally,
              style: ElevatedButton.styleFrom(
                backgroundColor: JiraTheme.secondaryGreen,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open YouTube'),
            ),
          ],
        ),
      ),
    );
  }
}
