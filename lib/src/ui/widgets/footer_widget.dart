import 'package:flutter/material.dart';
import 'package:super_teclas/src/data/i18n/app_strings.dart';
import 'package:super_teclas/src/ui/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  static const _githubUrl = 'https://github.com/EclesiasteVaz/super-teclas-flutter';
  static const _facebookUrl = 'https://www.facebook.com/profile.php?id=61556754993346';
  static const _supportUrl = 'https://github.com/EclesiasteVaz/super-teclas-flutter/issues';

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.from(context);
    final isWide = MediaQuery.of(context).size.width > 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 20,
        vertical: 32,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 16,
        children: [
          _buildBrand(strings),
          _buildLinks(),
        ],
      ),
    );
  }

  Widget _buildBrand(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.superTeclasTitle,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          strings.footerTagline,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildLinks() {
    final links = [
      ('GitHub', _githubUrl),
      ('Facebook', _facebookUrl),
      ('Suporte', _supportUrl),
    ];

    return Wrap(
      spacing: 20,
      runSpacing: 10,
      children: links.map((link) {
        return InkWell(
          onTap: () => _openUrl(link.$2),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              link.$1,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
