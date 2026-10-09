import 'package:mantic_doc_org/core/utils/persist_action.dart';
import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../../../../core/constants/constants_exports.dart';
import '../../../../../core/di/di_exports.dart';
import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../../../routes/routes_exports.dart';
import '../../../../home/home_exports.dart';
import '../viewmodels/add_document_viewmodel.dart';

const _formControlHeight = 55.0;

class AddDocumentView extends StatelessWidget {
  /// Preselects the category picker — set when opened via a category's
  /// document list "+" button, so the user doesn't have to reselect the
  /// category they were already looking at.
  final CategoryItem? initialCategory;

  /// Set when opened via the document viewer's Edit button — switches this
  /// screen into edit mode, prefilling every field and updating the
  /// existing document on save instead of creating a new one.
  final DocumentItem? editingDocument;

  /// Set when opened via a "Share into Docketly" intent from another app
  /// (see ShareIntentService/ShareIntentListener) — attaches these files
  /// immediately, same as a fresh camera/gallery/file pick.
  final List<String>? initialSharedFilePaths;

  /// Set when opened via the navbar's "+" button, or via the document
  /// viewer's "Add Pages" button, after the user already chose a source
  /// (Camera/Gallery/Files) from [AttachmentSourceSheet] — triggers that
  /// picker automatically once this screen loads, instead of making the
  /// user tap it again from [_AttachmentSection]. Works whether this is a
  /// fresh document or [editingDocument] is set.
  final AttachmentSource? initialSource;

