import 'package:flutter/material.dart';
import '../../../../../core/di/di_exports.dart';
import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/persist_action.dart';
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
      padding: const .only(bottom: 16),
      child: Material(
        color: context.primary.withValues(alpha: 0.08),
        borderRadius: .circular(16),
        clipBehavior: .antiAlias,
        child: ListTile(
          leading: Icon(Icons.edit_note_rounded, color: context.primaryAccent),
          title: Text(l10n.draftsTitle, style: context.titleSmall),
          subtitle: Text(l10n.draftsCount(_drafts.drafts.length)),
          trailing: const Icon(Icons.chevron_right),
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
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Padding(
              padding: const .fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(l10n.draftsTitle, style: context.titleLarge),
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
            Expanded(
              child: drafts.isEmpty
                  ? Center(child: Text(l10n.noDrafts))
                  : ListView.separated(
                      padding: const .fromLTRB(16, 0, 16, 20),
                      itemCount: drafts.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final draft = drafts[index];
                        final document = draft.document;
                        return Material(
                          color: context.surface,
                          borderRadius: .circular(16),
                          clipBehavior: .antiAlias,
                          child: Padding(
                            padding: const .all(12),
                            child: Column(
                              crossAxisAlignment: .stretch,
                              children: [
                                Row(
                                  children: [
                                    DocumentCoverThumbnail(
                                      document: document,
                                      color: context.primaryAccent,
                                      width: 52,
                                      height: 64,
                                      borderRadius: 8,
                                      iconSize: 22,
                                    ),
                                    const SizedBox(width: 12),
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
                                            style: context.titleSmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l10n.pageCount(
                                              document.filePaths.length,
                                            ),
                                            style: context.bodySmall,
                                          ),
                                          Text(
                                            MaterialLocalizations.of(
                                              context,
                                            ).formatShortDate(draft.updatedAt),
                                            style: context.labelSmall.copyWith(
                                              color: context.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  alignment: .spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: _busyId == null
                                          ? () =>
                                                Navigator.of(context).pop(draft)
                                          : null,
                                      child: Text(l10n.resumeDraft),
                                    ),
                                    TextButton(
                                      onPressed: _busyId == null
                                          ? () => _discard(draft)
                                          : null,
                                      child: Text(
                                        l10n.discardDraft,
                                        style: TextStyle(
                                          color: context.errorAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_busyId == draft.id)
                                  const LinearProgressIndicator(),
                              ],
                            ),
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
