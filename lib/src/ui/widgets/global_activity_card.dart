import 'package:flutter/material.dart';
import 'package:super_teclas/src/data/i18n/app_strings.dart';
import 'package:super_teclas/src/services/ranking_service.dart';
import 'package:super_teclas/src/ui/theme/app_colors.dart';

class GlobalActivityCard extends StatelessWidget {
  const GlobalActivityCard({
    super.key,
    this.recentGames = const [],
  });

  final List<RankingEntry> recentGames;

  String _formatTimeAgo(DateTime dateTime, bool isPortuguese) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return isPortuguese ? 'agora mesmo' : 'just now';
    } else if (difference.inMinutes < 60) {
      final m = difference.inMinutes;
      return isPortuguese ? 'há $m minutos' : '$m minutes ago';
    } else if (difference.inHours < 24) {
      final h = difference.inHours;
      return isPortuguese ? 'há $h horas' : '$h hours ago';
    } else {
      final d = difference.inDays;
      return isPortuguese ? 'há $d dias' : '$d days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.from(context);

    final gamesToDisplay = recentGames.isNotEmpty
        ? recentGames.take(2).toList()
        : [
            RankingEntry(
              username: 'heliodr',
              score: 95,
              wordsCompleted: 15,
              accuracy: 98.0,
              averageSpeed: 1.8,
              createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
            ),
            RankingEntry(
              username: 'patricio2',
              score: 80,
              wordsCompleted: 12,
              accuracy: 92.0,
              averageSpeed: 2.1,
              createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strings.globalActivity,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < gamesToDisplay.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildActivityItem(
              username: gamesToDisplay[i].username,
              score: gamesToDisplay[i].score,
              timeAgo: _formatTimeAgo(
                gamesToDisplay[i].createdAt,
                strings.isPortuguese,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String username,
    required int score,
    required String timeAgo,
  }) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      username,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '$score%',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                timeAgo,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
