# Mantic Document Organizer — Product UX Review

**Date:** 16 October 2026
**Role:** Product owner review, UX-focused
**Audience:** Product, design, engineering
**Scope:** What the app does today, who it serves, and the most valuable next improvements — judged against the product's own stated mission: **organize documents smartly, with ease, on a reliable platform.**
**Method:** Source inspection of the working tree (file paths cited throughout), plus the project's own prior docs (`project_doc.md`, `product_feature_roadmap.md`, `document_readiness.md`). Not device-tested, not based on user research — findings are labeled **code-verified** unless marked **assumption**.
**Rule followed:** nothing below recommends a feature that already exists; where an existing flow could be simplified rather than extended, that's called out explicitly.

---

## What this app is, who it serves

Mantic is an offline-first document scanner/organizer: capture or import a document, let OCR and an AI pass suggest its category/title/expiry, store it locally in SQLite, then retrieve it by browsing categories, searching, or favorites. A backend exists only for two opt-in things — Google Drive-backed backup and AI feature calls — and is never supposed to gate core use. The stated audience hypothesis (per `product_feature_roadmap.md`) is individuals managing personal/household documents; that's not yet validated against real users.

**Already implemented — not recommended again here:** camera/gallery capture, category-aware save flow, on-device OCR, AI-assisted category/title/expiry suggestion at save time, manual bulk import with AI grouping, drafts (SQLite-backed autosave/resume/discard), built-in and custom categories, favorites, trash (restore/purge), content search with filters, expiry reminders with configurable lead time and snooze, category/space sharing with invites and roles, document-level export/share (whole PDF, selected pages, images), Google Drive backup with sync-progress UI, an AI chat assistant over the document library, and settings for theme/language/biometric lock/mobile-data/reminder timing.

---

## Recommendations

### R1 — Remove the mandatory sign-in gate at first launch

**User problem:** A new user installs the app expecting to use it immediately — the entire value proposition is offline-first, no-account document capture — but is blocked by a signup form before they can touch the camera.

**Use case:** Someone wants to photograph a parking ticket before it's lost. They open the app for the first time and hit a mandatory account-creation screen instead of a camera button, with no way to skip it, and bounce.

**Proposed experience:** Splash resolves to Home for every user, onboarded or not. Account creation only happens from "Set up backup" in Profile, matching the spec's own description of the flow.

