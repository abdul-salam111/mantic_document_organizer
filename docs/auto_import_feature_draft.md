# Bulk Import — Implementation Specification

**Status:** Implemented in code (production + tests passing; `flutter
analyze --fatal-infos` clean). Discovery covers the photo library only —
Android Downloads/Documents discovery was built, then removed; see
"Android Downloads/Documents (removed)" below for why. Physical-device
verification remains for everything in this feature — permission
dialogs, the real photo library, and actual OCR/AI behavior can't be
exercised without a device/simulator.
**Working name:** Bulk Import
**Last reviewed:** 2026-10-02

## Purpose

Bulk Import finds documents the user already has on their device and gets
them into Docketly with minimal manual effort. The user does **not** browse
a file picker and multi-select files one by one for bulk import — they grant
permission, Docketly finds the candidates automatically, and the user
reviews/edits/confirms before anything is created.

This is unrelated to the separate single-document **"+ Add Document"**
feature, which keeps its own Gallery/Files/Camera pickers for adding one
document at a time (scanning a single new receipt, etc.) — that flow is not
changed by this spec.

Docketly must never crawl the broader device filesystem in the background,
import on a timer, or create a document without explicit confirmation on
the review screen — that still holds. **Android's all-files permission
(`MANAGE_EXTERNAL_STORAGE`) was tried and then deliberately removed**:
scoped storage doesn't let an app read another app's non-media files (like
a downloaded PDF) any other way, and real-device testing confirmed that
gap — PDFs in Downloads genuinely weren't being found without it. The
permission was requested briefly, but Google Play restricts
`MANAGE_EXTERNAL_STORAGE` to apps whose *core purpose* is broad file
management, which Docketly's isn't — it would very likely fail Play's
manual review, and even if approved once, Play periodically re-audits
apps holding it and can pull the whole app, not just this feature, on a
failed re-audit. That risk was judged not worth one onboarding
convenience feature, so it was reverted. See "Android Downloads/Documents
(removed)" below for the full history.

**Two further deliberate reversals, by explicit product decision:**

- **Discovery is now AI-driven and online-only**, not a free local
  heuristic. The inclusion decision (is this photo actually a document?),
  categorization, and tagging all happen in one AI call per candidate —
  see "Why AI replaced a local classifier" below. This replaces the
  earlier opt-in/offline-capable design entirely; Bulk Import cannot run
  without a network connection anymore.
- **Signup/login is now mandatory, app-wide**, reached before Home and
  with no skip. This directly reverses this repo's own documented
  architecture rule ("no part of the core app should ever gate on a
  signed-in user") — a deliberate, explicit product decision, not an
  oversight. Bulk Import's trigger moved accordingly: instead of a
  full-page prompt reached from onboarding, it's now a compact popup
  shown once, right after a user's first successful login. See
  "Mandatory signup/login and the popup trigger" below.

| Included | Excluded |
| --- | --- |
| Automatic discovery of candidate images via granted photo-library permission, online only | Background, scheduled, or silent import |
| One candidate per discovered file | Document creation without explicit confirmation |
| Review, editing, deselection, and confirmation before any document is created | Manual multi-select picking as the way to build a bulk batch |
| AI-driven inclusion decision + categorization + tagging in one call per candidate, always on | Automatic grouping, deduplication |
| | Broad filesystem access (`MANAGE_EXTERNAL_STORAGE`) and Android Downloads/Documents discovery — tried, then removed over Play Store policy risk |
| | Working offline — this feature requires network, by explicit requirement |

## Process

1. **Trigger** — a compact popup (`BulkImportPopup`, not a full page), shown
   once right after a user's first successful login, and reusable on demand
   from **Profile → Find more documents**: *"Find your documents"* /
   *"Not now."* No manual "Choose from Gallery"/"Choose from Files"
   buttons — one action starts discovery. See "Mandatory signup/login and
   the popup trigger" below for how/when it fires.
2. **Connectivity check** — discovery requires network; if there's none, a
   short offline state with a **Retry** action is shown before anything
   else runs (no point prompting for photo permission just to fail right
   after).
3. **Permission request** — exactly one OS prompt: Photos library access on
   iOS, `READ_MEDIA_IMAGES` on Android. Requested only when the user taps
   the trigger (and only once online), never proactively.
4. **Enumeration** — metadata-only listing (no file content read yet),
   sorted newest-first: photo library, both platforms, via
   `photo_manager`'s image `RequestType` (iOS `PHPhotoLibrary`, Android
   `MediaStore` `Images` collection). Android Downloads/Documents (PDFs
   saved by other apps) was tried and removed — see "Android
   Downloads/Documents (removed)" below.
