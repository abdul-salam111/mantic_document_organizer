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
  String get homeSearchHint => 'Rechercher des catégories et documents';

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
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '$count résultat',
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
  String nothingMatchesQuery(String query) {
    return 'Rien ne correspond à « $query »';
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
  String get trashSubtitle => 'Récupérer les documents récemment supprimés';

  @override
  String get settingsSubtitle => 'Apparence, langue, catégories et sécurité';

  @override
  String get signOut => 'Déconnexion';

  @override
  String get statDocuments => 'Documents';

  @override
  String get statCategories => 'Catégories';

  @override
  String get statFavorites => 'Favoris';

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
  String get addCategory => 'Ajouter une catégorie';

  @override
  String get manageCategories => 'Gérer les catégories';

  @override
  String get searchCategories => 'Rechercher des catégories';

  @override
  String get noCategoriesFound => 'Aucune catégorie trouvée';

  @override
  String get categoryNameLabel => 'Nom de la catégorie';

  @override
  String get categoryNameHint => 'p. ex. Relevés bancaires';

  @override
  String get categoryNameRequired => 'Le nom de la catégorie est requis';

  @override
  String get categoryNameTaken => 'Cette catégorie existe déjà';

  @override
  String get chooseIcon => 'Choisir une icône';

  @override
  String get searchIcons => 'Rechercher des icônes';

  @override
  String get noIconsFound => 'Aucune icône trouvée';

  @override
  String get chooseColor => 'Choisir une couleur';

  @override
  String get create => 'Créer';

  @override
  String get done => 'Terminé';

  @override
  String categoryCreatedToast(String name) {
    return 'Catégorie « $name » créée';
  }

  @override
  String get editCategory => 'Modifier la catégorie';

  @override
  String get save => 'Enregistrer';

  @override
  String categoryUpdatedToast(String name) {
    return 'Catégorie « $name » mise à jour';
  }

  @override
  String get deleteCategory => 'Supprimer la catégorie';

  @override
  String deleteCategoryConfirm(String name) {
    return 'Supprimer « $name » ? Cette action est irréversible.';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String categoryDeletedToast(String name) {
    return 'Catégorie « $name » supprimée';
  }

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnées',
      one: '$count sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String deleteCategoriesConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer $count catégories ? Cette action est irréversible.',
      one: 'Supprimer cette catégorie ? Cette action est irréversible.',
    );
    return '$_temp0';
  }

  @override
  String categoriesDeletedToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catégories supprimées',
      one: 'Catégorie supprimée',
    );
    return '$_temp0';
  }

  @override
  String get security => 'Sécurité';

  @override
  String get biometricUnlock => 'Déverrouillage par empreinte';

  @override
  String get faceIdUnlock => 'Déverrouillage Face ID';

  @override
  String get touchIdUnlock => 'Déverrouillage Touch ID';

  @override
  String get biometricUnlockGeneric => 'Déverrouillage biométrique';

  @override
  String get biometricUnlockSubtitle =>
      'Exiger votre empreinte ou votre visage pour ouvrir l\'application';

  @override
  String get biometricUnavailable =>
      'L\'authentification biométrique n\'est pas configurée sur cet appareil';

  @override
  String get biometricAuthFailed => 'Échec de l\'authentification';

  @override
  String get biometricPromptReason => 'Authentifiez-vous pour continuer';

  @override
  String get support => 'Assistance';

  @override
  String get rateApp => 'Évaluer l\'application';

  @override
  String get shareApp => 'Partager l\'application';

  @override
  String get shareAppMessage =>
      'Découvrez Mantic Document Organizer : numérisez, organisez et retrouvez chaque document important en quelques secondes.';

  @override
  String get appLocked => 'Application verrouillée';

  @override
  String get unlockToContinue => 'Authentifiez-vous pour continuer';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get addDocumentTitle => 'Ajouter un document';

  @override
  String get editDocumentTitle => 'Modifier le fichier';

  @override
  String get documentTitleLabel => 'Titre';

  @override
  String get documentTitleHint => 'p. ex. Numérisation de passeport';

  @override
  String get documentTitleRequired => 'Le titre est requis';

  @override
  String get categoryLabel => 'Catégorie';

  @override
  String get selectCategory => 'Sélectionner une catégorie';

  @override
  String get tags => 'Étiquettes';

  @override
  String get tagsHint => 'p. ex. facture-2026';

  @override
  String tagsHelper(int maxLength) {
    return 'Lettres, chiffres, - et _ uniquement, $maxLength caractères maximum';
  }

  @override
  String tagErrorLimitReached(int maxCount) {
    return 'Vous pouvez ajouter jusqu\'à $maxCount étiquettes';
  }

  @override
  String tagErrorTooLong(int maxLength) {
    return 'Les étiquettes doivent comporter $maxLength caractères maximum';
  }

  @override
  String get tagErrorInvalidCharacters =>
      'Utilisez uniquement des lettres, chiffres, - et _ (pas d\'espaces)';

  @override
  String get tagErrorDuplicate => 'Cette étiquette a déjà été ajoutée';

  @override
  String get documentExpirable => 'Ce document expire';

  @override
  String expiresOn(String date) {
    return 'Expire le $date';
  }

  @override
  String get tapToSetExpiryDate =>
      'Appuyez pour définir la date et l\'heure d\'expiration';

  @override
  String get attachments => 'Pièces jointes';

  @override
  String get extractingTextStatus => 'Extraction du texte…';

  @override
  String get organizingWithAiStatus => 'Organisation avec l\'IA…';

  @override
  String get camera => 'Appareil photo';

  @override
  String get gallery => 'Galerie';

  @override
  String get files => 'Fichiers';

  @override
  String get filesImagesNotAllowed =>
      'Les images ne sont pas acceptées ici — utilisez l\'appareil photo ou la galerie';

  @override
  String get scanFailedToast => 'Échec de la numérisation — veuillez réessayer';

  @override
  String documentCreatedToast(String name) {
    return '« $name » ajouté';
  }

  @override
  String documentUpdatedToast(String name) {
    return '« $name » mis à jour';
  }

  @override
  String get searchDocumentsHint => 'Rechercher des documents';

  @override
  String get sortBy => 'Trier par';

  @override
  String get sortNewestFirst => 'Plus récents d\'abord';

  @override
  String get sortOldestFirst => 'Plus anciens d\'abord';

  @override
  String get sortNameAZ => 'Nom (A-Z)';

  @override
  String get addToFavorites => 'Ajouter aux favoris';

  @override
  String get share => 'Partager';

  @override
  String get rename => 'Renommer';

  @override
  String get move => 'Déplacer';

  @override
  String get renameDocument => 'Renommer le document';

  @override
  String documentRenamedToast(String name) {
    return 'Renommé en « $name »';
  }

  @override
  String documentMovedToast(String category) {
    return 'Déplacé vers « $category »';
  }

  @override
  String get deleteDocument => 'Supprimer le document';

  @override
  String deleteDocumentConfirm(String name) {
    return 'Supprimer « $name » ? Cette action est irréversible.';
  }

  @override
  String documentDeletedToast(String name) {
    return '« $name » supprimé';
  }

  @override
  String get noPreviewAvailable =>
      'Aperçu non disponible pour ce type de fichier';

  @override
  String addedOn(String date) {
    return 'Ajouté le $date';
  }

  @override
  String get aiAssistantTitle => 'Demander à Mantic';

  @override
  String get aiAssistantInputHint => 'Posez une question sur vos documents...';

  @override
  String get aiAssistantEmptyTitle =>
      'Posez-moi une question sur vos documents';

  @override
  String get aiAssistantEmptySubtitle =>
      'Je peux parcourir ce que vous avez numérisé et trouver la réponse — essayez l\'une de ces questions, ou posez la vôtre.';

  @override
  String get aiAssistantExample1 =>
      'Quand ma carte d\'identité expire-t-elle ?';

  @override
  String get aiAssistantExample2 => 'Montre-moi les factures du mois dernier';

  @override
  String get aiAssistantExample3 =>
      'Quelle était ma dernière facture d\'électricité ?';

  @override
  String get aiAssistantGenericError =>
      'Impossible de contacter l\'assistant IA — vérifiez votre connexion et réessayez.';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String comingSoonToast(String name) {
    return '$name — bientôt disponible';
  }

  @override
  String get pageNotFound => 'Page introuvable';

  @override
  String pageNotFoundSubtitle(String path) {
    return 'Nous n\'avons pas trouvé « $path ».';
  }

  @override
  String get goBack => 'Retour';
}
