# Dockitly — Product Feature Roadmap

**Updated:** 14 October 2026  
**Status:** Proposed product roadmap; not a release commitment  
**Scope:** Seven remaining user-experience improvements; implemented search and reminder controls removed from planned scope  
**Audience:** Product, design, engineering, and QA

## 1. Product objective

Help people save documents quickly, find the right document when needed, and act before important deadlines. Prioritize reliable completion of these tasks over adding more screens or increasing daily app usage.

The initial audience hypothesis is individuals managing personal and household documents. Validate that assumption before investing heavily in family collaboration or business workflows.

This roadmap supplements the [technical implementation spec](project_doc.md) and [architecture guide](clean_architecture.md). It distinguishes current code from proposed behavior. It does not override repository architecture rules or authorize implementation of every proposal.

### Product principles

- Core capture, organization, retrieval, and review should work locally.
- AI suggestions should be optional, editable, and clearly distinguished from verified facts.
- Interruptions should not discard saved progress or produce duplicate documents.
- Show what happened, what remains, and what the user can do next.
- Never silently discard originals, approve discovered files, or delete suspected duplicates.
- Reuse existing flows and components before introducing another navigation destination.

### Evidence and limitations

Current-state notes come from source inspection, not device testing or customer research. “Implemented” means code exists; it does not establish production readiness. Priorities and effort sizes are product estimates, to be validated during implementation planning.

## 2. Priority overview

The IDs preserve the order of the original recommendations, so F1 is intentionally absent. The working-tree review confirmed that search excerpts, relevance ranking, and date/file-type/expiry filters are implemented (`e1ac411`, with filter UI refinement in `d862afe`). Configurable reminder timing and snooze are also implemented (`ba71da6`), along with the Expiring Soon entry points (`95cee02`). Those capabilities are no longer planned work here. F3 now covers only renewal tracking and reminder recovery.

This review includes the current working tree, not only committed code. It does not certify device behavior or a released build.

| ID | Feature | Current foundation | Remaining priority | Relative effort |
| --- | --- | --- | --- | --- |
| F2 | Save now, organize later | Capture, OCR, editable suggestions, and save flow exist | Next release | Medium |
| F3 | Renewal tracking and reminder recovery | Reminder controls and expiry previews already implemented | Add replacement links and durable snooze behavior | Medium |
| F4 | Persistent review inbox | Discovery and review flow exist; discovery is feature-disabled | Required before enabling discovery | Medium–large |
| F5 | Clear backup and recovery status | Backup/sync, pending counts, and progress UI exist | Next release | Medium–large |
| F6 | Duplicate suggestions | Import pipeline provides a place to check candidates | After durable capture/review | Medium |
| F7 | Collections for real tasks | Categories, document references, and export provide foundations | After audience validation | Medium–large |
| F8 | Redacted sharing | Existing sharing/export pipeline | Later, with dedicated export verification | Large |

Sizes express relative complexity, not dates or staffing commitments.

## 3. Feature specifications

### F3. Renewal tracking and reminder recovery

**User problem:** An expiry reminder tells someone about a problem but does not help them record that it has been resolved.

**Remaining gap:** There is no renewal/replacement relationship in the current document model. Existing snooze scheduling can be replaced when reminders are reconciled, so durable snooze state remains follow-up work. Extend [ExpiryNotificationService](../lib/core/notifications/expiry_notification_service.dart); do not rebuild reminder settings, the snooze action, or expiry previews.

**User story:** As someone renewing a document, I want to connect the replacement and stop obsolete reminders while keeping the old record.

**Experience:** Open an expiring insurance policy, choose “Mark renewed,” then select an existing replacement or capture a new one. Confirm the relationship. Retain the original as history and schedule reminders for the replacement's confirmed expiry.

**MVP scope:**

- Link a renewed document to its replacement.
- Show the previous and current versions clearly.
- Stop obsolete renewal reminders after confirmation.
- Persist snooze intent and preserve it across app restart and reminder reconciliation, until it is due or explicitly changed.