5. **Cheap exact filters** (no guessing), applied before anything is copied,
   OCR'd, or sent to the AI: drop videos, animated images (iOS Live Photos
   via `isLivePhoto`; GIFs by file extension), **PNG** files, assets below
   a minimum resolution (icons/stickers/thumbnails), and anything with no
   readable OCR text at all. These are free/local, unlike the AI step
   below, and exist specifically to avoid spending a network call on
   something that obviously isn't a document.
   - **Note on PNG and screenshots**: excluding PNG was an explicit later
     request to cut down false positives, but it's in tension with an
     earlier decision in this same doc not to exclude screenshots (iOS and
     Android screenshots are PNG by default, so excluding PNG excludes
     most screenshots too, including legitimate ones like boarding passes
     or receipts someone screenshotted). As implemented now, PNG wins —
     screenshots saved as PNG won't be discovered. Flagging this
     explicitly since it reverses that earlier reasoning rather than
     refining it.
6. **Scope** — defaults to assets from the last 12 months; a follow-up
   "Scan older photos too" action (from Profile) widens the range later.
7. **Document classification, categorization, and tagging — one AI call**
   — run OCR extraction (`DocumentProcessingUseCases.extractText()`) on
   filtered survivors, then send the extracted text to
   `DocumentProcessingUseCases.analyze()` (the same AI service Add
   Document's own suggestions use). Its response now decides inclusion
   (`isDocument`) *and* supplies title/category/tags/description/expiry in
   the same call — see "Why AI replaced a local classifier" below.
   Below-threshold assets are discarded silently before reaching review —
   they're not shown as a "rejected" pile, since that would be worse UX
   than just not surfacing them. A failed AI call (any reason — offline
   mid-call, bad response, etc.) never silently drops a candidate: it's
   included anyway, retryable from the review screen, rather than lost.
8. **Candidate creation** — survivors become `BulkImportCandidate`s,
   pre-selected (`isSelected = true`) and already carrying the AI's
   suggested title/category/tags/description/expiry, staged into
   `<app documents>/import_staging/<session-id>/` exactly as the removed
   manual flow did.
9. **Review screen** (unchanged mechanics, different input source) —
   thumbnail, editable title/category/tags/description/expiry, select-all/
   deselect-all, bulk-categorize, remove, retry failed analysis, confirm
   with a count ("Import 12 documents"). Nothing is written to the document
   database before confirmation.
10. **Commit** — one `DocumentItem` per selected candidate via the existing
    `DocumentUseCases.addDocument()`, same staging-promotion/rollback rules
    as before.
11. **Incremental watermark** — after a successful scan, persist the newest
    processed asset identifier/timestamp via the existing `Storage` utility.
    The persistent re-entry point (**Profile → Find more documents**) re-runs
    discovery from that watermark, so repeat scans only process new assets.

### If permission is denied

Show the reason discovery needs the permission, an **Open Settings** action,
and **Not now** (closes the popup, no documents imported). There is no
manual-picker fallback inside Bulk Import — a user who declines can still add
documents individually via the existing, separate "+ Add Document" feature.
This is a deliberate trade-off: the whole point of this redesign is removing
manual per-file picking from bulk import, so reintroducing it as a fallback
would undercut that. Flagging this explicitly since it's a real UX cost for
users who decline the permission, not an oversight.

### Mandatory signup/login and the popup trigger

Signup/login is now required before reaching Home at all, with no skip —
this reverses this repo's own documented rule that no part of the core app
should gate on a signed-in user (`CLAUDE.md`). Flagging the conflict
explicitly since it's written down elsewhere as a constraint; proceeding
because the direction was explicit and repeated product direction, not an
oversight.

Mechanics:

- `SplashViewModel.resolveNextRoute()`: once onboarding has been seen, it
  loads the session (`SessionController.loadUserFromStorage()`) and routes
  to Home if signed in, Signin otherwise — previously it never checked
  auth state at all.
- `OnboardingViewModel.completeOnboarding()`: always hands off to Signup
  now (new users), instead of branching to Home or Bulk Import's old
  full-page intro.
- Signup itself does **not** auto-sign-in — it only triggers email OTP
  verification; `SessionController.saveUserInStorage()` and the actual
  `RouteNames.home` navigation happen in Signin, once verification
  completes and the user signs in. "First login" in product terms is
  really signup → verify → signin in code terms.
- `ProfileViewModel.signOut()` now navigates to Signin after clearing the
  session — signing out leaves the app, it no longer drops into a
  local-only in-app state.
- **Bulk Import's popup trigger is deliberately decoupled from which auth
  path was taken.** `NavbarView` (the `home` route's root widget, wrapping
  the bottom-tab shell) checks `StorageKeys.hasSeenBulkImportPrompt` once
  in `initState` and shows `BulkImportPopup` if it hasn't been seen — this
  fires exactly once, the first time Home is actually reached, regardless
  of whether that was via signup→verify→signin or a plain signin. This is
  the same storage flag and "seeing it counts as shown" semantics the old
  full-page intro already used, just relocated from onboarding-time to
  first-Home-reached-time.
- Profile's existing "not signed in"/local-only UI state is now
  unreachable in normal use (it can only flash briefly during the
  sign-out redirect) — left in place as defensive code rather than
  deleted, to avoid unrelated scope creep.
- **Known limitation, not solved here**: no `go_router` `redirect:` guard
  was added — this matches the existing router's pattern (no guards
  anywhere today; access control happens at the few navigation decision
  points above, not centrally), so a typed/deep-linked path could in
  principle still reach a gated screen without going through Signin
  first. Flagged as a known gap, not fixed, since a central guard would
  be new architecture this router doesn't otherwise use.

