import 'package:flutter/material.dart';
import 'package:super_teclas/src/data/contributors/contributors_data.dart';
import 'package:super_teclas/src/data/i18n/app_strings.dart';
import 'package:super_teclas/src/data/models/contributor_model.dart';
import 'package:super_teclas/src/ui/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ContributorsPage extends StatefulWidget {
  const ContributorsPage({super.key});

  @override
  State<ContributorsPage> createState() => _ContributorsPageState();
}

class _ContributorsPageState extends State<ContributorsPage> {
  static const _githubRepoUrl =
      'https://github.com/EclesiasteVaz/super-teclas-flutter';
  String _selectedRole = 'all';

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
    const allContributors = ContributorsData.contributors;

    final filtered = allContributors.where((c) {
      if (_selectedRole == 'all') return true;
      if (_selectedRole == 'design') {
        return c.role.toLowerCase().contains('design');
      }
      return !c.role.toLowerCase().contains('design');
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.surfaceBorder),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          strings.contributors,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(strings),
                const SizedBox(height: 24),
                _buildFilterChips(strings),
                const SizedBox(height: 24),
                _buildContributorsGrid(filtered, strings),
                const SizedBox(height: 36),
                _buildCallToAction(strings, isWide),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.badgeBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: AppColors.primary,
              ),
              SizedBox(width: 6),
              Text(
                'EQUIPA & COMUNIDADE OPEN SOURCE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          strings.contributorsTitle,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            strings.contributorsSubtitle,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(AppStrings strings) {
    final filters = [
      ('all', strings.allWords),
      ('opensource', strings.openSource),
      ('design', strings.design),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((filter) {
        final isSelected = _selectedRole == filter.$1;
        return ChoiceChip(
          label: Text(filter.$2),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedRole = filter.$1);
            }
          },
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surfaceElevated,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildContributorsGrid(
    List<ContributorModel> contributors,
    AppStrings strings,
  ) {
    final showNextCard = _selectedRole == 'all' || _selectedRole == 'opensource';

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 780 ? 2 : 1;
        final totalCards = contributors.length + (showNextCard ? 1 : 0);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCards,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            mainAxisExtent: 195,
          ),
          itemBuilder: (context, index) {
            if (index < contributors.length) {
              return _buildContributorCard(contributors[index]);
            }
            return _buildNextContributorCard(strings);
          },
        );
      },
    );
  }

  Widget _buildContributorCard(ContributorModel contributor) {
    final isDesign = contributor.role.toLowerCase().contains('design');
    final accentColor = isDesign ? const Color(0xFF00D26A) : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(contributor, accentColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  contributor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  contributor.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    contributor.role,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (contributor.linkedinUrl != null)
                      _buildSocialButton(
                        label: 'LinkedIn',
                        icon: Icons.link,
                        onTap: () => _openUrl(contributor.linkedinUrl!),
                      ),
                    if (contributor.githubUrl != null)
                      _buildSocialButton(
                        label: 'GitHub',
                        icon: Icons.code,
                        onTap: () => _openUrl(contributor.githubUrl!),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextContributorCard(AppStrings strings) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.badgeBackground,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person_add_alt_1_rounded,
                size: 30,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  strings.nextContributorTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  strings.nextContributorSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        strings.nextContributorBadge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _openUrl(_githubRepoUrl),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              strings.joinTheTeam,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ],
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
    );
  }

  Widget _buildAvatar(ContributorModel contributor, Color accentColor) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accentColor, width: 2),
      ),
      child: ClipOval(
        child: contributor.isAsset
            ? Image.asset(
                contributor.imageUrl,
                width: 68,
                height: 68,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackInitials(contributor.name),
              )
            : Image.network(
                contributor.imageUrl,
                width: 68,
                height: 68,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackInitials(contributor.name),
              ),
      ),
    );
  }

  Widget _buildFallbackInitials(String name) {
    final initials = name.isNotEmpty
        ? name
            .trim()
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0] : '')
            .join()
            .toUpperCase()
        : '?';

    return Container(
      color: AppColors.surfaceElevated,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallToAction(AppStrings strings, bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 32 : 20,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.badgeBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Icon(
              Icons.terminal_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.contribute,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.contributeSubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _openUrl(_githubRepoUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GitHub',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
