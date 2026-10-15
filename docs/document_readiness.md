# Document readiness

Implemented on Home as a circular progress card with an editable checklist sheet.

## Checklist and scoring

Five fixed groups: Identity, Proof of address, Birth record, Health records, and Financial records. Users do not build the checklist. Each applicable group contributes one point, regardless of how many matching documents exist. “Not applicable” removes a group from the denominator and can be undone. If all groups are excluded, the card displays a neutral state instead of 100%.

Only active saved documents with attachments count. Drafts and Trash do not. Progress measures records saved in the app, not legal validity, expiry, physical file verification, or successful backup. Expired documents still count as stored records; existing expiry UI handles renewal needs separately.

Identity can match the specific ID/passport/driving-license categories. Other groups use conservative exact document title/tag labels in the supported languages, not a broad category or incidental OCR mention. Users can explicitly link a saved document when recognition misses a record. A linked document remains associated when renamed or moved. Trashing it removes its contribution; restoring it restores progress. A deleted link can be replaced through “Use a saved document.”

## User flow

Tap the Home card to see examples, saved/missing status, and actions for each group. “Add document” opens the existing capture form with a suitable category and links the returned saved document. If no suitable writable category exists (including Birth record), a local category is created on demand. Canceling capture does not mark the group complete; an unfinished draft can later be linked after it is saved.

“Use a saved document” opens a searchable selector. Completed items offer a direct link to the source document and a change action. Driving licence, insurance, education, marriage, property, and employment records appear as optional suggestions and add no separate points.

## Implementation

- Home domain: fixed group definitions, immutable preferences, and score evaluation.
- Repository: versioned local preference JSON using existing secure storage and Result-based error handling.
- ViewModel: Provider/UseCaseExecutor; observes document and category repositories.
- Capture: returns its successfully saved document to the calling route; ordinary capture callers may ignore the result.
- Chart: Flutter CircularProgressIndicator, with semantic progress text and theme-aware colors. No extra chart dependency.
- Preferences are device-local, not synchronized. Storage errors retain the previous state and provide retry/error feedback.

## Verification

Policy tests cover fixed groups, alternative IDs, unrelated files, multilingual labels, empty attachments, exclusions, and trash/restore. Persistence tests cover restart recovery, all-excluded state, unavailable links, and malformed stored preferences. Device QA should cover capture return, draft cancellation, larger text, RTL, dark mode, and offline use.
