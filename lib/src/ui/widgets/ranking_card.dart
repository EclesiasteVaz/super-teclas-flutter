import 'package:flutter/material.dart';
import 'package:super_teclas/src/data/i18n/app_strings.dart';
import 'package:super_teclas/src/services/ranking_service.dart';
import 'package:super_teclas/src/ui/theme/app_colors.dart';
import 'package:super_teclas/src/ui/widgets/ranking_modal.dart';

class RankingCard extends StatelessWidget {
  const RankingCard({
    super.key,
    required this.rankings,
  });

  final List<RankingEntry> rankings;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.from(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      strings.rankingTitle,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  strings.updatedJustNow,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceBorder),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const SizedBox(
                  width: 30,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    strings.player,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Text(
                  strings.accuracy,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceBorder),
          if (rankings.isEmpty)
            _buildFallbackRows()
          else
            for (var i = 0; i < rankings.length && i < 5; i++)
              _buildRankingRow(
                position: i + 1,
                username: rankings[i].username,
                accuracy: rankings[i].accuracy,
                score: rankings[i].score,
              ),
          const Divider(height: 1, color: AppColors.surfaceBorder),
          InkWell(
            onTap: () => RankingModal.show(context),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  strings.seeFullRanking,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackRows() {
    const fallbackData = [
      (1, 'Amarildo', 100.0),
      (2, '!000ton', 45.0),
      (3, 'Dark HawEye', 26.0),
      (4, 'ildeberto', 24.0),
      (5, 'Matheus Fagundes', 24.0),
    ];

    return Column(
      children: fallbackData
          .map((item) => _buildRankingRow(
                position: item.$1,
                username: item.$2,
                accuracy: item.$3,
                score: item.$3.toInt(),
              ))
          .toList(),
    );
  }

  Widget _buildRankingRow({
    required int position,
    required String username,
    required double accuracy,
    required int score,
  }) {
    final isTop = position == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$position.',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isTop ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              username,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${accuracy.toStringAsFixed(0)}%',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isTop ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
