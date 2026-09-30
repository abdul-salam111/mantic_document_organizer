# Mantic Document Organizer — Technical Implementation Spec

2026-09-22 · @Someone

This document is the single technical reference for how Mantic is built — architecture, stack, data model, screens, and phase-by-phase implementation. Intended for engineering use and as context for AI-assisted development (e.g. Claude Code) on this project.

## Architecture overview

Mantic is **offline-first** for everything core, and **online-enhanced** for AI features.

- **Client (Flutter app):** owns all core functionality — capture, categorize, organize, search by keyword, favorites, trash. Works fully with zero network connection, from first launch, with no account.
- **Local database (sqflite/SQLite):** the source of truth on-device. All reads/writes for normal use hit this, never the network.
- **Backend (FastAPI + PostgreSQL):** not required for core use. Comes into play only when: (a) the user opts into an account for backup/sync, or (b) an AI feature (Phase 3) is invoked and needs a live model call.
- **AI features are call-time, not always-on:** OCR, auto-tagging, and deadline detection (Phase 2) run entirely on-device — no network needed. AI search, summaries, and clustering (Phase 3) need connectivity *at the moment they're used*: the app narrows to a few locally-relevant documents first (offline), then sends just that small slice to a language model over the network for the actual answer. If there's no connection, the app shows a clear "needs internet" state for that one feature — everything else keeps working.
- **Sync (Phase 4) is additive, not foundational:** once implemented, it reconciles the local database with the backend in the background. The app is designed so it never depends on sync succeeding to function correctly offline.

## Tech stack & key package decisions

| Layer | Choice | Why |
| --- | --- | --- |
| Mobile app | Flutter | One codebase for iOS + Android |
| State management | Riverpod or Bloc | Standard, testable; pairs with sqflite through a repository/provider layer for reactive UI updates |
| Local database | sqflite | Relational (matches our data model), a thin well-understood wrapper directly over each platform's native SQLite, no code-generation step, large community and long track record |
| Document scanning (Android) | `google_mlkit_document_scanner: ^0.6.1` | Native Google Play Services scanning UI: edge detection, auto-capture, multi-page, crop/filter built in. Android only, beta |
| Document scanning (iOS) | `flutter_doc_scanner` (wraps Apple VisionKit) or a direct VisionKit binding | Equivalent native scanning UI on iOS, since the ML Kit package has no iOS support |
| On-device OCR | Google ML Kit Text Recognition | Fully offline, fast, no server round-trip |
| Backend | Python (FastAPI) | Async, fast to build REST endpoints, good fit for a small team |
| Backend database | PostgreSQL | Relational, mirrors the local sqflite schema, mature full-text search for Phase 2 |
| File storage | Local disk (MVP) → the user's own Google Drive (backup/sync) | No storage infra cost to us; reuses the Google sign-in already offered for backup; user keeps ownership and visibility of their own files |
| Google Drive integration | google\_sign\_in + googleapis (Drive API v3), drive.file scope | drive.file only requests access to files the app itself creates, avoiding Google's stricter sensitive-scope review; files go into a visible "Mantic Backups" folder in the user's Drive |
| Auth | FastAPI + JWT, Google OAuth | Standard, optional — only used once a user opts into backup |
| AI / language model | Anthropic API (Claude) | Used for AI search answers (Phase 3) and summaries; called only when those features are invoked |
| Vector store (Phase 3) | pgvector (Postgres extension) or a dedicated vector DB | Stores document embeddings for AI search and clustering; reuses the existing Postgres instance if pgvector is used, keeping infra simple |
| Push notifications (Phase 2 reminders) | Local notifications via the OS (no server push needed initially) | Deadline reminders are computed on-device from already-local data, so no server round-trip needed to schedule them |

## Data model

The same shape is used locally (sqflite/SQLite) and on the backend (PostgreSQL) so sync stays simple. `fields` is stored as JSON in both, since it varies per category.

