import 'package:flutter_test/flutter_test.dart';
import 'package:super_teclas/src/data/models/contributor_model.dart';

void main() {
  group('ContributorModel', () {
    test('creates model with required fields', () {
      const contributor = ContributorModel(
        name: 'Jane Doe',
        headline: 'UI Designer',
        imageUrl: 'assets/images/contributors/jane.jpg',
      );

      expect(contributor.name, 'Jane Doe');
      expect(contributor.headline, 'UI Designer');
      expect(contributor.imageUrl, 'assets/images/contributors/jane.jpg');
      expect(contributor.role, 'Open Source');
      expect(contributor.isAsset, isTrue);
      expect(contributor.linkedinUrl, isNull);
      expect(contributor.githubUrl, isNull);
    });

    test('serializes to and from map', () {
      const original = ContributorModel(
        name: 'Francisco Ganga',
        headline: 'UI/UX Designer',
        imageUrl: 'assets/images/contributors/francisco_ganga.jpg',
        role: 'UI/UX Designer',
        linkedinUrl: 'https://www.linkedin.com/in/franciscoganga/',
        githubUrl: 'https://github.com/franciscoganga',
        portfolioUrl: 'https://franciscoganga.design',
      );

      final map = original.toMap();
      final fromMap = ContributorModel.fromMap(map);

      expect(fromMap.name, 'Francisco Ganga');
      expect(fromMap.headline, 'UI/UX Designer');
      expect(fromMap.imageUrl,
          'assets/images/contributors/francisco_ganga.jpg');
      expect(fromMap.role, 'UI/UX Designer');
      expect(fromMap.linkedinUrl,
          'https://www.linkedin.com/in/franciscoganga/');
      expect(fromMap.githubUrl, 'https://github.com/franciscoganga');
      expect(fromMap.portfolioUrl, 'https://franciscoganga.design');
      expect(fromMap.isAsset, isTrue);
    });
  });
}
