import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:super_teclas/src/data/i18n/app_strings.dart';
import 'package:super_teclas/src/ui/theme/app_colors.dart';

class GameModeCards extends StatelessWidget {
  const GameModeCards({
    super.key,
    this.onTimeTrialTap,
    this.onSuddenDeathTap,
  });

  final VoidCallback? onTimeTrialTap;
  final VoidCallback? onSuddenDeathTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.from(context);

    return Row(
      children: [
        Expanded(
          child: _buildModeCard(
            icon: 'assets/icons/stopwatch.svg',
            title: strings.timeTrial,
            subtitle: strings.timeTrialSubtitle,
            onTap: onTimeTrialTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModeCard(
            icon: 'assets/icons/lightning.svg',
            title: strings.suddenDeath,
            subtitle: strings.suddenDeathSubtitle,
            onTap: onSuddenDeathTap,
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required String icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              icon,
              width: 22,
              height: 22,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