| Table | Fields | Notes |
| --- | --- | --- |
| User | id, email, name, auth\_provider, created\_at | Only populated once an account is created; app works with zero rows here |
| Category | id, name, icon, field\_schema (JSON list of {name, type: text\|date\|number}), is\_custom, is\_essential, created\_at | 13 built-in rows seeded on first launch, plus any user-created ones. `is_essential` flags categories that count toward the document-completeness progress indicator (see below) |
| Document | id, user\_id (nullable until account exists), category\_id (defaults to Uncategorized), title, description, fields (JSON, keyed by field\_schema), tags\[\], is\_favorite, page\_count, pdf\_url, thumbnail\_url, created\_at, deleted\_at (soft delete) | Core entity |
| Page | id, document\_id, image\_url, order, filter\_applied | One row per scanned/imported page |
| Tag | id, user\_id, name | Free-form, many-to-many with Document via `tags[]` |
| Todo | id, document\_id, text, is\_done, created\_at | Per-document to-do list |

**Phase 2 additions:** `Document.ocr_text` (extracted text, indexed for full-text search), `Document.detected_dates` (JSON, from deadline detection).

**Phase 3 additions:** `Document.embedding` (vector, for AI search/clustering similarity).

**Phase 4 additions:** `Vault` (id, name, owner\_id), `VaultMember` (vault\_id, user\_id, role), `Document.vault_id` (nullable), `VoiceNote` (id, document\_id, audio\_url, transcript).

## Screens & navigation

Bottom tabs: **Home, All Docs, Favorites, Profile**, with a centered raised "+" button docked into the nav bar as the single entry point for adding a document.

| Screen | Purpose |
| --- | --- |
| Splash | Brief load, straight to Home — no auth gate |
| Home | Search bar, with a document-completeness progress bar directly beneath it when essential documents are missing (hidden once complete); categories as a 2-column grid (icon, name, file count) ending in Uncategorized + a "New Category" tile; Recent documents strip |
| New Category | Name input, icon picker (8+ options), optional custom field builder (Add field → name + type: Text/Date/Number, removable) |
| All Docs | Flat grid of every document across categories |
| Favorites | Hearted documents; tap the heart to unfavorite in place |
| Profile (not signed in) | Document-completeness progress bar when essential documents are missing (hidden once complete); local-only status, "Set up backup" CTA, storage used, link to Trash, app version |
| Set up backup | Continue with Google, or name + email form |
| Profile (signed in) | Document-completeness progress bar when essential documents are missing (hidden once complete); avatar/initials, name, email, sync status, Edit profile, Sync now, Storage, Trash, Log out |
| Add a document (source picker) | Bottom-sheet overlay: Take Photo / Choose from Gallery / Cancel |
| Camera / Scan | Live edge-detection viewfinder, capture, running page count, Done |
| Review | Captured page preview, filter chips (Color/Grayscale/B&W), page filmstrip (select/delete), Retake/Next |
| Save document | Category-specific fields (e.g. Driving License: name, license no., DOB, valid till), to-do list, Save |
| Document viewer | Paged view, favorite toggle, page strip, Export/Share/Rename/Move/Delete |
| Category view (Folder) | Grid of documents in one category, add-to-category button |
| Search | Search input + results (title/category/date), opened from Home's search bar, not a tab |
| Trash | Restore / Delete forever, 30-day auto-purge, opened from Profile, not a tab |

## Document completeness progress bar

A small set of built-in categories are flagged `is_essential` (e.g. government ID, proof of address — exact set TBD, see Open questions). The app tracks how many of those essential categories have at least one non-deleted Document, and surfaces this as a progress bar (e.g. "3 of 5 important documents added") in two places:

- **Home**, directly under the search bar.
- **Profile**, near the top, in both the signed-in and not-signed-in states.

The bar is purely a local aggregation over the existing sqflite tables (same pattern as the Phase 3 document health dashboard) — no network or account required, and it's identical for signed-in and not-signed-in users. It's hidden entirely once every essential category has at least one document; it never blocks any other action. Tapping it surfaces which essential categories are still missing (e.g. a bottom sheet or checklist) and lets the user jump straight into Add a document for one of them, category pre-selected.

## Phase 1 implementation

**Local storage:** sqflite schema mirrors the data model above. All app screens read/write through sqflite via a repository layer; since sqflite has no built-in reactive streams, the state-management layer (Riverpod/Bloc) re-queries and notifies listeners after each write, so category counts, Favorites, and Recent still update immediately without a manual pull-to-refresh.