### What this removes from the implemented V1/V1.1 code

- The **Choose from Gallery** / **Choose from Files** entry points on the
  Bulk Import intro screen, and the bulk multi-select calls into
  `DeviceAttachmentDataSource.pickFromGallery()` / `pickFile()` that fed
  candidate creation from them.
- Any bulk-import code path that creates a `BulkImportCandidate` from a
  manually-picked `AttachmentItem`.
- Tests in `test/features/bulk_import/` that exercise the manual-picker
  entry points (candidate creation from `pickFromGallery`/`pickFile`) need
  rewriting against the discovery datasource instead.

### What this keeps unchanged

- The review screen's editing/selection/confirmation mechanics.
- Staging directory lifecycle, promotion, and rollback rules.
- The sequential, concurrency-1 processing queue (`_enqueue`/`_process`),
  and the rule that an AI result never overwrites a user-edited field —
  now used only for `retry()` on a candidate whose discovery-time AI call
  failed, since discovery itself applies a successful result inline.
- The 25-candidate cap reaching review at once (discovery reports "N more
  found" rather than silently dropping or raising it).
- Mapping a confirmed candidate to a `DocumentItem` via the normal
  `DocumentUseCases.addDocument()` path.

**No longer true, by explicit reversal**: AI suggestions are not opt-in
anymore. The old design had two separate passes — a free local classifier
decided inclusion, and a separate opt-in (`suggestionsEnabled`, default
off) background pass called the AI for metadata only. Both are gone,
replaced by one mandatory AI call per candidate that decides inclusion
*and* supplies metadata — see "Why AI replaced a local classifier" below.

### Deferred

- Android Downloads/Documents discovery (PDFs saved by other apps) —
  built, then removed. It needs `MANAGE_EXTERNAL_STORAGE`, which Google
  Play restricts to apps whose core purpose is broad file management;
  see "Android Downloads/Documents (removed)" below.
- iOS Downloads/Files-app discovery — no enumerable "shared storage"
  equivalent to Android's `MediaStore` collections exists on iOS without a
  separate document-provider integration; iOS discovery covers the Photos
  library only.
- Background or scheduled re-scans — discovery only runs on explicit user
  action (initial trigger or "Find more documents"), never a timer.
- Candidate combine/grouping (e.g. merging an ID card front/back into one
  multi-page document) and duplicate detection.
- Scanner/camera as a bulk source; a scanner session naturally produces
  pages of one document and remains in Add Document.

## Implementation notes and deviations

Real engineering choices made while building this that differ from or add
detail beyond the sketch above:

- **No separate scanning screen/route.** Scan progress and the
  permission-denied/offline states are shown inline within
  `BulkImportFlowContent` (a progress indicator and button states swap in
  place) — shared by both the popup (`BulkImportPopup`) and a thin
  full-page fallback (`BulkImportIntroView`, kept only so the old
  `RouteNames.bulkImport` route still resolves to something sensible for
  a direct/malformed navigation; not linked from the real flow anymore).
- **No separate permission package.** `photo_manager` already exposes
  `requestPermissionExtend()` and `openSetting()`, covering both the
  prompt and "Open Settings" for photo-library access. `permission_handler`
  was added briefly, specifically for `Permission.manageExternalStorage`
  (the Downloads/Documents source), and removed again along with that
  source — nothing else in this feature needs it.
- **iOS/Android photo-permission declarations already existed** in this
  repo (`NSPhotoLibraryUsageDescription` in `Info.plist`,
  `READ_MEDIA_IMAGES`/`READ_MEDIA_VIDEO`/`READ_EXTERNAL_STORAGE` in
  `AndroidManifest.xml`) — nothing needed adding there.
  `MANAGE_EXTERNAL_STORAGE` was added for the Downloads/Documents source
  and then removed with it — see that section.
- **No double OCR.** `_process()` (now only reached via `retry()`) reuses
  `candidate.ocrText` since discovery already populated it, instead of
  calling `extractText` again on the same file.
- **Connectivity is an injected dependency, not a hardcoded singleton
  call.** `BulkImportViewModel` takes `Future<bool> Function()
  checkConnectivity` in its constructor, defaulted at the DI site
  (`injection_container.dart`) to
  `InternetConnectionChecker.instance.hasConnection` — the same package
  `DioHelper` already uses the same way. This keeps the viewmodel unit-
  testable against a fake instead of real connectivity.
- **First-pass constants, not yet tuned against real photo libraries:**
  minimum asset dimension 256px, default scan window 365 days, 150
  photo-library assets examined per scan. This budget was sized when the
  per-asset check was a free local classifier; under the AI design, every
  examined asset with any readable text now costs a real network
  round-trip. Not re-tuned yet — flagged as a likely follow-up once
  real-world latency/cost is observed. The AI calls also stay fully
  sequential (same loop, same OCR isolate-safety constraint as before,
  no new concurrency added) — a scan with many real documents will take
  longer wall-clock than the old free-classifier version did.
- **Document classification went through three revisions, the first two
  now fully superseded:**
  1. A flat 40-character minimum — too permissive, imported ordinary
     photos of people.
  2. A length+line-count+word-count density check (150 chars / 4 lines /
     20 words) — still too permissive. A menu board, storefront sign, or
     poster behind a person is itself often multi-line and word-dense, so
     a person photo with that kind of background still cleared it. This
     was the actual repeated complaint ("it picked up my picture").
  3. A local keyword/MRZ/regex classifier (`_looksLikeDocument`) — matched
     specific vocabulary/structure (MRZ lines, "INVOICE", "SUBTOTAL" plus
     prices, etc.) instead of approximating "document" via density. Fixed
     the reported false positives, free and fully offline, but could only
     ever recognize the specific categories/keywords/languages it was
     written for.
  4. **Current**: replaced by a mandatory AI call — see "Why AI replaced a
     local classifier" below. Applies to every discovered candidate
     uniformly, online only.
- **Overflow handling in `discover()`:** once the 25-candidate review cap
  is reached, remaining discovered assets are left completely unprocessed
  (never staged or OCR'd) and the watermark only advances past what was
  actually processed — so a follow-up scan picks up exactly where this
  one stopped, rather than skipping anything.
- Added dependency: `photo_manager: ^3.6.4` (resolved 3.12.0) for the
  photo library. `permission_handler` was added, then removed, along
  with the Downloads/Documents source it existed for. `content_resolver`
  (already a dependency, used elsewhere for Add Document's scanner flow)
  is **not** used by this feature.
- **Cheap filters also exclude PNG and GIF files, and iOS Live Photos**
  (`AssetEntity.isLivePhoto`) — on top of the dimension/video filters
  already in place. **This is in direct tension with the earlier decision
  not to exclude screenshots** (both platforms save screenshots as PNG by
  default), so a screenshotted receipt or boarding pass will no longer be
  found by a scan. Implemented as explicitly requested, not a judgment
  call — flagging the conflict rather than silently reversing the earlier
  reasoning.

### Why AI replaced a local classifier

The local keyword/MRZ classifier (described above) worked and was free,
but by explicit product direction, document classification, categorization,
and tagging should all be AI-driven rather than a hand-maintained keyword
list — partly for accuracy (a model generalizes past the specific
categories/keywords/languages a regex list happens to cover), and partly
because categorization/tagging were already AI-driven for Add Document's
own suggestions; unifying onto one mechanism avoids maintaining two
separate "is this a document, and what is it" systems.

**Mechanism**: `AiDocumentService._systemPrompt()` (`lib/core/ai/
ai_document_service.dart`) now asks for an `"isDocument"` boolean alongside
its existing title/category/description/tags/expiry fields — true only
for an actual personal document (passport, ID, receipt, invoice, bill,
contract, etc.), false for incidental text in an ordinary photo (people,
signage, menus, screenshots, etc.), with an explicit "prefer false when in
doubt" instruction. `AiDocumentSuggestion.isDocument` defaults to `true`
when the field is missing/malformed in the response — this keeps Add
Document's own manual-pick call site (which never reads this field, since
a file the user deliberately scanned is already known to be a document)
completely unaffected by this addition.

`BulkImportViewModel.discover()` calls `analyze()` **inline, synchronously,
in its existing sequential per-asset loop** — no new concurrency, same
loop that already ran OCR per asset:

- `analyze()` throws or returns `null` (any failure — offline mid-call,
  malformed response, etc. are all collapsed into `null` by
  `AiDocumentService`'s own contract) → the candidate is **included
  anyway**, in `CandidateProcessingState.failed`, retryable from review.
  A transient AI/network failure must never silently drop a real
  document.
- `isDocument == false` → rejected, removed from staging, never reaches
  review.
- `isDocument == true` → accepted, with title/category/tags/description/
  expiry seeded directly from the response (via a shared
  `_applySuggestion` helper also used by `retry()`, so both paths apply a
  successful result identically).

Trade-off, accepted deliberately: this feature cannot work at all without
a network connection anymore (see the connectivity gate above) — a
meaningful regression from the old fully-offline design, but explicit
product direction. A missed/misclassified document can still be fixed
manually via "+ Add Document" or editing in review.

A real device/face-detection enhancement to distinguish "a selfie" from
"a small ID photo printed on a passport" was considered earlier (when the
classifier was still local) but never built — moot now that the AI call
itself makes that distinction as part of `isDocument`.

### Android Downloads/Documents (removed)

**History**: the first implementation queried `MediaStore.Files` for PDFs
under the `Download`/`Documents` relative paths, scoped-storage-safe and
requesting no broad permission. Real-device testing (not a simulator)
showed this didn't actually find real-world files — a PDF bill
downloaded via a browser never surfaced. Root cause: scoped storage
(API 29+) lets an app query/read its own files plus *media* (photos/
video/audio) shared by other apps, but not arbitrary non-media files
(like a PDF) another app created — a `MediaStore.Files` query for those
either returns nothing or can't actually read their bytes, regardless of
Android version, without `MANAGE_EXTERNAL_STORAGE`.

A second implementation requested `Permission.manageExternalStorage` (the
`permission_handler` package — a full-screen system settings grant, not a
simple runtime dialog), then listed `Download`/`Documents` directly via
`dart:io` once granted, with one native call
(`Environment.getExternalStorageDirectory()`) to resolve the real storage
root. This worked, but was reverted before shipping once its Play Store
risk was weighed against the feature's value:

- `MANAGE_EXTERNAL_STORAGE` is a sensitive permission Google Play
  restricts to apps whose *core purpose* is broad file management (file
  explorers, backup tools, antivirus, disk cleaners). Docketly's core
  purpose is document organizing — this source was one onboarding
  convenience feature within that, not the app's reason for existing —
  so it does not meet Play's bar, and Play's manual review specifically
  rejects apps using it for a secondary feature when an alternative API
  exists.
- An alternative does exist: the Storage Access Framework (SAF) folder
  picker — the user explicitly picks their Downloads folder once via the
  system folder picker, and the app gets a persisted grant to just that
  folder, with no broad permission at all. This is the Play-compliant
  path if this source is revisited.
- Beyond the initial review, Play periodically re-audits apps holding
  this permission; a failed re-audit risks the *whole app* being pulled,
  not just this feature — a materially worse outcome than not having
  Downloads/Documents discovery.

**Current state**: removed entirely. `GalleryDiscoveryDataSource` only
enumerates the photo library; `MANAGE_EXTERNAL_STORAGE` is no longer in
`AndroidManifest.xml`; `permission_handler` is no longer a dependency;
`MainActivity.kt` no longer has a storage method channel. If
Downloads/Documents discovery is wanted later, implement it via SAF, not
`MANAGE_EXTERNAL_STORAGE`.

## Current codebase and reuse

| Component | Current behavior | Role going forward |
| --- | --- | --- |
| `DeviceAttachmentDataSource.pickFromGallery()` / `pickFile()` | Manual multi-select pickers | **Removed from Bulk Import.** Remains used only by the separate single-document Add Document feature — untouched there. |
| `AttachmentSelection` / `AttachmentItem` | Picker attachment types | Reused as the shape discovery output is normalized into, so the rest of the candidate pipeline doesn't change. |
| `DocumentProcessingUseCases.extractText()` | OCR extraction for a path | Reused for discovery's AI-analysis input and review-screen retries; same call either way now. |
| `DocumentProcessingUseCases.analyze()` | AI title/category/description/tags/expiry suggestions, now also `isDocument` | Reused as the mandatory inclusion decision for discovery, not just an opt-in metadata suggestion. |
| `DocumentUseCases.addDocument()` | Persists and updates local state | Final commit path, unchanged. |
| `BulkImportViewModel` / review screen | Built for manually-picked candidates | Unchanged mechanics; candidate list now populated by discovery instead of picker callbacks. |
| `Storage` (core local storage utility) | Key-value local storage | New use: persists the discovery watermark (last-scanned asset id/timestamp). |

`image_picker`/`file_picker` stay in `pubspec.yaml` for single-document Add
Document but are no longer invoked by Bulk Import. Discovery added
`photo_manager` (asset enumeration) for the photo library.

## Architecture

```text
features/bulk_import/
  domain/entities/bulk_import_candidate.dart
  domain/repositories/bulk_import_repository.dart
  domain/usecases/bulk_import_usecases.dart
  data/gallery_discovery_datasource.dart       # asset enumeration + metadata filters (replaces manual picker datasource calls)
  data/discovery_watermark_store.dart          # last-scanned asset id/timestamp via Storage
  data/bulk_import_local_datasource.dart       # staging/commit, unchanged
  presentation/bulk_import_flow_content.dart   # the actual prompt/progress/error state machine, container-agnostic
  presentation/bulk_import_popup.dart          # shows the flow content in a compact Dialog -- the real entry point
  presentation/bulk_import_intro_view.dart     # thin full-page Scaffold wrapper, kept only as a route fallback
  presentation/bulk_import_review_view.dart    # unchanged
  presentation/viewmodel/bulk_import_viewmodel.dart
```

`BulkImportViewModel` owns the temporary batch and exposes immutable
candidates, selected count, progress, edit actions, and commit state. The
discovery datasource implements the domain repository contract directly; the
ViewModel depends on `BulkImportUseCases`, not platform or storage code. The
review route owns and disposes one ViewModel per session.

```dart
class BulkImportCandidate {
  final String id;
  final AttachmentItem attachment; // One file per candidate.
  final String title;
  final String categoryId;
  final List<String> tags;
  final String ocrText;
  final CandidateProcessingState state;
  final bool isSelected;
  final bool hasUserEditedTitle;
  final bool hasUserEditedCategory;
  final bool hasUserEditedTags;
  final String description;
  final DateTime? expiryDate;
  final bool hasUserEditedDescription;
  final bool hasUserEditedExpiry;
  final String? error; // AI analysis failure, non-fatal.
  final String? importError; // Save failure, staged file retained.
}
```

An AI result must merge only into fields the user has not edited.

## File lifecycle: staging is required

Normal attachment picking (in the separate Add Document feature) copies
immediately into permanent `<app documents>/documents/`. Bulk Import needs a
temporary area so cancellation does not leave orphaned files — this is
unchanged by moving from manual picking to discovery as the candidate
source.

```text
<app documents>/import_staging/<session-id>/
```

1. Copy discovered files into the active session directory.
2. Generate previews and OCR only from staged copies.
3. On confirmation, move/copy accepted files into `documents/`, then create
   their `DocumentItem` rows.
4. On Cancel, remove the entire staging directory.
5. On app launch, best-effort cleanup removes stale sessions.
6. A failed move/copy must not create a database row pointing to a missing
   file; retain that candidate for retry or discard.

Promotion copies the file; a database failure rolls back that promoted copy.
Staged copies are removed after successful saving or candidate removal.
Removing/cancelling an in-flight native OCR operation invalidates its result
immediately, but defers deletion of its input until it releases the file.
Leaving the screen does not wait for native OCR. On startup, abandoned
session directories are removed before new sessions can begin. Cleanup
failures are best-effort and retried at the next launch.

Commit candidates one at a time. Successful imports remain successful when a
later candidate fails; show an import summary identifying the failed items.

## Processing and performance

Do not assume native OCR is isolate-safe. Plugin calls may require Flutter's
main isolate. Preserve the current asynchronous approach and process
OCR/analysis with queue concurrency **1**.

- Show numeric scan progress during discovery (`Scanning… N of 150
  checked · M found`) — OCR and the AI call both happen inline within
  that same pass now, there's no separate post-discovery "Processing 7 of
  24" stage anymore.
- Cancel queued processing for removed/deselected candidates (applies to
  `retry()`'s queue now, since discovery's own AI call is inline).
- Cap candidates reaching review at **25**, before copying excess files.
  Discovery reports "N more found" when it exceeds this.
- An AI call failure is non-fatal; the candidate still reaches review
  (`failed` state, retryable) with manual title/category entry available.
- Deselecting cancels a pending retry; reselecting resumes it. Removed
  rows and disposed sessions cannot receive late updates. Only one
  OCR/AI-analysis task runs at a time within a session, including
  retries.
- OCR currently supports images and the first five PDF pages (though
  discovery itself only ever finds images now — PDFs only ever entered
  this pipeline via the removed Downloads/Documents source).
- The AI service does not return confidence scores. Only an exact
  category-name match is accepted; missing/unknown categories remain
  Uncategorized. There is no numeric confidence threshold for
  categorization — separate from the `isDocument` inclusion decision
  (step 7 above).

## Mapping to documents

On confirmation, each selected candidate creates one `DocumentItem` via
`DocumentUseCases.addDocument()`.

| Field | Source |
| --- | --- |
| `id` | Stable `bulk_<candidate-id>` across save retries |
| `title` | Trimmed candidate title, required |
| category fields | Selected category, Uncategorized fallback |
| `tags` | Candidate tags; cap suggested tags at three |
| `filePaths` | Accepted files moved from staging |
| `createdAt` | Confirmation time |
| `ocrText` | Extracted text or empty string |
| description/expiry | Reviewed metadata; AI results respect user edits, including cleared expiry |

Using the normal document use case preserves category counts, recents,
search, backups, and notification behavior.

## Platform rules

- Signup/login is required before Home is reachable at all, app-wide —
  see "Mandatory signup/login and the popup trigger" above. This is
  outside Bulk Import's own scope but gates its new trigger point.
- Photo-library discovery requests exactly one permission — Photos
  library on iOS, `READ_MEDIA_IMAGES` on Android. Requires
  `NSPhotoLibraryUsageDescription` in `Info.plist` and the
  `READ_MEDIA_IMAGES` entry in `AndroidManifest.xml`, both stating the
  discovery purpose in the permission prompt copy itself (platform-level
  copy, not just the in-app screen).
- Discovery requires network and will not request photo permission at all
  if there's none (see the connectivity gate above).
- `pickMultiImage()` / `FilePicker.pickFiles()` remain in use by the
  separate single-document Add Document feature only; Bulk Import no longer
  calls them.
- Keep **Share into Docketly** routed to Add Document, unchanged.
- Report unsupported/unreadable discovered files as skipped; never fail a
  whole batch for one file.

## Acceptance criteria

- Bulk Import's only entry points are the one-time popup shown right
  after a user's first login, and **Profile → Find more documents**
  (same popup, reused) — there are no manual Gallery/Files buttons and no
  full-page intro in the real flow.
- Declining the discovery permission shows Settings/Not now, with no
  in-flow manual-picker fallback; the separate Add Document feature remains
  available for individual documents.
- Discovery refuses to run offline — a clear offline state with Retry is
  shown before photo permission is even requested.
- Discovery never reads file content before the exact metadata filters run.
- Screenshots are never excluded by the discovery filters.
- Inclusion is decided by AI (`isDocument` on the `analyze()` response),
  not a local heuristic — see "Why AI replaced a local classifier" above.
  A failed AI call never silently drops a candidate.
- Scan progress is visible and numeric (examined/budget and a running
  found count), not just an indeterminate spinner.
- A repeat scan only processes assets newer than the stored watermark.
- Each discovered candidate becomes an editable review row; users can edit,
  select/deselect, remove, and bulk-categorize before confirming.
- Cancel creates no documents and leaves no staged files.
- Confirm creates one document per selected candidate; partial failures
  report failed items without losing successful imports.
- Candidates reaching review are capped at 25; excess matches are reported,
  not silently dropped or the cap silently raised.
- AI results (title/category/tags/description/expiry) never overwrite
  user edits, and failed analysis leaves a candidate manually importable.
- Discovery requires network throughout — there's no offline fallback
  anymore; only the review/commit flow (after discovery has already run)
  works without a connection.

## Implementation order

1. Choose and add the asset-enumeration and permission-request packages.
2. Remove the Gallery/Files bulk entry points and manual-picker candidate
   creation from `bulk_import`; keep the single-document Add Document
   feature's pickers untouched.
3. Build `GalleryDiscoveryDataSource`: permission request, enumeration,
   cheap exact filters.
4. Add document-likelihood OCR scoring and the discovery progress screen.
5. Add `DiscoveryWatermarkStore` and wire the persistent "Find more
   documents" re-entry point to it.
6. Wire discovery output into the existing candidate/review/staging/commit
   pipeline (should require no changes to that pipeline beyond its input
   source).
7. Update/rewrite `test/features/bulk_import/` tests that assumed
   manual-picker candidate creation.
8. Device verification: permission-denied path, large galleries, repeat-scan
   watermark behavior, real Android/iOS discovery (including cloud-backed
   photo libraries).

## Recorded decisions

| Decision | Rationale |
| --- | --- |
| Automatic discovery replaces manual multi-select as Bulk Import's only candidate source | Removes per-file manual picking for the common case; explicit product direction |
| No in-flow fallback picker on permission denial | Reintroducing manual picking as a fallback would undercut the point of removing it; single-document Add Document covers that case instead |
| Discovery reuses the existing review/staging/commit pipeline unchanged | Avoids a second parallel import path to maintain |
| Screenshots are never filtered out | Many legitimate documents (boarding passes, receipts) are screenshots; the signal is unreliable as an exclusion rule |
| Below-threshold discovery results are not shown for review | A large "rejected" pile is worse UX than simply not surfacing non-documents |
| Android Downloads/Documents discovery removed | Needs `MANAGE_EXTERNAL_STORAGE`, which Play Store policy restricts to broad file-management apps and periodically re-audits; too much ship/standing risk for one onboarding convenience feature. SAF is the Play-compliant path if revisited |
| iOS Downloads/Files discovery deferred | No scoped-storage-equivalent API exists on iOS without a separate document-provider integration |
| 25-candidate review cap retained | Keeps sequential native OCR predictable |
| Three suggested-tag limit retained | Useful metadata without noisy tag dumps |
| No automatic grouping | Incorrect merges are costly; manual combine can come later |
| Staging directory before confirmation | Prevents cancelled batches leaving permanent files |
| AI (`isDocument`) replaces the local keyword/MRZ classifier for inclusion | Explicit product direction; unifies with Add Document's existing AI-driven categorization/tagging instead of maintaining two systems |
| Discovery is online-only, no offline fallback | The inclusion decision itself now requires the AI call; explicit product direction, accepted as a real regression from the prior fully-offline design |
| A failed AI call includes the candidate (retryable) rather than dropping it | A transient network/service failure must never cost the user a real document |
| Signup/login made mandatory app-wide, reversing this repo's own "never gate on sign-in" rule | Explicit, repeated product direction |
| Bulk Import's trigger moved from a post-onboarding page to a popup shown once after first login | Matches the new mandatory-auth flow; also addresses a separate ask to shorten/simplify the prompt's UI |
| Popup content is shared between the first-login trigger and Profile's manual re-entry point | One UI to maintain instead of two; both call sites wanted the same simplification |

## Verification and remaining checks

`flutter analyze --fatal-infos` is clean and `test/features/bulk_import/`
(now including a `FakeConnectivity` seam and AI-flag-driven classification
tests in place of the old keyword-text-driven ones) plus
`test/architecture/` pass — 30 tests total, covering:

- Staging, original-file preservation, per-item removal, rollback, session
  isolation, skipped files, size limits, and startup cleanup.
- Required titles, metadata mapping, partial save failures, retry without
  duplication, and edits during save.
- The sequential processing queue, dirty-field protection, tag validation,
  retry, deselection/reselection, cancellation during discovery, and
  disposal — now exercised via `retry()` on a failed AI call rather than
  the old opt-in post-discovery queue.
- Review rendering in light and dark themes at small screen sizes with
  enlarged text, row/controller identity, and Back navigation.
- Discovery's exact filters, watermark persistence and incremental
  re-scan, permission-denied path, the 25-candidate overflow report, the
  offline gate, and AI-flagged accept/reject of a candidate.

Architecture checks also include this feature. Diagnostic events contain
only operation names and counts; document text, filenames, and paths are not
logged by Bulk Import.

**Not verified in this environment** (same pre-existing limitation as
before — this repo's Gradle/JDK combination can't compile native changes
here): the mandatory-auth routing changes (`SplashViewModel`,
`OnboardingViewModel`, `NavbarView`'s new `initState` hook,
`ProfileViewModel.signOut()`) and the popup itself were reviewed by
reading, not exercised on a device/simulator. Before release, verify on a
real device: the full signup → verify → signin → popup → review flow for
a brand-new account, that a returning signed-in user skips straight to
Home without the popup reappearing, that sign-out actually returns to
Signin, and real-world AI-call latency/cost across a typical photo
library (see the `maxExaminedPerScan` caveat above).

Before release, verify real Android/iOS photo-library discovery (including
cloud-backed libraries), permission denial, native OCR, and an interrupted
app session. Automated tests use fakes plus real temporary filesystem
operations; they do not replace these native-device checks.