  const AddDocumentView({
    super.key,
    this.initialCategory,
    this.editingDocument,
    this.initialSharedFilePaths,
    this.initialSource,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (providerContext) {
        final vm = sl<AddDocumentViewModel>();
        final editing = editingDocument;
        if (editing != null) {
          vm.startEditing(editing);
        } else {
          final category = initialCategory;
          if (category != null) vm.preselectCategory(category);
          final sharedPaths = initialSharedFilePaths;
          if (sharedPaths != null && sharedPaths.isNotEmpty) {
            unawaited(vm.addSharedFiles(sharedPaths));
          }
        }
        final source = initialSource;
        if (source != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            switch (source) {
              case AttachmentSource.camera:
                final failed = await vm.pickFromCamera();
                if (failed && providerContext.mounted) {
                  AppToastsUtils.error(
                    AppLocalizations.of(providerContext).scanFailedToast,
                  );
                }
              case AttachmentSource.gallery:
                await vm.pickFromGallery();
              case AttachmentSource.file:
                final skippedImages = await vm.pickFile();
                if (skippedImages && providerContext.mounted) {
                  AppToastsUtils.warning(
                    AppLocalizations.of(providerContext).filesImagesNotAllowed,
                  );
                }
            }
          });
        }
        return vm;
      },
      child: UnfocusWrapper(
        child: Consumer<AddDocumentViewModel>(
          builder: (context, vm, _) {
            return Scaffold(
              appBar: CustomAppBar(
                title: editingDocument != null
                    ? AppLocalizations.of(context).editDocumentTitle
                    : AppLocalizations.of(context).addDocumentTitle,
              ),
              body: SafeArea(
                bottom: false,
                child: Form(
                  key: vm.formKey,
                  child: ListView(
                    padding: const .symmetric(horizontal: 14, vertical: 20),
                    children: [
                      _AttachmentSection(vm: vm),
                      heightBox(24),
                      CustomTextFormField(
                        label: AppLocalizations.of(context).documentTitleLabel,
                        floatingLabel: true,
                        controller: vm.titleController,
                        // Match the elevated white form controls in light
                        // mode while retaining the dark theme's surface.
                        fillColor: context.surfaceElevated,
                        // Same height as the Tags field's InputDecorator —
                        // a minHeight constraint instead of tall vertical
                        // padding, so the floating label doesn't inflate
                        // this field well past that one.
                        constraints: const BoxConstraints(
                          minHeight: _formControlHeight,
                        ),
                        contentPadding: const .symmetric(horizontal: 16),
                        textCapitalization: .sentences,
                      ),
                      heightBox(20),
                      _CategoryPickerTrigger(vm: vm),
                      heightBox(20),
                      _TagsField(vm: vm),
                      heightBox(20),
                      _ExpirableToggle(vm: vm),
                      heightBox(20),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: SafeArea(
                top: false,
                child: Container(
                  padding: const .symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(),
                  child: CustomButton(
                    isLoading: vm.isSaving,
                    text: vm.isEditing
                        ? AppLocalizations.of(context).update
                        : AppLocalizations.of(context).save,
                    onPressed: () async {
                      if (!vm.validateAttachments()) return;
                      if (!vm.formKey.currentState!.validate()) return;
                      if (!await persistAction(context, () => vm.submit())) {
                        return;
                      }
                      if (!context.mounted) return;
                      // Compute the message and pop *before* showing the
                      // toast — another_flushbar pushes its toast as its
                      // own Navigator route, so popping this screen right
                      // on top of that in-flight push corrupts the
                      // navigator's route lifecycle.
                      final title = vm.titleController.text.trim();

                      final message = editingDocument != null
                          ? AppLocalizations.of(
                              context,
                            ).documentUpdatedToast(title)
                          : AppLocalizations.of(
                              context,
                            ).documentCreatedToast(title);
                      AppNavigator.pop();
                      AppToastsUtils.success(message);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Attachments section — three always-visible source buttons (Camera /
/// Gallery / Files) plus a thumbnail grid of everything picked so far,
/// each removable individually. Matches the reference design's layout
/// more directly than a single tap-to-open-sheet placeholder would.
class _AttachmentSection extends StatelessWidget {
  final AddDocumentViewModel vm;

  const _AttachmentSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SourceButton(
                iconAsset: AppIcons.camera,
                label: AppLocalizations.of(context).camera,
                onTap: () async {
                  final failed = await vm.pickFromCamera();
                  if (failed && context.mounted) {
                    AppToastsUtils.error(
                      AppLocalizations.of(context).scanFailedToast,
                    );
                  }
                },
              ),
            ),
            widthBox(10),
            Expanded(
              child: _SourceButton(
                iconAsset: Platform.isIOS
                    ? AppIcons.galleryIos
                    : AppIcons.galleryAndroid,
                label: AppLocalizations.of(context).gallery,
                onTap: vm.pickFromGallery,
              ),
            ),
            widthBox(10),
            Expanded(
              child: _SourceButton(
                iconAsset: AppIcons.filesIos,
                label: AppLocalizations.of(context).files,
                onTap: () async {
                  final skippedImages = await vm.pickFile();
                  if (skippedImages && context.mounted) {
                    AppToastsUtils.warning(
                      AppLocalizations.of(context).filesImagesNotAllowed,
                    );
                  }
                },
              ),
            ),
          ],
        ),
        if (vm.attachments.isNotEmpty) ...[
          heightBox(14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (index, attachment) in vm.attachments.indexed)
                _AttachmentThumbnail(
                  attachment: attachment,
                  onRemove: () => vm.removeAttachment(attachment),
                  onTap: () => AppNavigator.pushNamed(
                    RouteNames.filePreview,
                    extra: (vm.attachments.map((a) => a.path).toList(), index),
                  ),
                ),
            ],
          ),
        ],
        if (vm.showAttachmentError) ...[
          heightBox(10),
          Text(
            AppLocalizations.of(context).attachmentRequired,
            style: context.bodySmall.copyWith(color: context.error),
          ),
        ],
        if (vm.isProcessingOcr || vm.isAnalyzing) ...[
          heightBox(12),
          _OcrAiStatusLine(
            label: vm.isProcessingOcr
                ? AppLocalizations.of(context).extractingTextStatus
                : AppLocalizations.of(context).organizingWithAiStatus,
          ),
        ],
      ],
    );
  }
}

/// Bottom sheet prompting for a page's source (Camera/Gallery/Files) —
/// shown by the navbar's "+" button before [AddDocumentView] even opens,
/// so the chosen picker can run automatically once it does (see
/// [AddDocumentView.initialSource]) instead of making the user pick again
/// from [_AttachmentSection] after landing on the form.
class AttachmentSourceSheet extends StatelessWidget {
  const AttachmentSourceSheet({super.key});

  static Future<AttachmentSource?> show(BuildContext context) {
    return showModalBottomSheet<AttachmentSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AttachmentSourceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const .fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text(
              AppLocalizations.of(context).addPageTitle,
              style: context.titleMedium.copyWith(fontWeight: .w700),
            ),
            heightBox(16),
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    iconAsset: AppIcons.camera,
                    label: AppLocalizations.of(context).camera,
                    onTap: () =>
                        Navigator.of(context).pop(AttachmentSource.camera),
                  ),
                ),
                widthBox(10),
                Expanded(
                  child: _SourceButton(
                    iconAsset: Platform.isIOS
                        ? AppIcons.galleryIos
                        : AppIcons.galleryAndroid,
                    label: AppLocalizations.of(context).gallery,
                    onTap: () =>
                        Navigator.of(context).pop(AttachmentSource.gallery),
                  ),
                ),
                widthBox(10),
                Expanded(
                  child: _SourceButton(
                    iconAsset: AppIcons.filesIos,
                    label: AppLocalizations.of(context).files,
                    onTap: () =>
                        Navigator.of(context).pop(AttachmentSource.file),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Never blocks the form — attachments, title, and every other field stay
/// fully interactive while this shows. Only appears while
/// [AddDocumentViewModel.isProcessingOcr]/[AddDocumentViewModel.isAnalyzing]
/// is true, so it disappears on its own once the pipeline settles.
class _OcrAiStatusLine extends StatelessWidget {
  final String label;

  const _OcrAiStatusLine({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const LoadingIndicator(size: 14),
        widthBox(8),
        Text(
          label,
          style: context.labelSmall.copyWith(color: context.textSecondary),
        ),
      ],
    );
  }
}

class _SourceButton extends StatelessWidget {
  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  static const double _size = 56;
  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final white = context.white;
    final accent = context.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: .circular(_radius),
      child: Column(
        mainAxisSize: .min,
        children: [
          SizedBox.square(
            dimension: _size,
            child: Stack(
              children: [
                // Painted directly behind the lens so it has something
                // colorful to refract/blur/tint — a flat single-color
                // backdrop would blur to the same flat color and the glass
                // would read as invisible.
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: .circular(_radius),
                    gradient: LinearGradient(
                      begin: .topLeft,
                      end: .bottomRight,
                      colors: [
                        accent.withValues(alpha: dark ? 0.55 : 0.4),
                        accent.withValues(alpha: dark ? 0.22 : 0.16),
                      ],
                    ),
                  ),
                ),
                LiquidGlassLens(
                  style: LiquidGlassStyle(
                    shape: const LiquidGlassShape.continuousRoundedRectangle(
                      cornerRadius: _radius,
                      clipQuality: .exact,
                      borderWidth: 1.1,
                      lightDirection: 125,
                      lightIntensity: 1.25,
                      borderType: OpticalBorder(
                        borderSaturation: 0.35,
                        ambientIntensity: 0.25,
                        lightSpread: 0.25,
                      ),
                    ),
                    appearance: LiquidGlassAppearance(
                      blur: const LiquidGlassBlur(sigmaX: 6, sigmaY: 6),
                      color: white.withValues(alpha: dark ? 0.16 : 0.12),
                      shadow: LiquidGlassShadow(
                        blur: 8,
                        opacity: dark ? 0.3 : 0.12,
                        cornerRadius: _radius,
                      ),
                    ),
                    refraction: const LiquidGlassRefraction(
                      refractionType: OpticalRefraction(
                        refraction: 1.46,
                        refractionWidth: 9,
                        depth: 0.16,
                      ),
                      chromaticAberration: 0.002,
                    ),
                  ),
                  // The icon is the lens's child, not part of the backdrop,
                  // so it's drawn crisp on top instead of being blurred.
                  child: Center(
                    child: Image.asset(iconAsset, width: 44, height: 44),
                  ),
                ),
              ],
            ),
          ),
          heightBox(6),
          Text(
            label,
            textAlign: .center,
            style: context.labelMedium.copyWith(
              color: context.textSecondary,
              fontWeight: .w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  final AttachmentItem attachment;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _AttachmentThumbnail({
    required this.attachment,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: .circular(12),
      child: Container(
        width: 90,
        height: 90,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: .circular(12),
          border: Border.all(color: context.border),
        ),
        child: Stack(
          fit: .expand,
          children: [
            attachment.type == AttachmentType.image
                ? Image.file(File(attachment.path), fit: .cover)
                : isPdfPath(attachment.path)
                ? PdfPageThumbnail(
                    path: attachment.path,
                    fallback: _UnsupportedAttachmentIcon(path: attachment.path),
                  )
                : _UnsupportedAttachmentIcon(path: attachment.path),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: onRemove,
                borderRadius: .circular(20),
                child: Container(
                  padding: const .all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: .circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnsupportedAttachmentIcon extends StatelessWidget {
  final String path;

  const _UnsupportedAttachmentIcon({required this.path});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .all(6),
    child: Column(
      mainAxisSize: .min,
      mainAxisAlignment: .center,
      children: [
        Icon(Iconsax.document_text, size: 26, color: context.primary),
        heightBox(4),
        Text(
          path.split(Platform.pathSeparator).last,
          maxLines: 1,
          overflow: .ellipsis,
          textAlign: .center,
          style: context.labelSmall.copyWith(fontSize: 9),
        ),
      ],
    ),
  );
}

/// Compact row shown on the form — tapping it opens [_CategoryPickerSheet].
class _CategoryPickerTrigger extends StatelessWidget {
  final AddDocumentViewModel vm;

  const _CategoryPickerTrigger({required this.vm});

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<CategoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CategoryPickerSheet(
        categories: vm.categories,
        selected: vm.selectedCategory,
      ),
    );
    if (picked != null) vm.selectCategory(picked);
  }

  @override
  Widget build(BuildContext context) {
    final category = vm.selectedCategory;
    final color = category == null
        ? context.textSecondary
        : ((category.colorValue == null ? null : Color(category.colorValue!)) ??
              categoryIconColor(context, category.name));

    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: .circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: _formControlHeight),
        padding: const .symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: .circular(12),
          boxShadow: [
            BoxShadow(
              color: context.shadow,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: .center,
              decoration: BoxDecoration(color: color, shape: .circle),
              child: category == null
                  ? Icon(Iconsax.category, size: 16, color: context.white)
                  : FaIcon(
                      iconForKey(category.iconKey),
                      size: 16,
                      color: context.white,
                    ),
            ),
            widthBox(12),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Text(
                    AppLocalizations.of(context).categoryLabel,
                    style: context.bodySmall.copyWith(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    category?.name ??
                        AppLocalizations.of(context).uncategorized,
                    style: context.bodyMedium.copyWith(
                      fontWeight: .w600,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 16, color: context.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Strips a trailing comma as it's typed and commits whatever came before
/// it as a tag — intercepting via [TextInputFormatter] (part of the actual
/// text-input pipeline) rather than reacting to it after the fact in
/// `onChanged`, which avoids mutating the same controller from inside its
/// own change notification (a known source of flaky behavior — the
/// framework can still be in the middle of applying the very update that
/// triggered it). [onCommit] is deferred to a microtask so it only runs
/// once the comma-stripped value has actually been applied to the
/// controller; reading it synchronously here would still see the old text.
class _CommaTagFormatter extends TextInputFormatter {
  final ValueChanged<String> onCommit;

  _CommaTagFormatter({required this.onCommit});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Android keyboards may keep an ordinary Latin word in a composing
    // region until the user edits it again. A comma is an explicit tag
    // delimiter, so it must take priority over that transient composing
    // state; otherwise the comma remains in the field until Backspace.
    if (!newValue.text.endsWith(',')) return newValue;
    final text = newValue.text.substring(0, newValue.text.length - 1);
    final strippedValue = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    scheduleMicrotask(() => onCommit(text));
    return strippedValue;
  }
}

/// Renders entered tags as pill chips *inside* the field's own bordered
/// box — chips and the still-typing [TextField] share one [Wrap] inside an
/// [InputDecorator], which draws the same label/border/fill every other
/// field on this screen gets from the theme without needing its own text
/// field. A [StatefulWidget] only so the inline field's [FocusNode] can
/// drive [InputDecorator.isFocused] (otherwise the box never shows the
/// focused-border highlight).
class _TagsField extends StatefulWidget {
  final AddDocumentViewModel vm;

  const _TagsField({required this.vm});

  @override
  State<_TagsField> createState() => _TagsFieldState();
}

class _TagsFieldState extends State<_TagsField> {
  // Android's software Backspace edits TextEditingValue but does not always
  // emit a KeyEvent. This invisible marker gives it one character to delete
  // when a chip is selected, so the formatter below can remove that chip.
  static const _selectedTagMarker = '\u200B';

  final FocusNode _focusNode = FocusNode();
  String? _selectedTag;
  String? _queuedCommaCommit;

  @override
  void initState() {
    super.initState();
    // The tag input owns this focus node, so handle Backspace here rather
    // than on an ancestor Focus widget. This receives the key before the
    // TextField's default editing action consumes it.
    _focusNode.onKeyEvent = _handleKeyEvent;
    _focusNode.addListener(_refreshField);
    widget.vm.tagController.addListener(_handleTagTextChanged);
  }

  @override
  void didUpdateWidget(covariant _TagsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vm.tagController != widget.vm.tagController) {
      oldWidget.vm.tagController.removeListener(_handleTagTextChanged);
      widget.vm.tagController.addListener(_handleTagTextChanged);
    }
  }

  void _refreshField() => setState(() {});

  void _handleTagTextChanged() {
    _refreshField();

    // The formatter is the normal path. A few Android IMEs apply their own
    // composing update after it, though, leaving `tag,` in the controller
    // without another formatter pass. Observe that final value and defer the
    // mutation until this controller notification has fully completed.
    final text = widget.vm.tagController.text;
    if (!text.endsWith(',') || text == _queuedCommaCommit) return;
    _queuedCommaCommit = text;
    scheduleMicrotask(() {
      if (!mounted || _queuedCommaCommit != text) return;
      _queuedCommaCommit = null;
      _commitFormattedTag(text.substring(0, text.length - 1));
    });
  }

  void _selectTag(String tag) {
    setState(() => _selectedTag = tag);
    widget.vm.tagController.value = const TextEditingValue(
      text: _selectedTagMarker,
      selection: TextSelection.collapsed(offset: _selectedTagMarker.length),
    );
    _focusNode.requestFocus();
  }

  void _clearSelectedTag() {
    if (_selectedTag == null) return;
    setState(() => _selectedTag = null);
    final controller = widget.vm.tagController;
    if (controller.text.contains(_selectedTagMarker)) controller.clear();
  }

  bool get _hasOnlySelectedTagMarker =>
      widget.vm.tagController.text == _selectedTagMarker;

  TextEditingValue _handleSelectedTagEdit(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!oldValue.text.contains(_selectedTagMarker)) return newValue;

    final newText = newValue.text.replaceAll(_selectedTagMarker, '');
    if (newText.isEmpty && _selectedTag != null) {
      scheduleMicrotask(_removeSelectedTag);
      // Keep the marker until the microtask removes the selected chip. This
      // prevents Android from restoring an empty composing value first.
      return oldValue;
    }

    // The user typed after selecting a chip. The marker must never become
    // part of a tag, and typing switches back to normal text entry.
    if (newText != newValue.text) scheduleMicrotask(_clearSelectedTag);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
      composing: TextRange.empty,
    );
  }

  void _removeSelectedTag() {
    if (!mounted) return;
    final tag = _selectedTag;
    if (tag == null || !widget.vm.tags.contains(tag)) return;
    widget.vm.removeTag(tag);
    _clearSelectedTag();
    _focusNode.requestFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace ||
        !_hasOnlySelectedTagMarker) {
      return .ignored;
    }
    if (_selectedTag == null) return .ignored;
    _removeSelectedTag();
    return .handled;
  }

  void _commitTag() {
    final vm = widget.vm;
    if (vm.tagController.text.contains(_selectedTagMarker)) {
      vm.tagController.text = vm.tagController.text.replaceAll(
        _selectedTagMarker,
        '',
      );
    }
    _clearSelectedTag();
    if (vm.tagController.text.trim().isEmpty) {
      vm.tagController.clear();
    } else {
      vm.addTag();
    }
    _focusNode.requestFocus();
  }

  void _commitFormattedTag(String text) {
    // A later edit or a removed field must not be consumed by a stale
    // microtask. Some Android IMEs restore the comma after the formatter has
    // returned its stripped value, so accept either representation and put
    // the stripped text back before committing. Comparing only the stripped
    // controller value made those valid Android commits disappear.
    if (!mounted) return;
    final controller = widget.vm.tagController;
    final currentText = controller.text;
    if (currentText != text && currentText != '$text,') return;
    if (currentText != text) {
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    _commitTag();
  }

  @override
  void dispose() {
    widget.vm.tagController.removeListener(_handleTagTextChanged);
    _focusNode.removeListener(_refreshField);
    _focusNode.onKeyEvent = null;
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      behavior: .translucent,
      onTap: () => _focusNode.requestFocus(),
      child: InputDecorator(
        isFocused: _focusNode.hasFocus,
        isEmpty:
            vm.tags.isEmpty &&
            vm.tagController.text.replaceAll(_selectedTagMarker, '').isEmpty,
        decoration: InputDecoration(
          constraints: const BoxConstraints(minHeight: _formControlHeight),
          filled: true,
          // InputDecorator inherits the global grey field fill unless
          // this inline tag field explicitly uses the elevated surface.
          fillColor: context.surfaceElevated,
          label: Text(
            l10n.tags,
            style: context.bodySmall.copyWith(
              color: context.textSecondary,
              fontSize: 16,
            ),
          ),
          floatingLabelBehavior: .auto,
          hintStyle: context.bodySmall.copyWith(color: context.textSecondary),
          errorText: switch (vm.tagError) {
            TagError.limitReached => l10n.tagErrorLimitReached(
              AddDocumentViewModel.maxTagCount,
            ),
            TagError.tooLong => l10n.tagErrorTooLong(
              AddDocumentViewModel.maxTagLength,
            ),
            TagError.duplicate => l10n.tagErrorDuplicate,
            null => null,
          },
          errorMaxLines: 2,
        ),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: .center,
          children: [
            for (final tag in vm.tags)
              GestureDetector(
                onTap: () => _selectTag(tag),
                child: Chip(
                  label: Text(tag, maxLines: 1, overflow: .ellipsis),
                  labelPadding: const .symmetric(horizontal: 4),
                  padding: .zero,
                  materialTapTargetSize: .shrinkWrap,
                  deleteIconBoxConstraints: const BoxConstraints.tightFor(
                    width: 18,
                    height: 18,
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    vm.removeTag(tag);
                    if (_selectedTag == tag) _clearSelectedTag();
                    _focusNode.requestFocus();
                  },
                  backgroundColor: context.surfaceElevated,
                  deleteIconColor: context.textSecondary,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _selectedTag == tag
                          ? context.primary
                          : context.border,
                      width: _selectedTag == tag ? 2 : 1,
                    ),
                  ),
                ),
              ),
            // A fixed width rather than IntrinsicWidth — EditableText
            // under IntrinsicWidth's two-pass layout is a known source
            // of flaky/incorrect rendering. A plain TextField already
            // scrolls its content horizontally past this width, same
            // as any other single-line field, so nothing is lost.
            SizedBox(
              width: 140,
              child: TextField(
                controller: vm.tagController,
                focusNode: _focusNode,
                onChanged: (_) {
                  _clearSelectedTag();
                  vm.clearTagError();
                },
                inputFormatters: [
                  TextInputFormatter.withFunction(_handleSelectedTagEdit),
                  _CommaTagFormatter(onCommit: _commitFormattedTag),
                ],
                // Tags are delimiter-based values. Android IMEs can keep
                // autocorrect/suggestion text in an active composing
                // range, and Flutter intentionally does not run input
                // formatters until that range commits. Turning these off
                // makes a typed comma reach the formatter immediately.
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: .done,
                // Keep the keyboard and caret active after Done/Enter.
                onEditingComplete: () {},
                onSubmitted: (_) => _commitTag(),
                style: context.bodySmall.copyWith(color: context.textPrimary),
                // Only the outer InputDecorator paints the field. Even
                // border: none would inherit themed focus borders/fill.
                decoration: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpirableToggle extends StatelessWidget {
  final AddDocumentViewModel vm;

  const _ExpirableToggle({required this.vm});

  Future<void> _pickExpiry(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: vm.expiryDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 20),
    );
    if (date == null) {
      if (vm.expiryDate == null) vm.setExpirable(false);
      return;
    }
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: vm.expiryDate != null
          ? TimeOfDay.fromDateTime(vm.expiryDate!)
          : TimeOfDay.now(),
    );
    final combined = time == null
        ? date
        : DateTime(date.year, date.month, date.day, time.hour, time.minute);
    vm.setExpirable(true);
    vm.setExpiryDate(combined);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: _formControlHeight),
      padding: const .symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: .circular(12),
        boxShadow: [
          BoxShadow(
            color: context.shadow,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Scoped to just the icon/label so it doesn't share a tap
          // target with the Switch to its right.
          Expanded(
            child: InkWell(
              onTap: () => _pickExpiry(context),
              borderRadius: .circular(12),
              child: Row(
                children: [
                  Icon(
                    Iconsax.calendar_2,
                    color: vm.isExpirable
                        ? context.primary
                        : context.textSecondary,
                    size: 22,
                  ),
                  widthBox(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      mainAxisSize: .min,
                      children: [
                        Text(
                          AppLocalizations.of(context).documentExpirable,
                          style: context.bodyMedium.copyWith(fontWeight: .w600),
                        ),
                        if (vm.isExpirable) ...[
                          heightBox(2),
                          Text(
                            vm.expiryDate == null
                                ? AppLocalizations.of(
                                    context,
                                  ).tapToSetExpiryDate
                                : AppLocalizations.of(
                                    context,
                                  ).expiresOn(vm.expiryDate!.fullFormat),
                            style: context.labelSmall.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Switch(
            value: vm.isExpirable,
            onChanged: (value) {
              if (value) {
                _pickExpiry(context);
              } else {
                vm.setExpirable(false);
              }
            },
            activeThumbColor: context.primary,
          ),
        ],
      ),
    );
  }
}
