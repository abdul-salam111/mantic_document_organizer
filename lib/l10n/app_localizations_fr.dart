// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get splashTagline => 'Organisateur de documents';

  @override
  String get onboardingHeadline =>
      'Tous vos documents,\nparfaitement organisés';

  @override
  String get onboardingSubtitle =>
      'Numérisez, classez et retrouvez chaque document important en quelques secondes — le tout stocké en toute sécurité sur votre appareil, même hors ligne.';

  @override
  String get onboardingGetStarted => 'Commencer';

  @override
  String get onboardingNoSignIn =>
      'Aucune connexion requise — vos documents restent sur cet appareil.';

  @override
  String get navHome => 'Accueil';

  @override
  String get navAllDocs => 'Documents';

  @override
  String get navFavorites => 'Favoris';

  @override
  String get navProfile => 'Profil';

  @override
  String get homeSearchHint => 'Rechercher des documents';

  @override
  String get recentFiles => 'Fichiers récents';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get categories => 'Catégories';

  @override
  String get uncategorized => 'Sans catégorie';

  @override
  String get newCategory => 'Nouvelle catégorie';

  @override
  String fileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers',
      one: '$count fichier',
    );
    return '$_temp0';
  }

  @override
  String get profileTooltip => 'Profil';

  @override
  String get allDocsTitle => 'Documents';

  @override
  String get allDocsSearchHint => 'Rechercher des documents ou des catégories';

  @override
  String get allCategoryTab => 'Tous';

  @override
  String get noDocumentsFound => 'Aucun document trouvé';

  @override
  String nothingInCategoryYet(String category) {
    return 'Rien dans « $category » pour l\'instant';
  }

  @override
  String nothingMatchesQueryInCategory(String query, String category) {
    return 'Rien ne correspond à « $query » dans « $category »';
  }

  @override
  String get favoritesTitle => 'Favoris';

  @override
  String get noFavoritesYet => 'Aucun favori pour l\'instant';

  @override
  String get favoritesEmptySubtitle =>
      'Les documents que vous ajoutez aux favoris apparaîtront ici';

  @override
  String get removeFromFavorites => 'Retirer des favoris';

  @override
  String get profileTitle => 'Profil';

  @override
  String get guest => 'Invité';

  @override
  String get account => 'Compte';

  @override
  String get localOnlyStatus =>
      'Local uniquement — vos documents restent sur cet appareil';

  @override
  String get setUpBackup => 'Configurer la sauvegarde';

  @override
  String get trash => 'Corbeille';

  @override
  String get signOut => 'Déconnexion';

  @override
  String get settings => 'Paramètres';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get language => 'Langue';

  @override
  String get addDocumentTitle => 'Ajouter un document';

  @override
  String get addADocument => 'Ajouter un document';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String comingSoonToast(String name) {
    return '$name — bientôt disponible';
  }

  @override
  String get pressBackAgainToExit =>
      'Appuyez de nouveau sur retour pour quitter';

  @override
  String get pageNotFound => 'Page introuvable';

  @override
  String pageNotFoundSubtitle(String path) {
    return 'Nous n\'avons pas trouvé « $path ».';
  }

  @override
  String get goBack => 'Retour';
}