**Acceptance criteria:**

- Renewal never deletes the old document or changes its recorded expiry to an invented date.
- Canceling the renewal flow leaves the original unchanged.
- A confirmed replacement can be opened from the old record.
- Users can correct an accidental renewal link and restore appropriate reminders.
- Restarting the app or reconciling reminders preserves an unexpired snooze; renewal clears obsolete reminders and snoozes.
- Payment due dates remain distinct from expiry dates.

**Dependencies:** Renewal relationship/status in the local model, reminder reconciliation, and sync behavior for the new metadata.

**Later / excluded:** General task management, recurring bill payment, and automatic claims that a document is legally valid.

**Success signal:** More reminders lead to a recorded resolution; fewer obsolete reminders remain after renewal.

### F4. Persistent review inbox

**Plain-language meaning:** A permanent place inside the app for documents discovered automatically but not yet approved by the user. “Persistent” means the list and review progress survive closing the app or restarting the phone.

**Example:** The app finds 12 possible documents in the gallery. The user reviews three, gets a phone call, and closes the app. Tomorrow, Home says “9 documents ready to review.” Tapping it resumes the remaining items with previous edits preserved. Dismissing the discovery notification does not remove this list.

**Current state:** [AutoImportService](../lib/core/background/auto_import_service.dart) holds pending review through an in-memory ViewModel and uses notifications as an entry point. It records the initial-attempt flag before scanning completes. Discovery is currently disabled through [AppConstants](../lib/core/constants/app_constants.dart). The scan runs while the app is active; it is not a guaranteed OS background job.

**User story:** As someone who cannot review discovered files immediately, I want to return later without rescanning or losing decisions.

**MVP flow:**

1. User explicitly starts or consents to discovery.
2. The app persists a scan session and discovered candidates.
3. Home shows a review count; Profile provides a durable entry point too.
4. User previews candidates, edits suggestions, and approves or dismisses them.
5. Approved items become documents; unreviewed items remain available.
6. Reopening the app restores the inbox and offers recovery for interrupted scans.

**MVP scope:**

- Durable scan session, candidate metadata, staged attachments, edits, and decisions.
- A review queue accessible without a notification.
- Clear states for scanning, interrupted, awaiting review, importing, and failed items.
- Retry failed items and dismiss candidates without deleting source files.
- Keep existing confirmation-before-import behavior.

**Acceptance criteria:**

- Force-closing during review preserves previously persisted candidates and edits.
- Force-closing during import does not create duplicates when resumed.
- Denying notifications does not make the inbox inaccessible.
- Starting another scan does not replace unreviewed results from an earlier scan.
- Missing attachments or revoked permissions produce an actionable item state.
- Only confirmed candidates appear in the normal document library.
- Dismissing a candidate never deletes the user's original file.
- No-pending-items state removes the Home count; completion counts reflect committed imports.

**Dependencies:** Local session/candidate persistence, stable candidate identity, durable staging files, safe cleanup, and transactional import completion. Persist IDs and data rather than relying on a live ViewModel for navigation.

**Relationship to F2:** A capture draft is user-started unfinished work. An inbox candidate is automatically discovered material awaiting consent. They may share storage infrastructure, but their states and user-facing labels must remain distinct.

**Later / excluded:** Guaranteed scanning while the app is terminated, automatic approval, and cross-device review queues. Decide retention and cleanup rules before release; do not silently expire unreviewed work.

**Success signal:** Users return to pending reviews successfully, with no lost confirmed work or duplicate imports during interruption tests.

### F5. Clear backup and recovery status

**User problem:** A successful local save can be mistaken for a successful backup. A progress indicator alone does not prove that a document can be recovered on another device.

**User story:** As a document owner, I want to know which files are protected and how to recover them after losing my phone.

**Current state:** Backup/sync, pending-document counts, and progress/error UI already exist. Extend [backup setup](../lib/features/backup/presentation/backup_setup_page.dart) and the [sync service](../lib/features/backup/data/services/document_sync_service.dart).

