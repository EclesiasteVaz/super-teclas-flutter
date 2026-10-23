import 'package:super_teclas/src/data/models/contributor_model.dart';

class ContributorsData {
  static const List<ContributorModel> contributors = [
    ContributorModel(
      name: 'Eclesiaste Vaz',
      headline: 'Mobile Engineer',
      imageUrl: 'assets/images/contributors/eclesiaste_vaz.jpeg',
      role: 'Mobile Engineer',
      linkedinUrl: 'https://www.linkedin.com/in/eclesiaste-vaz/',
      githubUrl: 'https://github.com/EclesiasteVaz',
    ),
    ContributorModel(
      name: 'Francisco Ganga',
      headline: 'UI/UX Designer',
      imageUrl: 'assets/images/contributors/francisco_ganga.jpg',
      role: 'UI/UX Designer',
      linkedinUrl: 'https://www.linkedin.com/in/franciscoganga/',
    ),
  ];
}
