import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../../core/di/di_exports.dart';
import '../../../../../../../core/localization/localization_exports.dart';
import '../../../../../../../core/theme/theme_exports.dart';
import '../../../../../../../core/utils/utils_exports.dart';
import '../../../../../../../core/widgets/widgets_exports.dart';
import '../../../../../../../routes/routes_exports.dart';
import '../../../../../../home/home_exports.dart';
import '../viewmodels/add_document_viewmodel.dart';

class AddDocumentView extends StatelessWidget {
  const AddDocumentView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<AddDocumentViewModel>(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: AppLocalizations.of(context).addDocumentTitle,
        ),
        body: SafeArea(
          child: Consumer<AddDocumentViewModel>(
            builder: (context, vm, _) {
              return Form(
                key: vm.formKey,
                child: ListView(
                  padding: const .symmetric(horizontal: 14, vertical: 20),
                  children: [
                    _AttachmentSection(vm: vm),
                    heightBox(24),
                    CustomTextFormField(
                      label: AppLocalizations.of(context).documentTitleLabel,
                      hintText: AppLocalizations.of(context).documentTitleHint,
                      isRequired: true,
                      controller: vm.titleController,
                      textCapitalization: .sentences,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? AppLocalizations.of(context).documentTitleRequired
                          : null,
                    ),
                    heightBox(20),
                    _CategoryPickerTrigger(vm: vm),
                    heightBox(20),
                    _TagsField(vm: vm),
                    heightBox(20),
                    _ExpirableToggle(vm: vm),
                    heightBox(32),
                    CustomButton(
                      text: AppLocalizations.of(context).save,
                      // Writes into the shared DocumentLocalStore (see
                      // AddDocumentViewModel) — no real document data layer
                      // exists yet (CLAUDE.md's "Known mismatches"), so this
                      // is local-only, but it does persist for the session
                      // and shows up in Home's Recent Files strip.
                      onPressed: () {
                        if (!vm.formKey.currentState!.validate()) return;
                        vm.submit();
                        // Compute the message and pop *before* showing the
                        // toast — another_flushbar pushes its toast as its
                        // own Navigator route, so popping this screen right
                        // on top of that in-flight push corrupts the
                        // navigator's route lifecycle.
                        final message = AppLocalizations.of(
                          context,
                        ).documentCreatedToast(vm.titleController.text.trim());
                        AppNavigator.pop();
                        AppToastsUtils.success(message);
                      },
                    ),
                    heightBox(20),
                  ],
                ),
              );
            },
          ),
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
        Text(
          AppLocalizations.of(context).attachments,
          style: context.titleMedium.copyWith(fontWeight: .w700),
        ),
        heightBox(10),
        Row(
          children: [
            Expanded(
              child: _SourceButton(
                icon: Iconsax.camera,
                label: AppLocalizations.of(context).camera,
                onTap: vm.pickFromCamera,
              ),
            ),
            widthBox(10),
            Expanded(
              child: _SourceButton(
                icon: Iconsax.gallery,
                label: AppLocalizations.of(context).gallery,
                onTap: vm.pickFromGallery,
              ),
            ),
            widthBox(10),
            Expanded(
              child: _SourceButton(
                icon: Iconsax.document,
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
              for (final attachment in vm.attachments)
                _AttachmentThumbnail(
                  attachment: attachment,
                  onRemove: () => vm.removeAttachment(attachment),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: .circular(12),
      child: Container(
        padding: const .symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: context.surfaceElevated,
          borderRadius: .circular(12),
          border: Border.all(color: context.border),
        ),
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(icon, color: context.primary, size: 22),
            heightBox(6),
            Text(
              label,
              style: context.labelSmall.copyWith(
                color: context.primary,
                fontWeight: .w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  final AttachmentItem attachment;
  final VoidCallback onRemove;

  const _AttachmentThumbnail({
    required this.attachment,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              : Padding(
                  padding: const .all(6),
                  child: Column(
                    mainAxisSize: .min,
                    mainAxisAlignment: .center,
                    children: [
                      Icon(
                        Iconsax.document_text,
                        size: 26,
                        color: context.primary,
                      ),
                      heightBox(4),
                      Text(
                        attachment.path.split(Platform.pathSeparator).last,
                        maxLines: 1,
                        overflow: .ellipsis,
                        textAlign: .center,
                        style: context.labelSmall.copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ),
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
    );
  }
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
      builder: (_) => _CategoryPickerSheet(
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
        : (category.color ?? categoryIconColor(context, category.name));

    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: .circular(12),
      child: Container(
        padding: const .symmetric(horizontal: 16, vertical: 14),
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
                  : FaIcon(category.icon, size: 16, color: context.white),
            ),
            widthBox(12),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    AppLocalizations.of(context).categoryLabel,
                    style: context.labelSmall.copyWith(
                      color: context.textSecondary,
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

class _CategoryPickerSheet extends StatelessWidget {
  final List<CategoryItem> categories;
  final CategoryItem? selected;

  const _CategoryPickerSheet({
    required this.categories,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const .fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: .circular(2),
                ),
              ),
              heightBox(16),
              Text(
                AppLocalizations.of(context).selectCategory,
                style: context.titleMedium.copyWith(fontWeight: .bold),
              ),
              heightBox(12),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => heightBox(8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category.name == selected?.name;
                    final color =
                        category.color ??
                        categoryIconColor(context, category.name);
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(category),
                      borderRadius: .circular(12),
                      child: Container(
                        padding: const .symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.primary.withValues(alpha: 0.1)
                              : context.surface,
                          borderRadius: .circular(12),
                          border: isSelected
                              ? Border.all(color: context.primary, width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: .center,
                              decoration: BoxDecoration(
                                color: color,
                                shape: .circle,
                              ),
                              child: FaIcon(
                                category.icon,
                                size: 14,
                                color: context.white,
                              ),
                            ),
                            widthBox(12),
                            Expanded(
                              child: Text(
                                category.name,
                                style: context.bodyMedium.copyWith(
                                  fontWeight: .w600,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: context.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TagsField extends StatelessWidget {
  final AddDocumentViewModel vm;

  const _TagsField({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        CustomTextFormField(
          label: AppLocalizations.of(context).tags,
          hintText: AppLocalizations.of(context).tagsHint,
          controller: vm.tagController,
          onChanged: (_) => vm.clearTagError(),
          textInputAction: .done,
          onFieldSubmitted: (_) => vm.addTag(),
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
        ),
        heightBox(4),
        Text(
          switch (vm.tagError) {
            TagError.limitReached => AppLocalizations.of(
              context,
            ).tagErrorLimitReached(AddDocumentViewModel.maxTagCount),
            TagError.tooLong => AppLocalizations.of(
              context,
            ).tagErrorTooLong(AddDocumentViewModel.maxTagLength),
            TagError.invalidCharacters => AppLocalizations.of(
              context,
            ).tagErrorInvalidCharacters,
            TagError.duplicate => AppLocalizations.of(
              context,
            ).tagErrorDuplicate,
            null => AppLocalizations.of(
              context,
            ).tagsHelper(AddDocumentViewModel.maxTagLength),
          },
          style: context.labelSmall.copyWith(
            color: vm.tagError != null ? context.error : context.textSecondary,
          ),
        ),
        if (vm.tags.isNotEmpty) ...[
          heightBox(10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in vm.tags)
                Chip(
                  label: Text(tag),
                  onDeleted: () => vm.removeTag(tag),
                  backgroundColor: context.surface,
                  deleteIconColor: context.textSecondary,
                  side: BorderSide(color: context.border),
                ),
            ],
          ),
        ],
      ],
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