**MVP scope:**

- Clear local-only, waiting, syncing, backed-up, and failed states.
- Last successful backup information and document-level retry explanations.
- A guided recovery flow that distinguishes retrieving metadata from downloading usable files.
- Explanations for offline, authentication, permission, or quota-related failures where the backend provides that distinction.

**Acceptance criteria:**

- “Backed up” means the required metadata and attachments for that document revision have completed successfully.
- Pending or failed backup does not block opening the usable local document.
- Retry is safe and does not create duplicate documents or attachments.
- A representative restored document opens on a clean installation with its expected metadata and files.
- Partial recovery shows what remains and can resume after interruption.
- Users understand that deletion propagated by sync is different from a historical recovery backup.

**Dependencies:** Reliable per-document/revision status, backend error mapping, account/Drive access, and clean-device restore verification. Confirm actual server guarantees before choosing wording.

**Later / excluded:** Historical version recovery unless the storage system actually preserves versions; blanket “everything is safe” claims.

**Success signal:** Successful clean-device recovery and users correctly identifying which documents are local-only or still pending.

### F6. Duplicate suggestions

**User problem:** The same receipt or PDF is imported repeatedly, making search and organization harder.

**User story:** As someone importing files, I want a warning when an identical file is already saved, with control over what to keep.

**MVP scope:** Compare exact file content using a local fingerprint and show the existing match before confirmation. Offer Open existing, Skip this candidate, and Keep both. Explain partial overlap for multi-attachment documents without treating the whole document as identical.

**Acceptance criteria:**

- Identical bytes can match even when filenames differ.
- Different contents with the same filename are not marked as exact duplicates.
- No suspected duplicate is deleted automatically.
- Keeping both remains possible and retrying import does not accidentally repeat that choice.
- Trashed-document matches are labeled clearly and do not silently restore anything.

**Dependencies:** Local fingerprint storage, stable attachment identity, F4 review integration, and a policy for trashed matches.

**Later / excluded:** Similar-photo detection, fuzzy OCR matching, and automatic merging.

**Success signal:** Fewer unwanted duplicate imports, with no false exact-match removals.

### F7. Collections for real tasks

**User problem:** One task can require documents from multiple categories. Moving each file into a new category breaks its original organization.

**User story:** As someone preparing a visa application, I want my passport, bank statement, and employment letter together without duplicating them.

**MVP scope:** Named collections referencing existing documents, an optional checklist of needed items, and ordered batch export. A document can belong to several collections while retaining its category.

**Acceptance criteria:**

- Adding to a collection does not copy attachments or change category.
- Removing a collection does not delete its documents.
- Missing or trashed documents are clearly indicated and not silently exported.
- Export lets the user review order and selected items first.
- Membership alone grants no additional sharing access.

**Dependencies:** Collection and membership model, export flow, and rules for references to shared-space documents.

**Later / excluded:** Public templates, collaboration on collections, and asserting that a checklist meets official application requirements.

**Success signal:** Users assemble and export a task-specific set with fewer searches and no unnecessary file duplication.

### F8. Redacted sharing

**User problem:** A document may need to be shared while hiding an address, account number, or other private detail.

**User story:** As someone sharing a document, I want a separate copy with selected information permanently removed while preserving my original.

**MVP scope:** Manual selection of areas to redact on supported images/PDF pages, export preview, and sharing of a separate sanitized output. State supported formats explicitly.

**Acceptance criteria:**

- Original attachments remain unchanged.
- Redacted information cannot be recovered from exported text layers, metadata, annotations, embedded originals, or thumbnails.
- The final exported file is the same artifact reviewed before sharing.
- Multi-page outputs preserve page order and apply all confirmed redactions.
- Unsupported formats or failed sanitization block export with an explanation.
- Verification includes attempting text extraction from the actual exported PDF; drawing a black rectangle over visible content is insufficient.