**Current coverage:** Regression, not a gap — **code-verified**. `lib/features/splash/viewmodel/splash_viewmodel.dart` routes a non-logged-in user to `Signin`, not `Home`, after onboarding (the code's own comment states *"Signup/login is mandatory past onboarding"*). The signin screen has no guest/skip path. This contradicts both `CLAUDE.md` ("No part of the core app should ever gate on a signed-in user") and the technical spec.

**Priority and effort:** Highest-value fix on this list — it blocks every other improvement for every new user. Low-to-medium effort: it's a routing change (drop the `signin` branch in `resolveNextRoute()`), not new feature work.

**MVP scope:** Splash always resolves to `onboarding` or `home`; nothing else changes.

---

### R2 — Re-enable the Document Readiness card

**User problem:** Users have no visibility into which important records (ID, proof of address, birth record, health, financial) they haven't captured yet, and only discover the gap when they urgently need one.

**Use case:** Someone has scanned a few receipts and a utility bill but has no signal that they've never saved a copy of their passport until they need it at a border desk.

**Proposed experience:** A progress card on Home (circular score, five essential-record groups); tapping it shows saved/missing status per group with an "Add document" action that pre-selects the right category. Exactly as already specced in `document_readiness.md`.

**Current coverage:** **Fully implemented, just hidden** — code-verified. `lib/features/home/view/home_view.dart:104` has `// const DocumentReadinessCard(),` commented out. The feature itself (scoring policy, persistence, capture linking, tests) is complete per its own doc.

**Priority and effort:** High value, near-zero effort — this is a flag flip plus a visual QA pass (large text, RTL, dark mode — already listed in the feature's own doc), not a build.

**MVP scope:** Already done; uncomment and ship.

---

### R3 — Make reminder snooze durable

**User problem:** A user snoozes an expiry reminder, believes it's handled, and the app silently un-snoozes it the next time the document is touched — with no warning.

**Use case:** A user snoozes a passport-renewal reminder for two weeks, then edits the document's description a few days later; the reminder fires early anyway, with no indication anything changed.

**Proposed experience:** Persist "snoozed until" per document. When reminders are reconciled after an edit, an unexpired snooze is respected instead of silently overwritten; it clears only when it expires or the user explicitly changes it.

**Current coverage:** Partially implemented — **code-verified**. `lib/core/notifications/expiry_notification_service.dart` reschedules only the OS-level notification; there's no persisted snooze state, confirmed by the service's own comment explaining why it doesn't track one. This is the same gap `product_feature_roadmap.md` (F3) flags as outstanding, now confirmed as an active silent-failure rather than a theoretical one.

**Priority and effort:** Medium value, medium effort.

**MVP scope:** Add a persisted `snoozedUntil` field read by the reminder-reconciliation pass; renewal/replacement linking (the rest of F3) can follow later.

---

### R4 — Persist the auto-discovery review inbox

**User problem:** Documents the app discovers automatically (gallery/filesystem scan) can only be reviewed in one sitting — an interruption loses the batch, and this is the stated reason the feature stays switched off entirely.

**Use case:** The app finds 12 possible documents; the user reviews 3, takes a phone call, and closes the app. Today, reopening it loses the remaining 9 candidates and their edits.

**Proposed experience:** Persist the scan session and every candidate's state/edits to SQLite. Home/Profile show a durable review count that survives a restart or crash; dismissing a candidate never deletes the source file.

**Current coverage:** Feature is fully built except for this gap — **code-verified**. `lib/core/background/auto_import_service.dart` keeps pending review on an in-memory field only; `AppConstants.autoImportEnabled = false` exists specifically because of this. Matches `product_feature_roadmap.md` F4.

**Priority and effort:** Medium-to-large effort, but it's the single blocker between "built" and "shippable" for an entire feature that's currently dead code in production.

**MVP scope:** As specified in F4 — durable session + candidates, a review queue independent of the notification that triggered it, safe retry/dismiss without deleting originals.

---

### R5 — Warn on duplicate imports

**User problem:** The same receipt or statement gets imported twice (re-shared from email, re-scanned by habit), and nothing tells the user — the library quietly accumulates clutter that undermines "organized."

**Use case:** A bank statement PDF is shared into the app from an email client, then imported again months later from a downloads folder.

**Proposed experience:** Compare exact file content via a local fingerprint at import time; if a match exists, offer "Open existing / Skip / Keep both" before the candidate is saved. Never auto-delete a suspected duplicate.

**Current coverage:** **Missing entirely** — code-verified by exhaustive search; no fingerprint/hash/duplicate-check code exists anywhere in the import or save path. Matches `product_feature_roadmap.md` F6.

**Priority and effort:** Medium value, medium effort — best sequenced after R4, since F6 explicitly depends on the review-inbox work for its UI integration.

**MVP scope:** Exact-byte-match detection only (no fuzzy/OCR matching), surfaced at the existing confirmation step.

---

### R6 — Per-document backup status and an explicit restore flow

**User problem:** A document that saved successfully on-device can be mistaken for one that's actually protected if the phone is lost — there's no way to check which specific documents are safe, and no labeled "recover my documents" action after reinstalling.

**Use case:** A phone is lost; the user reinstalls on a new device and wants a clear "Recover my documents" action, not a generic Sync button they have to trust is doing the right thing.

**Proposed experience:** Per-document/revision states (local-only / waiting / syncing / backed-up / failed-with-reason), plus a guided recovery flow that's distinct from ongoing sync.

**Current coverage:** Partially implemented — **code-verified**. `lib/features/backup/presentation/backup_setup_page.dart` and `document_sync_service.dart` show connection status and an aggregate, space-level `SyncProgress` (preparing/categories/documents/completed/failed) with retry, but no per-document indicator and no dedicated restore action — restore happens implicitly inside the generic sync pull. Matches `product_feature_roadmap.md` F5.

**Priority and effort:** Medium-to-large effort, high trust value.

**MVP scope:** Per the acceptance criteria already written in F5 — don't re-derive; it's well-specified there.

---

### R7 — Tell the user when the AI assistant is failing because they're offline

**User problem:** A generic error message after an AI assistant question doesn't distinguish "you're offline" from "the server is broken," undermining trust in an otherwise-reliable offline-first app.

**Use case:** On a flight or with no signal, a user asks the assistant "when does my passport expire" and gets "something went wrong" instead of the offline-specific message the spec calls for.

**Proposed experience:** Check connectivity before attempting the call (the app already has this primitive elsewhere) and show the spec's own "AI search needs an internet connection" state; reserve the generic error for genuine server failures.

**Current coverage:** Missing this one distinction — **code-verified**. `lib/core/ai/ai_chat_service.dart` deliberately collapses offline/missing-API-key/server-error into one message (its own comment: *"all indistinguishable by design"*), while `dio_helper.dart` already has a cached connectivity check used elsewhere in the app (the mobile-data sync gate). **Separately flagged, assumption-level:** the assistant calls Groq's API directly rather than Anthropic's, which the spec names — may be a deliberate pivot, not necessarily a problem, but worth a product decision either way.

**Priority and effort:** Low effort (reuse an existing primitive), medium value.

**MVP scope:** One pre-flight connectivity check, one new user-facing string.

---

### R8 — Accessibility and RTL audit

**User problem:** Icon-only controls and custom widgets likely have no screen-reader labels, and RTL layout correctness is unverified — despite Arabic being a real, selectable language today, not a hypothetical future one.

**Use case:** A screen-reader user can't identify the unlabeled camera "+" button; an Arabic-language user encounters a filter row or custom widget that doesn't mirror correctly.

**Proposed experience:** Add `Semantics`/`semanticLabel` to icon-only interactive elements; do a dedicated RTL visual pass on custom (non-default-Material) widgets; verify large text sizes don't clip key UI.

**Current coverage:** Largely missing — **code-verified** that explicit `Semantics(...)` appears in only two non-generated files app-wide, and no explicit RTL-aware layout checks or `TextScaler` handling were found outside framework defaults. **Assumption:** this is flagged as risk, not a confirmed visual bug — no device/screen-reader testing has been done.

**Priority and effort:** Medium effort, moderate-to-high value given RTL is an advertised capability already shipped in Settings, not aspirational.

**MVP scope:** Start with the highest-traffic screens (Home, Add Document, Document Viewer) rather than a full-app pass.

---

### R9 — Collections and redacted sharing (deferred, not re-specified)

Both are already fully specified in `product_feature_roadmap.md` (F7, F8) with MVP scope and acceptance criteria, and the groundwork they depend on already exists (document references, category model, selective page export via `document_processing_repository_impl.dart`). No reason to rebuild those specs here — they're correctly sequenced last: collections behind audience validation (is personal/household the right focus, or does this app need to serve shared/task-based use?), redacted sharing behind dedicated export-verification work.

---

## Flagged inconsistencies (for a product decision, not a build)

- **Sign-in requirement** (R1) contradicts the written no-account promise — needs an explicit decision, not just a code fix, since something upstream of the splash logic decided to require it.
- **Category/space sharing already ships** what the spec calls a Phase 4 "shared vaults" concept, well ahead of the phase sequencing in `project_doc.md` — confirm this was intentional.
- **AI provider**: the assistant calls Groq, not Anthropic as named in the spec — confirm whether this was a deliberate pivot.
- **Deadline detection** is produced by an online AI call at save time, not the offline on-device regex pass the spec describes for Phase 2 — functionally fine, but means this capability currently requires connectivity to work at all.

---

## Prioritized roadmap

Ranked against the stated mission — organize smartly, with ease, reliably — not against raw activation-funnel math alone:

| Rank | Item | Mission fit | Priority / Effort |
|---|---|---|---|
| 1 | R2 — Re-enable Document Readiness | Directly: shows what's organized vs. missing | High value / near-zero effort |
| 2 | R5 — Duplicate detection | Directly: a cluttered library isn't organized | Medium value / medium effort |
| 3 | R4 — Persistent review inbox | Directly: unlocks a fully-built discovery feature currently dead in production | High value / medium–large effort |
| 4 | R3 — Durable snooze | Reliability: fixes a live silent-failure bug | Medium value / medium effort |
| 5 | R6 — Per-document backup status + restore | Reliability: trust in "is my library safe" | High value / medium–large effort |
| 6 | R7 — AI offline messaging | Reliability: removes a confusing failure mode | Medium value / low effort |
| — | R1 — Remove sign-in gate | Precondition — nothing above matters to a user blocked at the door | Highest value / low–medium effort |
| — | R8 — Accessibility/RTL audit | Who can use the experience, not the experience itself | Medium value / medium effort |
| Later | R9 — Collections, redacted sharing | Already specified; gated on validation work | Large effort |

### The three to build next

1. **Remove the mandatory sign-in gate (R1).** Every other improvement on this list is wasted on a user who never gets past signup — it's the cheapest fix here and the only one actively working against the app's own stated mission.
2. **Re-enable Document Readiness (R2).** It's fully built and directly serves "organize smartly, with ease" — essentially a free win that should ship alongside #1, not after it.
3. **Persist the auto-discovery review inbox (R4).** It's the one piece of debt standing between "a whole feature exists in code" and "that feature can be turned on" — highest leverage per unit of effort after the two near-zero-cost fixes above.

---

## Maintenance

Update this document's statuses as items move from Missing → Built → Enabled. Keep `product_feature_roadmap.md` as the source of detailed acceptance criteria for F3–F8; this document tracks priority and current reality, not spec detail.
