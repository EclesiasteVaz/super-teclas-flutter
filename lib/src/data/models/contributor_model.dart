class ContributorModel {
  final String name;
  final String headline;
  final String imageUrl;
  final String role;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? portfolioUrl;

  const ContributorModel({
    required this.name,
    required this.headline,
    required this.imageUrl,
    this.role = 'Open Source',
    this.linkedinUrl,
    this.githubUrl,
    this.portfolioUrl,
  });

  bool get isAsset => imageUrl.startsWith('assets/');

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'headline': headline,
      'imageUrl': imageUrl,
      'role': role,
      'linkedinUrl': linkedinUrl,
      'githubUrl': githubUrl,
      'portfolioUrl': portfolioUrl,
    };
  }

  factory ContributorModel.fromMap(Map<String, dynamic> map) {
    return ContributorModel(
      name: map['name'] ?? '',
      headline: map['headline'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      role: map['role'] ?? 'Open Source',
      linkedinUrl: map['linkedinUrl'],
      githubUrl: map['githubUrl'],
      portfolioUrl: map['portfolioUrl'],
    );
  }
}
