// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get splashTagline => 'Organizador de Documentos';

  @override
  String get onboardingHeadline =>
      'Todos tus documentos,\norganizados con estilo';

  @override
  String get onboardingSubtitle =>
      'Escanea, clasifica y encuentra cualquier documento importante en segundos, todo almacenado de forma segura en tu dispositivo, incluso sin conexión.';

  @override
  String get onboardingGetStarted => 'Comenzar';

  @override
  String get onboardingNoSignIn =>
      'No se requiere iniciar sesión: tus documentos permanecen en este dispositivo.';

  @override
  String get navHome => 'Inicio';

  @override
  String get navAllDocs => 'Documentos';

  @override
  String get navFavorites => 'Favoritos';

  @override
  String get homeSearchHint => 'Buscar categorías y documentos';

  @override
  String get recentFiles => 'Archivos recientes';

  @override
  String get seeAll => 'Ver todos';

  @override
  String get categories => 'Categorías';

  @override
  String get uncategorized => 'Sin categoría';

  @override
  String get newCategory => 'Nueva categoría';

  @override
  String fileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '$count archivo',
    );
    return '$_temp0';
  }

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '$count resultado',
    );
    return '$_temp0';
  }

  @override
  String get profileTooltip => 'Perfil';

  @override
  String get allDocsTitle => 'Documentos';

  @override
  String get allDocsSearchHint => 'Buscar documentos o categorías';

  @override
  String get allCategoryTab => 'Todos';

  @override
  String get noDocumentsFound => 'No se encontraron documentos';

  @override
  String nothingInCategoryYet(String category) {
    return 'Nada en \"$category\" todavía';
  }

  @override
  String nothingMatchesQueryInCategory(String query, String category) {
    return 'Nada coincide con \"$query\" en \"$category\"';
  }

  @override
  String nothingMatchesQuery(String query) {
    return 'Nada coincide con \"$query\"';
  }

  @override
  String get favoritesTitle => 'Favoritos';

  @override
  String get noFavoritesYet => 'Sin favoritos todavía';

  @override
  String get favoritesEmptySubtitle =>
      'Los documentos que marques como favoritos aparecerán aquí';

  @override
  String get removeFromFavorites => 'Quitar de favoritos';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get guest => 'Invitado';

  @override
  String get account => 'Cuenta';

  @override
  String get localOnlyStatus =>
      'Solo local: tus documentos permanecen en este dispositivo';

  @override
  String get setUpBackup => 'Configurar copia de seguridad';

  @override
  String get trash => 'Papelera';

  @override
  String get trashSubtitle => 'Recupera documentos eliminados recientemente';

  @override
  String get settingsSubtitle => 'Apariencia, idioma, categorías y seguridad';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get statDocuments => 'Documentos';

  @override
  String get statCategories => 'Categorías';

  @override
  String get statFavorites => 'Favoritos';

  @override
  String get settings => 'Configuración';

  @override
  String get appearance => 'Apariencia';

  @override
  String get themeAuto => 'Automático';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get language => 'Idioma';

  @override
  String get addCategory => 'Agregar categoría';

  @override
  String get manageCategories => 'Administrar categorías';

  @override
  String get searchCategories => 'Buscar categorías';

  @override
  String get noCategoriesFound => 'No se encontraron categorías';

  @override
  String get categoryNameLabel => 'Nombre de la categoría';

  @override
  String get categoryNameHint => 'p. ej. Extractos bancarios';

  @override
  String get categoryNameRequired => 'El nombre de la categoría es obligatorio';

  @override
  String get categoryNameTaken => 'Esta categoría ya existe';

  @override
  String get chooseIcon => 'Elige un ícono';

  @override
  String get searchIcons => 'Buscar íconos';

  @override
  String get noIconsFound => 'No se encontraron íconos';

  @override
  String get chooseColor => 'Elige un color';

  @override
  String get create => 'Crear';

  @override
  String get done => 'Listo';

  @override
  String categoryCreatedToast(String name) {
    return 'Categoría \"$name\" creada';
  }

  @override
  String get editCategory => 'Editar categoría';

  @override
  String get save => 'Guardar';

  @override
  String categoryUpdatedToast(String name) {
    return 'Categoría \"$name\" actualizada';
  }

  @override
  String get deleteCategory => 'Eliminar categoría';

  @override
  String deleteCategoryConfirm(String name) {
    return '¿Eliminar \"$name\"? Esta acción no se puede deshacer.';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String categoryDeletedToast(String name) {
    return 'Categoría \"$name\" eliminada';
  }

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionadas',
      one: '$count seleccionada',
    );
    return '$_temp0';
  }

  @override
  String deleteCategoriesConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar $count categorías? Esta acción no se puede deshacer.',
      one: '¿Eliminar esta categoría? Esta acción no se puede deshacer.',
    );
    return '$_temp0';
  }

  @override
  String categoriesDeletedToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categorías eliminadas',
      one: 'Categoría eliminada',
    );
    return '$_temp0';
  }

  @override
  String get security => 'Seguridad';

  @override
  String get biometricUnlock => 'Desbloqueo por huella';

  @override
  String get faceIdUnlock => 'Desbloqueo con Face ID';

  @override
  String get touchIdUnlock => 'Desbloqueo con Touch ID';

  @override
  String get biometricUnlockGeneric => 'Desbloqueo biométrico';

  @override
  String get biometricUnlockSubtitle =>
      'Requiere tu huella o rostro para abrir la app';

  @override
  String get biometricUnavailable =>
      'La autenticación biométrica no está configurada en este dispositivo';

  @override
  String get biometricAuthFailed => 'Autenticación fallida';

  @override
  String get biometricPromptReason => 'Autentícate para continuar';

  @override
  String get support => 'Soporte';

  @override
  String get rateApp => 'Calificar app';

  @override
  String get shareApp => 'Compartir app';

  @override
  String get shareAppMessage =>
      'Descubre Mantic Document Organizer: escanea, organiza y encuentra cualquier documento importante en segundos.';

  @override
  String get appLocked => 'App bloqueada';

  @override
  String get unlockToContinue => 'Autentícate para continuar';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get addDocumentTitle => 'Agregar documento';

  @override
  String get documentTitleLabel => 'Título';

  @override
  String get documentTitleHint => 'p. ej. Escaneo de pasaporte';

  @override
  String get documentTitleRequired => 'El título es obligatorio';

  @override
  String get categoryLabel => 'Categoría';

  @override
  String get selectCategory => 'Seleccionar categoría';

  @override
  String get tags => 'Etiquetas';

  @override
  String get tagsHint => 'p. ej. factura-2026';

  @override
  String tagsHelper(int maxLength) {
    return 'Solo letras, números, - y _, hasta $maxLength caracteres cada una';
  }

  @override
  String tagErrorLimitReached(int maxCount) {
    return 'Puedes agregar hasta $maxCount etiquetas';
  }

  @override
  String tagErrorTooLong(int maxLength) {
    return 'Las etiquetas deben tener $maxLength caracteres o menos';
  }

  @override
  String get tagErrorInvalidCharacters =>
      'Usa solo letras, números, - y _ (sin espacios)';

  @override
  String get tagErrorDuplicate => 'Esa etiqueta ya fue agregada';

  @override
  String get documentExpirable => 'Este documento caduca';

  @override
  String expiresOn(String date) {
    return 'Caduca el $date';
  }

  @override
  String get tapToSetExpiryDate =>
      'Toca para establecer la fecha y hora de caducidad';

  @override
  String get attachments => 'Adjuntos';

  @override
  String get camera => 'Cámara';

  @override
  String get gallery => 'Galería';

  @override
  String get files => 'Archivos';

  @override
  String get filesImagesNotAllowed =>
      'Las imágenes no se aceptan aquí — usa la cámara o la galería';

  @override
  String get scanFailedToast => 'Error al escanear — inténtalo de nuevo';

  @override
  String documentCreatedToast(String name) {
    return '\"$name\" agregado';
  }

  @override
  String get searchDocumentsHint => 'Buscar documentos';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get sortNewestFirst => 'Más recientes primero';

  @override
  String get sortOldestFirst => 'Más antiguos primero';

  @override
  String get sortNameAZ => 'Nombre (A-Z)';

  @override
  String get addToFavorites => 'Añadir a favoritos';

  @override
  String get share => 'Compartir';

  @override
  String get rename => 'Renombrar';

  @override
  String get move => 'Mover';

  @override
  String get renameDocument => 'Renombrar documento';

  @override
  String documentRenamedToast(String name) {
    return 'Renombrado a \"$name\"';
  }

  @override
  String documentMovedToast(String category) {
    return 'Movido a \"$category\"';
  }

  @override
  String get deleteDocument => 'Eliminar documento';

  @override
  String deleteDocumentConfirm(String name) {
    return '¿Eliminar \"$name\"? Esta acción no se puede deshacer.';
  }

  @override
  String documentDeletedToast(String name) {
    return '\"$name\" eliminado';
  }

  @override
  String get noPreviewAvailable =>
      'Vista previa no disponible para este tipo de archivo';

  @override
  String addedOn(String date) {
    return 'Añadido el $date';
  }

  @override
  String get comingSoon => 'Próximamente';

  @override
  String comingSoonToast(String name) {
    return '$name — próximamente';
  }

  @override
  String get pageNotFound => 'Página no encontrada';

  @override
  String pageNotFoundSubtitle(String path) {
    return 'No pudimos encontrar \"$path\".';
  }

  @override
  String get goBack => 'Volver';
}
