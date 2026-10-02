# Bulk Import — Implementation Specification

**Status:** proposed for Phase 2
**Working name:** Bulk Import
**Last reviewed:** 2026-10-02

## Purpose

Bulk Import lets users turn selected images and files already on their device
into separate Docketly documents in one review-first flow. It removes the
first-use friction of adding many existing documents one at a time.

This is not a device scan. Docketly must never request broad storage access,
crawl user files, import in the background, or create a document without an
explicit confirmation.

| Included | Excluded |
| --- | --- |
| User-selected images and supported files | Gallery/filesystem scanning |
| One candidate per selected file | Silent automatic import |
| Review, editing, deselection, and confirmation | Automatic grouping or deduplication |
| Optional OCR suggestions | Account or network requirement |

## Release plan

### Version 1 — manual-first bulk import

- Sources: **Gallery** and **Files**.
- Each independently selected file becomes one candidate document.
- Each candidate starts with filename-derived title and **Uncategorized**.
- Users can edit title/category, remove or deselect candidates, then confirm.
- The flow appears once after onboarding and has a persistent entry point in
  Home or Profile. A one-time prompt must never be the only entry point.

### Version 1.1 — suggestions

- Run existing OCR and document-analysis services per candidate.
- Suggest title, category, description, expiry, and at most **three** tags.
- Never overwrite a field the user edited.
- Leave low-confidence/unreadable files in **Uncategorized**.
- Import remains fully usable offline; network-backed analysis is optional.

### Deferred

- Scanner/camera as a bulk source; a scanner session naturally produces pages
  of one document and remains in Add Document.
- Candidate combine/grouping, duplicate detection, and background import.

## User flow

```text
Post-onboarding prompt or persistent entry
        ↓
Choose Gallery or Files
        ↓
System multi-select picker
        ↓
Create staged candidates
        ↓
Optional OCR/suggestions
        ↓
Review, edit, select, and confirm
        ↓
Persist accepted documents and show result
```

The post-onboarding screen says:

> **Bring your documents together**
> Select existing files and review them before they are added to Docketly.

Actions are **Import documents** and **Not now**. Dismissing it opens Home and
records the prompt as seen.

### Review screen

Nothing is written to the document database before confirmation. Each
candidate shows thumbnail/file fallback, editable title, category, optional
tags, selection control, and state: `Queued`, `Processing`, `Ready`, or
`Failed`.

Required actions:

- Select all / deselect all.
- Edit title or category for one candidate.
- Apply a category to all selected candidates.
- Remove a candidate.
- Retry failed suggestions when enabled.
- Confirm with a count, for example **Import 12 documents**.

Disable Confirm when no item is selected. Cancelling the picker or review
creates no documents.

## Current codebase and reuse

| Component | Current behavior | Bulk Import role |
| --- | --- | --- |
| `DeviceAttachmentDataSource.pickFromGallery()` | Multi-select via `ImagePicker.pickMultiImage()` | Reuse picker mechanics with bulk staging |
| `DeviceAttachmentDataSource.pickFile()` | One non-image file | Add bulk method using `allowMultiple: true` |
| `AttachmentSelection` / `AttachmentItem` | Picker attachment types | Candidate attachment input |
| `DocumentProcessingUseCases.extractText()` | OCR extraction for a path | Per-candidate OCR |
| `DocumentProcessingUseCases.analyze()` | OCR-based metadata suggestions | Suggestion source only |
| `DocumentUseCases.addDocument()` | Persists and updates local state | Final commit path |
| `AddDocumentViewModel` | One-document form state | Must not own a batch |

OCR and suggestion hooks already exist. They currently process attachments
asynchronously and sequentially for one document. Bulk Import needs a batch
orchestrator, not a new OCR foundation.

## Architecture

Create a dedicated feature; do not extend `AddDocumentViewModel`.

```text
features/bulk_import/
  domain/entities/bulk_import_candidate.dart
  domain/repositories/bulk_import_repository.dart
  domain/usecases/bulk_import_usecases.dart
  data/datasources/bulk_import_local_datasource.dart
  data/repository_impl/bulk_import_repository_impl.dart
  presentation/intro/bulk_import_intro_view.dart
  presentation/review/bulk_import_review_view.dart
  presentation/viewmodel/bulk_import_viewmodel.dart
```

`BulkImportViewModel` owns the temporary batch and exposes immutable
candidates, selected count, progress, edit actions, and commit state.

