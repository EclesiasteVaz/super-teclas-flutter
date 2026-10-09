import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:super_teclas/src/data/i18n/app_strings.dart';
import 'package:super_teclas/src/ui/theme/app_colors.dart';
import 'package:super_teclas/src/ui/widgets/ranking_modal.dart';

class NavHeaderWidget extends StatelessWidget {
  const NavHeaderWidget({
    super.key,
    this.onDictionaryTap,
    this.currentRoute = 'home',
  });

  final VoidCallback? onDictionaryTap;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.from(context);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 16,
        vertical: 18,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/keyboard.svg',
                width: 26,
                height: 26,
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                strings.superTeclasTitle,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (isWide) ...[
                _buildNavLink(strings.home, currentRoute == 'home', () {}),
                const SizedBox(width: 20),
                _buildNavLink(
                  strings.practice,
                  currentRoute == 'practice',
                  onDictionaryTap,
                ),
                const SizedBox(width: 20),
                _buildNavLink(
                  strings.leaderboard,
                  currentRoute == 'leaderboard',
                  () => RankingModal.show(context),
                ),
                const SizedBox(width: 24),
              ],
              ElevatedButton(
                onPressed: () => RankingModal.show(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: Text(
                  strings.rankingTitle,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String text, bool active, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
