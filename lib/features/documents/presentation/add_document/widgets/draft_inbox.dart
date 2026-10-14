import 'package:flutter/material.dart';
import '../../../../../core/di/di_exports.dart';
import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/persist_action.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../../../routes/routes_exports.dart';
import '../../../../home/home_exports.dart' show DocumentCoverThumbnail;
import '../../../domain/entities/document_draft.dart';
import '../../../domain/usecases/draft_usecases.dart';

/// A compact Home entry, hidden when there is no unfinished work.
class DraftInbox extends StatefulWidget {
  const DraftInbox({super.key});
  @override
  State<DraftInbox> createState() => _DraftInboxState();
}

class _DraftInboxState extends State<DraftInbox> {
  late final DraftUseCases _drafts = sl<DraftUseCases>();
  @override
  void initState() {
    super.initState();
    _drafts.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _drafts.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_drafts.drafts.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const .only(bottom: 14),
      child: Material(
        color: context.primary.withValues(alpha: 0.08),
        borderRadius: .circular(10),
        clipBehavior: .antiAlias,
        child: InkWell(
          onTap: () async {
            final selected = await showModalBottomSheet<DocumentDraft>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              backgroundColor: context.background,
              builder: (_) => _DraftSheet(drafts: _drafts),
            );
            if (selected != null && context.mounted) {
              AppNavigator.pushNamed(RouteNames.addDocument, extra: selected);
            }
          },
          child: Padding(
            padding: const .symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: .center,
                  decoration: BoxDecoration(
                    color: context.primary.withValues(alpha: 0.15),
                    shape: .circle,
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    size: 17,
                    color: context.primaryAccent,
                  ),
                ),
                widthBox(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    mainAxisSize: .min,
                    children: [
                      Text(
                        l10n.draftsTitle,
                        style: context.labelLarge.copyWith(fontWeight: .w700),
                      ),
                      Text(
                        l10n.draftsCount(_drafts.drafts.length),
                        style: context.labelSmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: context.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DraftSheet extends StatefulWidget {
  final DraftUseCases drafts;
  const _DraftSheet({required this.drafts});
  @override
  State<_DraftSheet> createState() => _DraftSheetState();
}

class _DraftSheetState extends State<_DraftSheet> {
  String? _busyId;
  @override
  void initState() {
    super.initState();
    widget.drafts.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.drafts.removeListener(_changed);
    super.dispose();
  }

  Future<void> _discard(DocumentDraft draft) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAnimatedConfirmDialog(
      context,
      icon: Icons.delete_outline,
      title: l10n.discardDraft,
      message: l10n.discardDraftMessage,
      confirmLabel: l10n.discardDraft,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busyId = draft.id);
    await persistAction(context, () => widget.drafts.discard(draft.id));
    if (mounted) setState(() => _busyId = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final drafts = widget.drafts.drafts;
    return SafeArea(
      child: ConstrainedBox(
        // Caps how tall the sheet can grow for many drafts, but otherwise
        // hugs its actual content (mainAxisSize.min + shrinkWrap below) --
        // a single draft no longer leaves most of the sheet empty.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Padding(
              padding: const .fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    l10n.draftsTitle,
                    style: context.titleLarge.copyWith(fontWeight: .w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.draftsHelp,
                    style: context.bodySmall.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: drafts.isEmpty
                  ? Padding(
                      padding: const .symmetric(vertical: 32),
                      child: Center(child: Text(l10n.noDrafts)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const .fromLTRB(16, 0, 16, 20),
                      itemCount: drafts.length,
                      separatorBuilder: (_, index) => heightBox(12),
                      itemBuilder: (context, index) {
                        final draft = drafts[index];
                        final document = draft.document;
                        final busy = _busyId == draft.id;
                        return Container(
                          decoration: BoxDecoration(
                            color: context.surface,
                            border: Border.all(color: context.border),
                            borderRadius: .circular(16),
                          ),
                          padding: const .all(14),
                          child: Column(
                            crossAxisAlignment: .stretch,
                            children: [
                              Row(
                                crossAxisAlignment: .start,
                                children: [
                                  ClipRRect(
                                    borderRadius: .circular(10),
                                    child: DocumentCoverThumbnail(
                                      document: document,
                                      color: context.primaryAccent,
                                      width: 56,
                                      height: 70,
                                      borderRadius: 10,
                                      iconSize: 24,
                                    ),
                                  ),
                                  widthBox(12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: .start,
                                      children: [
                                        Text(
                                          document.title.trim().isEmpty
                                              ? l10n.untitledDraft
                                              : document.title,
                                          maxLines: 2,
                                          overflow: .ellipsis,
                                          style: context.titleSmall.copyWith(
                                            fontWeight: .w700,
                                          ),
                                        ),
                                        heightBox(6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.description_outlined,
                                              size: 13,
                                              color: context.textSecondary,
                                            ),
                                            widthBox(4),
                                            Text(
                                              l10n.pageCount(
                                                document.filePaths.length,
                                              ),
                                              style: context.labelSmall
                                                  .copyWith(
                                                    color:
                                                        context.textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        heightBox(3),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.schedule_rounded,
                                              size: 13,
                                              color: context.textSecondary,
                                            ),
                                            widthBox(4),
                                            Text(
                                              MaterialLocalizations.of(
                                                context,
                                              ).formatShortDate(
                                                draft.updatedAt,
                                              ),
                                              style: context.labelSmall
                                                  .copyWith(
                                                    color:
                                                        context.textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              heightBox(14),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      text: l10n.discardDraft,
                                      onPressed: busy
                                          ? null
                                          : () => _discard(draft),
                                      isLoading: busy,
                                      backgroundColor: context.transparent,
                                      textColor: context.errorAccent,
                                      borderColor: context.errorAccent
                                          .withValues(alpha: 0.4),
                                      radius: 12,
                                      fontSize: 14,
                                      size: const Size(0, 42),
                                    ),
                                  ),
                                  widthBox(10),
                                  Expanded(
                                    child: CustomButton(
                                      text: l10n.resumeDraft,
                                      onPressed: _busyId == null
                                          ? () =>
                                                Navigator.of(context).pop(draft)
                                          : null,
                                      backgroundColor: context.primary,
                                      radius: 12,
                                      fontSize: 14,
                                      size: const Size(0, 42),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
