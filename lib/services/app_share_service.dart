import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppShareService {
  static const String packageName = 'com.nuswallylillah';
  static const String playStoreWebUrl =
      'https://play.google.com/store/apps/details?id=$packageName';
  static const String playStoreMarketUrl = 'market://details?id=$packageName';
  static const String supportEmail = 'dev.nishmal@gmail.com';

  static const String shareMessage = '''
🌙 *Nuswally Lillah - Your Islamic Sanctuary*

Experience precise astronomical prayer times, custom Adhan & Iqamah alarms, Quran recitations, daily Adhkaar, and the curated Islamic Media Hub.

📲 Download on Google Play Store:
$playStoreWebUrl
''';

  /// Opens Google Play Store to rate, review or report feedback
  static Future<bool> openPlayStoreRating() async {
    try {
      final marketUri = Uri.parse(playStoreMarketUrl);
      if (await canLaunchUrl(marketUri)) {
        return await launchUrl(marketUri,
            mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    try {
      final webUri = Uri.parse(playStoreWebUrl);
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('AppShareService openPlayStoreRating error: $e');
    }
    return false;
  }

  /// Native system share sheet with Play Store link and fallback
  static Future<void> shareApp([BuildContext? context]) async {
    try {
      await Share.share(
        shareMessage,
        subject: 'Download Nuswally Lillah on Google Play Store',
      );
    } catch (e) {
      debugPrint('AppShareService shareApp error: $e');
      // Fallback if plugin native code is not attached (e.g. before full app rebuild)
      await Clipboard.setData(const ClipboardData(text: shareMessage));
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Play Store download link copied to clipboard! (Rebuild app for native share sheet)'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Sends feedback or bug report directly via email
  static Future<bool> sendFeedbackReport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': 'Nuswally Lillah - Feedback & Report ($packageName)',
        'body':
            'Assalamu Alaikum,\n\nI would like to share feedback / report an issue:\n\n',
      },
    );

    try {
      return await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('AppShareService sendFeedbackReport error: $e');
    }
    return false;
  }
}