```dart
class BulkImportCandidate {
  final String id;
  final List<AttachmentItem> attachments;
  final String title;
  final String categoryId;
  final List<String> tags;
  final String ocrText;
  final CandidateProcessingState processingState;
  final bool isSelected;
  final bool hasUserEditedTitle;
  final bool hasUserEditedCategory;
  final bool hasUserEditedTags;
  final String? processingError;
}
```

Suggestion results must merge only into fields the user has not edited.

## File lifecycle: staging is required

Normal attachment picking copies immediately into permanent
`<app documents>/documents/`. That is correct for Add Document, but Bulk
Import needs a temporary area so cancellation does not leave orphaned files.

```text
<app documents>/import_staging/<session-id>/
```

1. Copy chosen files into the active session directory.
2. Generate previews and OCR only from staged copies.
3. On confirmation, move/copy accepted files into `documents/`, then create
   their `DocumentItem` rows.
4. On Cancel, remove the entire staging directory.
5. On app launch, best-effort cleanup removes stale sessions.
6. A failed move/copy must not create a database row pointing to a missing
   file; retain that candidate for retry or discard.

Commit candidates one at a time. Successful imports remain successful when a
later candidate fails; show an import summary identifying the failed items.

## Processing and performance

Do not assume native OCR is isolate-safe. Plugin calls may require Flutter's
main isolate. Preserve the current asynchronous approach and process
OCR/analysis with queue concurrency **1**.

- Show progress, for example `Processing 7 of 24`.
- Keep review editing responsive while work continues.
- Cancel queued processing for removed/deselected candidates.
- Cap Version 1.1 at **25 candidates per batch**.
- OCR/analysis failure is non-fatal; manual import remains available.

## Mapping to documents

On confirmation, each selected candidate creates one `DocumentItem` via
`DocumentUseCases.addDocument()`.

| Field | Source |
| --- | --- |
| `id` | `generateLocalId()` |
| `title` | Trimmed candidate title, required |
| category fields | Selected category, Uncategorized fallback |
| `tags` | Candidate tags; cap suggested tags at three |
| `filePaths` | Accepted files moved from staging |
| `createdAt` | Confirmation time |
| `ocrText` | Extracted text or empty string |
| description/expiry | Empty in Version 1; optional suggestions in 1.1 |

Using the normal document use case preserves category counts, recents, search,
backups, and notification behavior.

## Platform rules

- Gallery supports multi-select images through `pickMultiImage()`.
- Files uses `FilePicker.pickFiles(allowMultiple: true, ...)`.
- Rely only on OS picker access; request no broad media/storage permission.
- Keep **Share into Docketly** routed to Add Document in Version 1.
- Report unsupported/unreadable files as skipped; never fail a whole batch for
  one file.

## Acceptance criteria

### Version 1

- Bulk Import is reachable after onboarding and later from the app.
- Gallery and Files support multi-select.
- Each selected item becomes an editable review candidate.
- Users can edit, select/deselect, remove, and bulk-categorize candidates.
- Cancel creates no documents and leaves no staged files.
- Confirm creates one document per selected candidate.
- Partial failures report failed items without losing successful imports.
- The manual flow works offline.

### Version 1.1

- Processing progress is visible and does not block editing.
- Suggestions never overwrite user edits.
- Failed processing leaves a candidate manually importable.
- Suggested tags are capped at three.

## Implementation order

1. Add route, post-onboarding prompt, and persistent entry point.
2. Build staging datasource and stale-session cleanup; test cancellation and
   partial failures.
3. Add Gallery/Files multi-select and candidate creation.
4. Build review, editing, selection, and bulk-category actions.
5. Implement per-candidate commit and import summary.
6. Add queued OCR/analysis suggestions and safe merge rules.
7. Instrument completion, cancellation, item count, and failures without
   collecting document content or filenames.

## Recorded decisions

| Decision | Rationale |
| --- | --- |
| Dedicated `bulk_import` feature/ViewModel | Keeps batch state out of Add Document |
| Gallery and Files only in V1 | Fits existing documents and avoids scanner grouping ambiguity |
| Manual-first release | Delivers value without OCR/AI as a launch dependency |
| 25-item suggestion cap | Keeps sequential native OCR predictable |
| Three suggested-tag limit | Useful metadata without noisy tag dumps |
| No automatic grouping | Incorrect merges are costly; manual combine can come later |
| Staging directory before confirmation | Prevents cancelled batches leaving permanent files |