**Dependencies:** A deliberate sanitization/export approach and dedicated artifact inspection. Reuse the share flow only after the output has passed verification.

**Later / excluded:** AI-only detection of sensitive data and editable/reversible redactions in shared output.

**Success signal:** Users produce the intended shareable copy and export checks find no recoverable redacted content.

## 4. Delivery sequence and release gates

| Stage | Deliverables | Exit criteria |
| --- | --- | --- |
| A — Complete everyday flows | Deliver F2 and F5 improvements | Existing offline retrieval stays functional; draft interruption recovery and clean-device restore are demonstrated |
| B — Close the loop | Deliver F3 renewal/recovery work and F4 before enabling discovery | Renewal actions reconcile reminders; review/import survives interruption without loss or duplication |
| C — Reduce library friction | F6, then a small F7 pilot | Exact duplicate decisions are safe; users confirm collections solve a recurring task |
| D — Safer document sharing | F8 | Actual exported artifacts pass sanitization and usability checks |

Do not enable automatic discovery solely because its scan works. Its review persistence and recovery are release requirements.

For Home, favor a small conditional “Needs attention” area for pending review, organization, and backup failures. Keep search prominent and retain access to existing Expiring Soon content. Avoid adding a new bottom tab for each improvement.

### Separate search follow-up

The completed search feature does not imply complete PDF indexing: [OcrService](../lib/core/ocr/ocr_service.dart) still processes at most five PDF pages. Coverage indicators, processing remaining pages, and page-level navigation are potential later enhancements, not reasons to keep the original search feature on the active backlog. Scope them separately if prioritized.

## 5. Cross-feature implementation requirements

- Follow Provider, GetIt, repositories, use cases, and the project's Result-based error conventions.
- Use SQLite for new durable local state; plan migrations that preserve existing libraries.
- Reuse localization, theme colors, date utilities, and shared widgets.
- Verify long titles, larger text, dark/light themes, and RTL layouts.
- Keep source files separate from app-owned drafts, staging copies, exports, and saved attachments.
- Define retry and recovery behavior before adding background work.
- Do not imply local biometric locking proves file encryption or cloud confidentiality.
- Preserve manual local workflows when AI or sync is unavailable.

### Decisions to resolve

| Decision | Recommended direction | Why it matters |
| --- | --- | --- |
| Account requirement | Reconcile mandatory sign-in in current startup with the spec's optional-account promise | Changes first-use and offline acceptance criteria |
| AI data scope | Explain online processing and send only relevant material | Sets accurate privacy and connectivity expectations |
| Draft/inbox retention | Explicit policy with visible cleanup controls | Avoids lost work and unbounded storage growth |
| Backup versus sync | Document retention and deletion semantics before promising recovery | Prevents misleading status labels |
| Renewal history | Keep original records and link replacements | Preserves evidence and avoids false expiry changes |
| Primary audience | Validate personal/household versus business needs | Determines whether collections or collaboration deserves more investment |

## 6. Validation and measurement

Start with five representative users completing realistic tasks using sample documents: capture a receipt, retrieve an older file, return to an interrupted review, respond to an expiry, and explain backup status. Include at least one larger-text and one RTL session where relevant to the audience.

Record task completion, elapsed time, errors, unnecessary steps, and confidence. Treat these as research observations rather than statistically conclusive results. Establish a baseline before setting numerical improvement targets.

If product analytics are later introduced, use opt-in aggregate interaction events. Do not collect document contents, OCR, titles, filenames, search queries, or personal identifiers as measurement payloads.

**Primary outcome:** Users reliably retrieve and use the document they need. Daily engagement alone is not an appropriate success measure for an occasional-use document organizer.

## 7. Maintenance

Remove completed scope from the active backlog as implementation changes; narrow partially completed features to their remaining work. Keep a short evidence note with commit or source references rather than retaining completed feature specifications. Record device-validation evidence separately and distinguish implemented code from released behavior. Keep the original recommendation IDs stable so discussions and future tasks remain traceable.
