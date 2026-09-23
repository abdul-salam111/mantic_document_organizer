import 'package:flutter/material.dart';

import '../local_storage/local_storage_exports.dart';
import '../../l10n/app_localizations.dart';

/// Controls and persists the app's language preference.
///
/// Mirrors ThemeController's shape — a `ChangeNotifier` DI singleton,
/// loaded once before the first frame (see main.dart) so there's no
/// flash of the wrong language.
class LocaleController extends ChangeNotifier {
  static const String _storageKey = 'locale';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  Future<void> loadLocale() async {
    final value = await storage.readValues(_storageKey);
    if (value != null &&
        AppLocalizations.supportedLocales.any((l) => l.languageCode == value)) {
      _locale = Locale(value);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    try {
      await storage.setValues(_storageKey, locale.languageCode);
    } catch (_) {
      // Best-effort persistence — the chosen language still applies for
      // the rest of this session even if saving it fails.
    }
  }
}
