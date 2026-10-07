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
  String get navProfile => 'Perfil';

  @override
  String get homeSearchHint => 'Busca en tus documentos...';

  @override
  String get askAi => 'Preguntar a la IA';

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
  String get signIn => 'Iniciar sesión';

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
  String get dataUsage => 'Uso de datos';

  @override
  String get useMobileData => 'Usar datos móviles';

  @override
  String get useMobileDataSubtitle =>
      'Permitir sincronizar, subir y descargar con datos móviles. Si está desactivado, solo ocurre con Wi-Fi';

  @override
  String get wifiOnlySyncToast =>
      'Esperando Wi-Fi para sincronizar. Activa los datos móviles en Ajustes para sincronizar en cualquier momento';

  @override
  String get support => 'Soporte';

  @override
  String get rateApp => 'Calificar app';

  @override
  String get shareApp => 'Compartir app';

  @override
  String get shareAppMessage =>
      'Descubre Dockitly: escanea, organiza y encuentra cualquier documento importante en segundos.';

  @override
  String get appLocked => 'App bloqueada';

  @override
  String get unlockToContinue => 'Autentícate para continuar';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get addDocumentTitle => 'Agregar documento';

  @override
  String get addPageTitle => 'Añadir página';

  @override
  String get add => 'Agregar';

  @override
  String get addPagesAction => 'Añadir páginas';

  @override
  String get addFiles => 'Agregar archivos';

  @override
  String get editDocumentTitle => 'Editar archivo';

  @override
  String get edit => 'Editar';

  @override
  String get update => 'Actualizar';

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
  String tagErrorLimitReached(int maxCount) {
    return 'Puedes agregar hasta $maxCount etiquetas';
  }

  @override
  String tagErrorTooLong(int maxLength) {
    return 'Las etiquetas deben tener $maxLength caracteres o menos';
  }

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
  String get attachmentRequired => 'Agrega al menos un documento para guardar';

  @override
  String get extractingTextStatus => 'Extrayendo texto…';

  @override
  String get organizingWithAiStatus => 'Organizando con IA…';

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
  String documentUpdatedToast(String name) {
    return '\"$name\" actualizado';
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
  String get exportAsPdf => 'Exportar como PDF';

  @override
  String get exportPdfFailedToast =>
      'No se pudo crear el PDF. Inténtalo de nuevo.';

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get deselectAll => 'Deseleccionar todo';

  @override
  String get shareOption => 'Compartir';

  @override
  String get preparingPdfMessage => 'Preparando PDF…';

  @override
  String get addingPagesMessage => 'Añadiendo páginas…';

  @override
  String get shareAsPdfOption => 'Compartir como PDF';

  @override
  String get shareAsImagesOption => 'Compartir como imágenes';

  @override
  String get exportEachPageAsPdfOption => 'Exportar cada página como PDF';

  @override
  String get saveToGalleryOption => 'Guardar en la galería';

  @override
  String get noFilesSelectedToast =>
      'Selecciona al menos un archivo para compartir';

  @override
  String get savedToGalleryToast => 'Guardado en la galería';

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
  String deleteDocumentConfirm(String name, int days) {
    return '¿Mover \"$name\" a la papelera? Podrás restaurarlo durante $days días antes de que se elimine definitivamente.';
  }

  @override
  String documentTrashedToast(String name) {
    return '\"$name\" movido a la papelera';
  }

  @override
  String deleteSelectedFilesConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar $count páginas? Esta acción no se puede deshacer.',
      one: '¿Eliminar esta página? Esta acción no se puede deshacer.',
    );
    return '$_temp0';
  }

  @override
  String selectedFilesDeletedToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas eliminadas',
      one: 'Página eliminada',
    );
    return '$_temp0';
  }

  @override
  String trashDocumentsConfirm(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '¿Mover $count documentos a la papelera? Podrás restaurarlos durante $days días antes de que se eliminen definitivamente.',
      one:
          '¿Mover este documento a la papelera? Podrás restaurarlo durante $days días antes de que se elimine definitivamente.',
    );
    return '$_temp0';
  }

  @override
  String documentsTrashedToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos movidos a la papelera',
      one: 'Documento movido a la papelera',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyTitle => 'La papelera está vacía';

  @override
  String get trashEmptySubtitle =>
      'Los documentos eliminados aparecen aquí hasta que se restauran o se eliminan definitivamente.';

  @override
  String trashRetentionRemaining(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Quedan $days días',
      one: 'Queda 1 día',
      zero: 'Se elimina hoy',
    );
    return '$_temp0';
  }

  @override
  String get restore => 'Restaurar';

  @override
  String documentRestoredToast(String name) {
    return '\"$name\" restaurado';
  }

  @override
  String get deleteForeverTitle => 'Eliminar definitivamente';

  @override
  String deleteForeverConfirm(String name) {
    return '¿Eliminar \"$name\" definitivamente? Esta acción no se puede deshacer.';
  }

  @override
  String documentPermanentlyDeletedToast(String name) {
    return '\"$name\" eliminado definitivamente';
  }

  @override
  String get emptyTrash => 'Vaciar papelera';

  @override
  String get emptyTrashTitle => '¿Vaciar la papelera?';

  @override
  String emptyTrashConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar definitivamente los $count elementos de la papelera?',
      one: '¿Eliminar definitivamente 1 elemento de la papelera?',
    );
    return '$_temp0 Esta acción no se puede deshacer.';
  }

  @override
  String get trashEmptiedToast => 'Papelera vaciada';

  @override
  String get noPreviewAvailable =>
      'Vista previa no disponible para este tipo de archivo';

  @override
  String get documentExpiringSoonTitle => 'Documento por vencer';

  @override
  String documentExpiringSoonBody(String title, int days) {
    return '\"$title\" vence en $days días';
  }

  @override
  String get documentExpiresTodayTitle => 'El documento vence hoy';

  @override
  String documentExpiresTodayBody(String title) {
    return '\"$title\" vence hoy';
  }

  @override
  String addedOn(String date) {
    return 'Añadido el $date';
  }

  @override
  String get expiringSoonDigestTitle => 'Documentos por vencer';

  @override
  String expiringSoonDigestBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos vencen este mes',
      one: '1 documento vence este mes',
    );
    return '$_temp0';
  }

  @override
  String get expiringSoonTitle => 'Por vencer';

  @override
  String get expiringSoonEmptyTitle => 'Nada por vencer';

  @override
  String get expiringSoonEmptySubtitle =>
      'Aquí aparecerán los documentos con una fecha de vencimiento próxima.';

  @override
  String get aiAssistantTitle => 'Pregunta a Dockitly';

  @override
  String get aiAssistantInputHint => 'Pregunta sobre tus documentos...';

  @override
  String get aiAssistantEmptyTitle =>
      'Pregúntame lo que quieras sobre tus documentos';

  @override
  String get aiAssistantEmptySubtitle =>
      'Puedo revisar lo que has escaneado y encontrar la respuesta — prueba una de estas o escribe tu propia pregunta.';

  @override
  String get aiAssistantExample1 => '¿Cuándo caduca mi tarjeta de identidad?';

  @override
  String get aiAssistantExample2 => 'Muéstrame las facturas del mes pasado';

  @override
  String get aiAssistantExample3 =>
      '¿Cuál fue mi última factura de electricidad?';

  @override
  String get aiAssistantGenericError =>
      'No pude contactar al asistente de IA — revisa tu conexión e inténtalo de nuevo.';

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

  @override
  String get operationFailedToast =>
      'No se pudo completar la acción. Inténtalo de nuevo.';
}
