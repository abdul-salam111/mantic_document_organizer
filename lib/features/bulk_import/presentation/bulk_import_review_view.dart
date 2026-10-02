import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../routes/routes_exports.dart';
import '../../documents/domain/entities/document_item.dart';
import '../domain/entities/bulk_import_candidate.dart';
import 'viewmodel/bulk_import_viewmodel.dart';

class BulkImportReviewView extends StatelessWidget {
  final BulkImportViewModel viewModel;
  const BulkImportReviewView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => viewModel,
    child: const _ReviewBody(),
  );
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody();

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.home);
    }
  }

  Future<void> _import(BuildContext context, BulkImportViewModel vm) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (vm.isProcessing) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import with current details?'),
          content: const Text(
            'Suggestions are still running. Importing now keeps the details currently shown and stops remaining suggestions.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep reviewing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import now'),
            ),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    }
    final result = await vm.commit();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          result.failures.isEmpty
              ? 'Import complete'
              : 'Some documents need retrying',
        ),
        content: Text(
          '${result.imported} documents imported.'
          '${result.failures.isEmpty ? '' : '\n${result.failures.length} could not be saved. They remain in review with an error so you can retry. Saved documents will not be imported again.'}',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              result.failures.isEmpty && vm.candidates.isEmpty
                  ? 'Done'
                  : 'Back to review',
            ),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (result.failures.isEmpty && vm.candidates.isEmpty) {
      context.goNamed(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BulkImportViewModel>();
    return PopScope(
      canPop: !vm.isImporting,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Review ${vm.candidates.length} documents'),
          leading: IconButton(
            tooltip: 'Cancel import',
            onPressed: vm.isImporting ? null : () => _leave(context),
            icon: const Icon(Icons.close),
          ),
        ),
        body: AbsorbPointer(
          absorbing: vm.isImporting,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (vm.notice != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(vm.notice!),
                  ),
                ),
              if (vm.isProcessing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Finding suggestions: ${vm.processedCount} of ${vm.processingTotal} complete',
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: vm.processingTotal == 0
                            ? 0
                            : vm.processedCount / vm.processingTotal,
                      ),
                    ],
                  ),
                ),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed: vm.candidates.isEmpty
                        ? null
                        : () => vm.selectAll(
                            vm.selectedCount != vm.candidates.length,
                          ),
                    child: Text(
                      vm.selectedCount == vm.candidates.length
                          ? 'Deselect all'
                          : 'Select all',
                    ),
                  ),
                  PopupMenuButton<String>(
                    enabled: vm.selectedCount > 0,
                    tooltip: 'Apply category to selected documents',
                    onSelected: vm.applyCategoryToSelected,
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: uncategorizedCategoryId,
                        child: Text('Uncategorized'),
                      ),
                      for (final c in vm.categories.where(
                        (c) => c.id != uncategorizedCategoryId,
                      ))
                        PopupMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Set category (${vm.selectedCount})'),
                    ),
                  ),
                ],
              ),
              if (vm.candidates.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No documents left to review. Close this screen to choose more files.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final c in vm.candidates)
                _CandidateCard(key: ValueKey(c.id), candidate: c),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: vm.canImport ? () => _import(context, vm) : null,
              child: Text(
                vm.isImporting
                    ? 'Importing ${vm.importCompleted} of ${vm.importTotal}…'
                    : 'Import ${vm.selectedCount} documents',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CandidateCard extends StatefulWidget {
  final BulkImportCandidate candidate;
  const _CandidateCard({super.key, required this.candidate});
  @override
  State<_CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<_CandidateCard> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _tags;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.candidate.title);
    _description = TextEditingController(text: widget.candidate.description);
    _tags = TextEditingController(text: widget.candidate.tags.join(', '));
  }

  @override
  void didUpdateWidget(covariant _CandidateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = widget.candidate;
    if (oldWidget.candidate.title != c.title && _title.text != c.title) {
      _title.text = c.title;
    }
    if (oldWidget.candidate.description != c.description &&
        _description.text != c.description) {
      _description.text = c.description;
    }
    // Do not normalize the user's comma-separated input while they type.
    if (!c.hasUserEditedTags && _tags.text != c.tags.join(', ')) {
      _tags.text = c.tags.join(', ');
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<BulkImportViewModel>();
    final c = widget.candidate;
    final theme = Theme.of(context);
    final categoryIds = {
      uncategorizedCategoryId,
      ...vm.categories.map((c) => c.id),
    };
    final status = switch (c.state) {
      CandidateProcessingState.queued =>
        c.isSelected ? 'Queued' : 'Suggestions paused',
      CandidateProcessingState.processing => 'Finding suggestions…',
      CandidateProcessingState.ready => 'Ready to import',
      CandidateProcessingState.failed => c.error ?? 'Suggestions unavailable',
    };
    final fallback = Icon(
      Icons.description_outlined,
      size: 30,
      color: theme.colorScheme.primary,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 52,
                    height: 60,
                    child: isImagePath(c.attachment.path)
                        ? Image.file(
                            File(c.attachment.path),
                            fit: BoxFit.cover,
                            cacheWidth: 156,
                            errorBuilder: (_, _, _) => fallback,
                          )
                        : fallback,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(status, style: theme.textTheme.bodySmall)),
                Checkbox(
                  value: c.isSelected,
                  onChanged: (_) => vm.toggle(c.id),
                  semanticLabel: 'Select ${c.title}',
                ),
                IconButton(
                  onPressed: () => vm.remove(c.id),
                  tooltip: 'Remove document',
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: 'Title',
                errorText: c.title.trim().isEmpty ? 'Enter a title' : null,
              ),
              onChanged: (value) => vm.updateTitle(c.id, value),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Category'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: categoryIds.contains(c.categoryId)
                      ? c.categoryId
                      : uncategorizedCategoryId,
                  isExpanded: true,
                  isDense: true,
                  items: [
                    const DropdownMenuItem(
                      value: uncategorizedCategoryId,
                      child: Text('Uncategorized'),
                    ),
                    for (final category in vm.categories.where(
                      (c) => c.id != uncategorizedCategoryId,
                    ))
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(
                          category.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) vm.updateCategory(c.id, value);
                  },
                ),
              ),
            ),
            if (c.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  children: [for (final tag in c.tags) Chip(label: Text(tag))],
                ),
              ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('More details'),
              subtitle: c.expiryDate == null
                  ? null
                  : Text(
                      'Expires ${MaterialLocalizations.of(context).formatMediumDate(c.expiryDate!)}',
                    ),
              children: [
                TextField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (value) => vm.updateDescription(c.id, value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tags,
                  decoration: const InputDecoration(
                    labelText: 'Tags, separated by commas',
                    helperText:
                        'Up to 10 tags; 20 letters, numbers, - or _ each.',
                    helperMaxLines: 2,
                  ),
                  onChanged: (value) => vm.updateTags(c.id, value),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          c.expiryDate == null
                              ? 'Set expiry date'
                              : MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(c.expiryDate!),
                        ),
                        onPressed: () async {
                          final initialDate = c.expiryDate ?? DateTime.now();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(initialDate.year < 1900 ? initialDate.year : 1900),
                            lastDate: DateTime(initialDate.year > 2200 ? initialDate.year + 1 : 2201),
                          );
                          if (date != null && context.mounted) {
                            vm.updateExpiry(c.id, date);
                          }
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: () => vm.updateExpiry(c.id, null),
                      child: const Text('No expiry'),
                    ),
                  ],
                ),
              ],
            ),
            if (c.state == CandidateProcessingState.failed)
              TextButton.icon(
                onPressed: c.isSelected ? () => vm.retry(c.id) : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry analysis'),
              ),
            if (c.importError != null)
              Text(
                c.importError!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