**Categories:** the 13 built-in categories (and Uncategorized) are seeded into the local database on first launch, each with its preset `field_schema`. Custom categories created via the New Category screen insert a new Category row with a user-defined `field_schema`.

**Document scanning — step by step (Android: `google_mlkit_document_scanner: ^0.6.1`):**

1. Add the dependency to `pubspec.yaml`; run `flutter pub get`.
2. Change `MainActivity` to extend `FlutterFragmentActivity` (required by the plugin's UI flow).
3. Optionally add the ML Kit metadata tags to `AndroidManifest.xml` so Play Services preloads the scanner module.
4. No manual camera permission needed — the scanner UI runs through Google Play Services and handles its own camera access.
5. Configure scanner options before launching: max page count, whether gallery import is allowed, which editing tools (crop/filter) are enabled.
6. Launch the scanner from the "Take Photo" option in the Add Source picker; Google's own UI handles edge detection, auto-capture, multi-page, crop, and filter.
7. Receive the result: scanned pages returned as images and/or a combined PDF.
8. Hand off the returned pages to our own Review screen (thumbnails, reorder, delete) so the rest of the save flow is identical regardless of capture method.
9. Handle edge cases: user cancels mid-scan (return to the calling screen, nothing saved), Play Services module not yet downloaded (brief "preparing scanner" state on first use), unsupported device (fall back to plain camera capture).

**Document scanning (iOS):** `flutter_doc_scanner` (wraps Apple VisionKit) or a direct VisionKit binding, giving an equivalent native scanning UI. Test on real devices before committing, since it's a smaller community-maintained plugin.

**Gallery import path:** "Choose from Gallery" in the Add Source picker uses `image_picker`; selected images go straight into the Review screen alongside any camera-captured pages.

**Save flow:** the Save screen renders form fields dynamically from the selected category's `field_schema` (built-in or custom), plus the always-present title/description/tags/to-do fields. On save, a Document row is inserted with `fields` as JSON matching that schema, Page rows are inserted for each page, and a PDF is generated from the pages (client-side for MVP, using a PDF-generation package).

**Accounts & backup:** entirely optional. Signing in with Google (from the "Set up backup" screen) does two things at once: creates the account (FastAPI issues a JWT) and requests Drive access (`drive.file` scope) in the same consent step. Once granted, documents already on the device are uploaded into a "Mantic Backups" folder created in the user's own Drive; each Document row stores the resulting Drive file ID so future updates overwrite the right file. Document metadata (category, fields, tags, to-dos) stays in our own backend database — Drive only ever holds the raw files. No part of the core app checks for a signed-in user to function.

## Phase 2 implementation

Everything in this phase runs on-device — no account or connectivity required.

**OCR:** after a page is saved, Google ML Kit Text Recognition runs on the image locally and the extracted text is written to `Document.ocr_text`. This is indexed with SQLite's full-text search (FTS5) so keyword search covers document content, not just title/tags.

**Automatic categorization & tagging:** when a new scan comes in, `ocr_text` is checked against a keyword ruleset per category (e.g. "License No.", "Valid Till" → Driving License) before the Save screen opens, pre-selecting the likely category. The user confirms or changes it — the suggestion is never applied silently. This starts as a rules engine and can later be swapped for a small on-device classifier without changing the UI contract.

**Deadline detection:** a regex + date-parsing pass over `ocr_text` looks for date-like patterns near known field labels ("Valid Till," "Due Date") and populates `Document.detected_dates` and the relevant category field automatically. A local notification is scheduled via the OS notification APIs (`flutter_local_notifications`) — no server push needed.

## Phase 3 implementation

These features need a live model call, so they're call-time online, not always-on — the rest of the app is unaffected if there's no connection.

**AI-powered search ("chat with your documents"):**

1. User asks a question in natural language.
2. The app searches locally first — using the FTS index from Phase 2 (and, once computed, local similarity over `Document.embedding`) — to shortlist a small number of likely-relevant documents. This step is instant and fully offline.
3. If online, the app sends only that shortlist's text to the Anthropic API with the question, and gets back a direct answer with a reference to the source document.
4. If offline, the app shows a clear "AI search needs an internet connection" state; everything else keeps working normally.
5. No account or full sync is required for this — it works per-question, using only what's locally shortlisted at that moment.

**Automatic summaries:** triggered once after OCR completes (or on demand from the document viewer); `ocr_text` is sent to the language model with a summarization instruction, and the result is cached on the Document row so it's never regenerated on every view. Requires connectivity only at generation time.

**Similar-document clustering:** reuses the embeddings computed for AI search; a similarity pass (cosine similarity over `Document.embedding`) runs when a new document is added, surfacing a "related documents" section. Can run locally if embeddings are cached, or via the backend if using pgvector for larger libraries.

**Document health dashboard:** purely a local aggregation — pulls `detected_dates` and flagged documents from the existing local database into one prioritized view. No network required.

## Phase 4 implementation

**Shared vaults:** new `Vault` and `VaultMember` tables on the backend; a Document can optionally belong to a vault (`vault_id`). Access checks are extended to also check vault membership and role (view/edit) before allowing a read or write. Invites sent via email or a shareable link.

**Voice-note attachments:** a short recording is captured on-device, uploaded to the same Google Drive backup folder, and transcribed via a speech-to-text service; the transcript is stored on a `VoiceNote` row linked to the document and indexed the same way as OCR text, so it's searchable too.

**Full offline-first sync:** every local change is tracked with a version marker (e.g. an incrementing `updated_at`/version column per row). When connectivity returns, the app pushes changes to a sync endpoint on FastAPI, which compares versions per row; if the same document was changed on two devices since the last sync, the conflict is flagged for the user to resolve rather than silently overwritten.

## Backend API overview

All endpoints under FastAPI, versioned (`/api/v1/...`). Grouped by resource:

- **Auth:** sign up, log in (email + password), Google OAuth callback, token refresh.
- **Categories:** list, create (custom category with `field_schema`), update, delete.
- **Documents:** list/search, get one, create, update, soft delete, restore, permanently delete, favorite toggle.
- **Pages:** upload, reorder, delete, apply filter.
- **Todos:** list per document, create, toggle done, delete.
- **Backup/Sync (Phase 4):** push local changes, pull remote changes, resolve conflict, map Document rows to their Google Drive file IDs.
- **AI (Phase 3):** ask (question + document shortlist → answer), summarize (document → summary), related (document → similar documents).
- **Vaults (Phase 4):** create, invite member, list members, update role, remove member.

Most of Phase 1 can actually run without hitting these at all — the backend only matters once an account exists or an AI feature is called.

## Open questions & assumptions

- **iOS scanning package:** `flutter_doc_scanner` is proposed but is a smaller community plugin — needs real-device testing before committing; a direct VisionKit binding is the fallback if it proves unreliable.
- **PDF generation:** assumed client-side for Phase 1 (simpler, offline); may move server-side later if file sizes or quality become an issue.
- **Vector store choice (Phase 3):** pgvector assumed for simplicity (same Postgres instance) but a dedicated vector DB may be worth it at larger scale.
- **Sync conflict UX (Phase 4):** flagged-for-user-resolution assumed; the actual conflict-resolution screen/flow isn't designed yet.
- **On-device classifier (Phase 2):** starts as keyword rules; whether/when to upgrade to a trained model is a later decision based on how well rules perform in practice.
- **Custom category field types:** currently Text/Date/Number only — whether to add more types (e.g. dropdown/select) is open.
- **Google Drive backup quota:** backups count against the user's own 15GB free Drive quota, not ours — the app should surface a clear message if their Drive is full rather than failing silently.
- **Essential category set (document-completeness progress bar):** which of the 13 built-in categories are flagged `is_essential` isn't decided yet — assumed to be a fixed product-defined subset (not user-configurable) until decided otherwise.
- **Document-completeness "done" definition:** assumed to be "at least one non-deleted Document in the category," regardless of whether its fields (e.g. an expiry date) are filled in or current — whether an expired/incomplete essential document should still count as "done" is open.

This document should be updated as these decisions are made, so it stays the accurate source of truth for implementation.
