// Barrel export for lib/core/widgets — the shared UI kit (buttons, text
// fields, app bar, loading states, etc.), plus the packages every screen
// that uses them typically also needs: iconsax (icons used by the kit) and
// provider (ChangeNotifierProvider/Consumer for wiring a ViewModel to a page).
export 'package:iconsax/iconsax.dart';
export 'package:provider/provider.dart';

export 'appbar/custom_appbar.dart';
export 'branding/app_logo.dart';
export 'buttons/custom_button.dart';
export 'feedback/loading_indicator.dart';
export 'feedback/loading_popup.dart';
export 'inputs/custom_dropdown_textfield.dart';
export 'inputs/custom_searchfield.dart';
export 'inputs/custom_textfield.dart';
