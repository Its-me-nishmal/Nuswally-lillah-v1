import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/adhkaar.dart';
import '../providers/adhkaar_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/heartbeat_tap.dart';
import '../widgets/jira_header.dart';
import '../widgets/jira_screen.dart';
import 'dua_detail_screen.dart';

const String kMlFont = 'BalooChettan2';

class QuranicDuasScreen extends StatelessWidget {
  const QuranicDuasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isMl = tp.isMalayalam;
    final bundle = context.watch<AdhkaarProvider>().bundle;

    if (bundle == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final duas = bundle.quranicDuaIds
        .map((id) => bundle.duas[id])
        .whereType<Dua>()
        .toList();

    final title = isMl ? 'ഖുർആനിക പ്രാർത്ഥനകൾ' : 'QURANIC DUAS';
    final subtitle = isMl ? 'ഖുർആനിൽ നിന്നുള്ളവ' : 'HOLY QURAN';

    return JiraScreen(
      child: Column(
        children: [
          JiraHeader(
            title: title,
            subtitle: subtitle,
          ),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 4, 16, 20 + MediaQuery.paddingOf(context).bottom),
              itemCount: duas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _DuaCard(dua: duas[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  final Dua dua;

  const _DuaCard({required this.dua});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isMl = tp.isMalayalam;

    return HeartbeatTap(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DuaDetailScreen(dua: dua),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tp.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: tp.borderColor.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tp.primaryAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 18,
                  color: tp.primaryAccent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dua.dua,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'AdobeArabic',
                      fontSize: 19,
                      height: 1.5,
                      color: tp.textPrimary,
                    ),
                  ),
                  if (isMl && dua.transli.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      dua.transli,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Indulekha',
                        fontSize: 12,
                        color: tp.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: tp.textSecondary.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
