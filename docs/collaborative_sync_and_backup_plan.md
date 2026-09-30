# Collaborative sharing, backup, and offline sync plan

## Purpose

This plan adds optional account backup and collaborative document spaces without changing the product's primary promise: documents remain usable when the device is offline.

The current app already has the right first building blocks. SQLite is the local source of truth, document and category IDs are client-generated, attachments are copied to device storage, and category/document repositories are isolated behind domain contracts. Authentication screens and HTTP scaffolding exist, but they are not connected to a production identity service or a sync protocol.

The implementation must preserve this rule throughout the work:

> Every create, edit, scan, delete, favorite, search, and view action completes against local SQLite first. Network work is queued and never blocks the screen or prevents a local change.

## Product model

### Use the name “shared space” in the product

A direct category ACL works for a small demo, but it becomes difficult to manage once a category has multiple people, invitations, roles, activity, and future subcategories. The professional model is a **shared space**.

For the user's example, they create a shared space named **Family**. It appears in the same category list users already understand, with a people badge and a sync state. Everyone invited to Family can see the same documents and, according to their role, add or edit them.

The initial version intentionally keeps the model shallow:

```text
Account
├── Personal area
│   ├── Bank
│   ├── Medical
│   └── other private categories
└── Shared spaces
    └── Family
        └── documents and attachments
```

Do not add nested folders, public links, external guests, comments, or live co-editing in the first release. Those are useful later, but they increase permissions, conflict handling, and support burden.

### Roles and permissions

| Role | Can view/download | Can upload/edit documents | Can invite/remove members | Can delete space |
| --- | --- | --- | --- | --- |
| Owner | Yes | Yes | Yes | Yes, after transfer or confirmation |
| Editor | Yes | Yes | No | No |
| Viewer | Yes | No | No | No |

Owners can change a member between editor and viewer, revoke access immediately, and transfer ownership. An invitation expires after seven days and can only be accepted by the invited email address. The server always enforces this table; hiding a button in Flutter is not authorization.

### User-visible behavior

- A private category has a **Share** action. Choosing it creates a Family-like shared space, asks the owner to confirm, and shows an invitation form.
- The owner enters an email and chooses Editor or Viewer. The server sends an invitation email with an accept link. For a first release, the invited person may also accept from the in-app Invitations screen after signing in with that email.
- Members see the shared space after the next successful sync. The owner sees member count and the latest activity.
- An editor can add a document while offline. The document is marked **Waiting to upload** and is visible to that editor immediately. Other members receive it after upload and sync.
- A viewer can open already-downloaded files offline. Files that have not been downloaded show **Available online** and download only when requested or when automatic download is enabled.
- A member who loses access retains no new server access. On the next sync, the app removes the shared space's local metadata and files after a clear notice. Personal documents are never affected.

## Account and backup flow

Accounts are optional. A new installation opens and works as it does today, without a sign-in requirement.

1. Settings or Profile shows **Set up backup** with a short benefit statement: “Keep your documents safe and sync them across your devices.”
2. Tapping it opens the existing sign-in screen. It has Email and password, **Continue with Google**, **Continue with Apple** on iOS, and a link to Sign up.
3. Sign up asks only for name, email, and password. Verify the email before enabling account recovery and outgoing invitations. Google and Apple accounts create or attach an account after the backend verifies their identity token.
4. After authentication, show a one-time **Back up this device** screen. It explains that local documents will upload in the background, shows the document/file count, and offers **Start backup**. Do not ask the user to choose a destructive “cloud wins” option when the account has no remote data.
5. The app returns immediately to the normal home screen. A compact sync indicator reports “Backing up”, “Up to date”, “Waiting for Wi-Fi”, or “Needs attention”. The user can continue scanning, browsing, or editing throughout.
6. When an existing account already has cloud data, show a dedicated **Merge this device** screen. The safe default is merge by stable ID, followed by the normal conflict policy. Never replace local data silently.

Sign-out stops network synchronization and removes access/refresh tokens from secure storage. It does not delete local personal data. Before removing locally cached shared-space content, show an explicit choice: keep an offline read-only copy until the user deletes it, or remove it now. The default should be remove shared files because their access was account-derived.

## Flutter architecture changes

The existing clean architecture direction remains unchanged: presentation → domain ← data. Network and background scheduling belong in data/core adapters, never in view models or widgets.

### New feature boundaries

```text
features/
  account/
    domain/       Account, AuthSession, AuthRepository, auth use cases
    data/         FastAPI auth client, token store implementation
    presentation/ setup-backup, sign-in, sign-up, account settings
  collaboration/
    domain/       SharedSpace, Membership, Invitation, role use cases
    data/         remote client and SQLite mappings
    presentation/ space settings, members, invitations, activity
  sync/
    domain/       SyncRepository, SyncStatus, Sync use cases
    data/         outbox, change-feed client, attachment uploader, scheduler
    presentation/ sync status indicator and sync details page
```

`DocumentItem` and `CategoryItem` should gain domain-safe ownership information, such as `scope` (`personal` or `shared`) and nullable `spaceId`. They must not acquire HTTP fields, JSON annotations, database rows, or UI state. Transport DTOs and SQLite rows map to these values inside data.

The current `IDocumentRepository` and `ICategoryRepository` should remain the app-facing contracts. Their implementations become local-first coordinators:

1. persist the new value and its sync mutation in **one SQLite transaction**;
2. update the in-memory repository cache and notify the UI;
3. wake the sync scheduler without awaiting network completion.

This means the current UI can keep awaiting a save for local durability, while it never waits for the network.

### Local database migration

Bump `AppDatabase` with an explicit, tested migration. Add the following tables/columns; do not overload the current attachment paths with remote URLs.

| Local data | Key fields | Purpose |
| --- | --- | --- |
| `spaces` | `id`, `name`, `scope`, `owner_id`, `role`, `remote_revision`, `deleted_at` | Personal or shared ownership boundary displayed as a category/space. |
| `categories` additions | `space_id`, `remote_revision`, `updated_at`, `sync_state`, `deleted_at` | Makes existing categories syncable. |
| `documents` additions | `space_id`, `remote_revision`, `updated_at`, `updated_by`, `sync_state`, `deleted_at` | Records server version and local pending state. |
| `document_attachments` additions | `id`, `content_hash`, `byte_size`, `mime_type`, `remote_object_key`, `upload_state` | Separates a durable attachment identity from a device path. |
| `sync_outbox` | `operation_id`, `entity_type`, `entity_id`, `operation`, `base_revision`, `payload_json`, `created_at`, `attempt_count`, `next_attempt_at` | Durable, ordered work for the server. |
| `sync_cursor` | `account_id`, `cursor`, `last_success_at` | Resumes incremental download after app restart. |
| `conflicts` | `entity_id`, `local_snapshot`, `remote_snapshot`, `reason`, `created_at`, `resolved_at` | Lets the user resolve rare unsafe conflicts. |

Existing local categories initially belong to a personal space. To share an existing Family category, create its server space, assign that `space_id` to its category/documents in a transaction, and enqueue the corresponding creates. The original local IDs remain stable; do not regenerate them during backup.

### Sync algorithm

The sync engine runs when the app starts, returns to foreground, network becomes available, the user pulls to refresh, or a local mutation is written. A platform background job is a best-effort extra, never the only way data reaches the server.

```text
Local user action
  → SQLite entity update + outbox row (atomic)
  → UI updates immediately
  → scheduler wakes when online
  → upload attachments, then submit idempotent mutations
  → download server changes after saved cursor
  → apply changes in local transactions
  → repository refreshes affected in-memory values
```

Each outbox mutation has a client-generated UUID idempotency key. Retrying a timed-out request is safe because the backend stores the key and returns the original result rather than writing a second document. Retries use exponential backoff with jitter; authentication errors pause work and display a sign-in action.

Attachments upload before the document mutation that references them. The client computes SHA-256 while copying the local file, requests a short-lived upload URL, uploads directly to object storage, confirms the object with the API, and then sends document metadata. Large files use multipart upload with resume support. Never send attachment bytes through the FastAPI process except for a small, tightly limited fallback.

### Change feed and conflicts

The server assigns a monotonically increasing change sequence and an entity `revision`. The client requests `GET /v1/sync/changes?cursor=…`; it receives all allowed changes plus the next cursor. Polling is sufficient for version one. A websocket notification can later wake a normal pull; it must never become the only delivery mechanism.

All writes include `base_revision`. The server rejects a stale write with HTTP 409 and both versions. Use these rules:

| Change | Resolution |
| --- | --- |
| New document, tag, or attachment | Merge; attachments are additive and tags use set union. |
| Favorite | Personal preference; keep it device/account private and do not share it with Family members. |
| Edit to different document fields | Merge field-by-field when each field changed only on one side. |
| Same document field changed by two people | Preserve both snapshots, choose the newest server timestamp for the displayed value, and show **Review conflict** to editors. |
| Rename/delete a shared space/category | Require current revision; show a resolution screen rather than guessing. |
| Delete versus edit | Deletion becomes a tombstone. Keep it for 30 days; an edit against it requires explicit restore. |

Use server time and revisions for conflict decisions, not device clock alone. Store an activity event for every shared change: who changed what, when, and which revision. Version history/restoration can be a later release, but the immutable activity log should begin with version one.

## FastAPI backend

### Deployment shape

```text
Flutter iOS / Android
        │ HTTPS, Bearer access token
        ▼
FastAPI API ───────────── PostgreSQL
   │                         │
   ├── Redis-backed worker ───┘  (email, cleanup, virus scan orchestration)
   │
   └── S3-compatible object storage (private attachments)
```

Use PostgreSQL, not SQLite, for the server. Use FastAPI with Pydantic, SQLAlchemy 2 async support, Alembic migrations, and `psycopg` or `asyncpg`. Keep the application as a modular monolith: `auth`, `spaces`, `documents`, `sync`, and `storage` modules with their own routers, services, repositories, schemas, and tests. A message queue/worker is required for durable email, cleanup, and scanning work; FastAPI in-process background tasks are not sufficient for data that must survive a process restart.

Store document binaries in private S3-compatible storage such as AWS S3, Cloudflare R2, or MinIO in development. PostgreSQL stores metadata, object key, content hash, size, and lifecycle state only. Object downloads use short-lived signed URLs issued after a membership check.

### Server tables

| Table | Essential fields |
| --- | --- |
| `users` | UUID, display name, normalized email, email verification time, created/disabled timestamps |
| `password_credentials` | user ID, Argon2id password hash, password changed timestamp |
| `external_identities` | user ID, provider (`google`/`apple`), provider subject, email at link time; unique provider+subject |
| `refresh_sessions` | token family ID, hashed refresh token, device label, expiry, revoked/replaced timestamps |
| `spaces` | UUID, name, owner ID, created/updated/deleted timestamps, revision |
| `space_memberships` | space ID, user ID, role, joined/revoked timestamps; unique space+user |
| `invitations` | opaque token hash, space ID, invited email, role, expiry, acceptance/revocation timestamps |
| `categories` | UUID, space ID, name, icon/color, revision, timestamps, tombstone |
| `documents` | UUID, space/category IDs, title, description, OCR text, expiry data, revision, updated by/time, tombstone |
| `attachments` | UUID, document ID, object key, SHA-256, media type, size, order, upload state, tombstone |
| `changes` | monotonically ordered sequence, space/entity IDs, operation, revision, actor ID, payload summary, timestamp |
| `idempotency_keys` | account ID, key, request hash, completed response, expiry |
| `audit_events` | actor, target, action, metadata, timestamp, IP/device metadata as allowed by privacy policy |

Every shared content query joins through `space_memberships`; no client-supplied user or space ID grants access. Add PostgreSQL foreign keys, uniqueness constraints, indexes on membership and change cursor queries, and a row-level authorization service used by every endpoint.

### API contract, version one

All endpoints live under `/v1`, return typed JSON, use UTC ISO-8601 timestamps, and include entity revision fields. The OpenAPI schema is generated from FastAPI and becomes the source for a checked-in Dart client or carefully tested DTO layer.

| Area | Endpoint | Behavior |
| --- | --- | --- |
| Email auth | `POST /auth/sign-up`, `POST /auth/sign-in`, `POST /auth/refresh`, `POST /auth/sign-out` | Creates account, issues short access token and rotated refresh token. |
| Verification/recovery | `POST /auth/verify-email`, `POST /auth/password-reset/*` | Time-limited, single-use tokens; generic responses to avoid email enumeration. |
| Social auth | `POST /auth/google`, `POST /auth/apple` | Receives a provider ID token; backend verifies it and issues this app's session. |
| Account | `GET /me`, `DELETE /me`, `GET /sessions`, `DELETE /sessions/{id}` | Profile and device session controls. |
| Spaces | `GET/POST /spaces`, `PATCH/DELETE /spaces/{id}` | Lists accessible spaces and manages owner settings. |
| Members | `GET /spaces/{id}/members`, `PATCH/DELETE /spaces/{id}/members/{userId}` | Owner-only role/revocation operations. |
| Invitations | `POST /spaces/{id}/invitations`, `GET /invitations`, `POST /invitations/{token}/accept` | Email invite lifecycle. |
| Uploads | `POST /uploads`, `POST /uploads/{id}/complete`, `GET /attachments/{id}/download` | Signed, checksum-verified object transfer. |
| Mutation batch | `POST /sync/mutations` | Accepts ordered idempotent category/document/attachment/tombstone mutations. |
| Change feed | `GET /sync/changes?cursor=&limit=` | Incremental authorized download and next cursor. |
| Sync health | `GET /sync/status` | Optional diagnostics: server time, account state, quota. |

The initial batch limit should be modest (for example 100 metadata mutations) and responses must identify per-operation success, retryable failure, 409 conflict, and permanent validation failure. Do not make a blind “upload all local database” endpoint; it cannot safely retry or resolve conflicts.

### Authentication requirements

- Email passwords are hashed with Argon2id, never encrypted or logged. Rate-limit sign-in, sign-up, invitation acceptance, verification, and reset endpoints.
- Issue a short-lived access JWT plus a rotating refresh token. Store only the refresh-token hash in PostgreSQL; store both client tokens in `flutter_secure_storage`.
- For Google, Flutter sends the Google ID token to FastAPI. FastAPI verifies signature, audience, issuer, expiration, and the immutable provider subject before creating/linking an identity. Do not trust an email or a client-supplied Google user ID alone.
- For Apple, the iOS app obtains the Apple identity token through the native sign-in flow and the backend verifies its signature and claims against Apple's public keys. Persist the Apple subject, because Apple may provide name/email only on the first authorization.
- Use HTTPS everywhere, HSTS at the edge, production secrets in a server secret manager, and separate development/staging/production OAuth client IDs.
- Offer Apple sign-in on iOS when Google or another third-party sign-in method is offered, and configure its identifiers/callbacks in Apple Developer settings before submission.

### Security and privacy baseline

Documents are sensitive. Version one should use TLS in transit, encrypted managed disks/object storage at rest, private buckets, signed URLs with brief expiry, strict server-side membership checks, audit events, backups, and least-privilege service accounts.

Do not advertise end-to-end encryption in this version. Real end-to-end encryption changes search, OCR/AI, sharing keys, recovery, web access, and support operations; it needs a separate cryptographic design and security review. The first release should clearly state that the service encrypts data in transit and at rest. Add malware scanning/quarantine before sharing an uploaded attachment with another member.

## UX details

### Settings and profile

Add a **Backup & sync** section near Security:

- Signed out: “Set up backup” and a short privacy note.
- Signed in: account email, last successful sync, current upload/download counts, Sync now, Wi-Fi-only switch, and Manage storage.
- A persistent but unobtrusive cloud icon: solid check for current, rotating/progress for work, outline cloud for offline, and attention icon for a conflict or sign-in requirement.

### Shared-space screens

- Home/category list: Family shows member avatar stack/count, role label, and local sync indicator.
- Space details: name, members, Invite member, pending invitations, role management, activity, and Leave/Delete actions as applicable.
- Add document: space is selected first; category choices are scoped to that space. Viewers see no add/edit controls.
- Document viewer: “Added by Sam · synced 2 min ago”, attachment availability, and conflict banner only when relevant.

Keep account setup and sharing discoverable but optional. Do not redirect a user to sign-in simply because they create a private category or document.

## Delivery phases

### Phase 0 — foundations and product decisions

1. Confirm naming: “Shared spaces” in UI, with Family as the initial example.
2. Create the FastAPI repository, local Docker Compose stack (API, PostgreSQL, MinIO, Redis, mail catcher), CI, environment validation, structured logging, error reporting, and Alembic migration workflow.
3. Define OpenAPI schemas and Flutter DTO fixtures before wiring screens.
4. Add local sync tables/migrations and tests without changing visible behavior.

**Exit criteria:** a fresh local stack starts with one command; SQLite migration preserves existing documents/files; all current offline flows still work with networking disabled.

### Phase 1 — optional account and personal backup

1. Implement email sign-up, verified sign-in, refresh rotation, sign-out, password reset, and account deletion.
2. Connect the existing auth feature to the real API; replace template endpoints and models only after contract tests pass.
3. Add Google and Apple sign-in with backend token verification.
4. Implement the setup-backup and merge-device flow.
5. Implement the outbox, idempotency, attachment upload, change cursor, retry policy, and sync status UI for personal data only.

**Exit criteria:** a user can work offline, sign in later, close/reopen the app during upload, and recover all personal metadata/files on a second device without duplicates or blocked UI.

### Phase 2 — shared spaces

1. Implement spaces, memberships, invitations, owner/editor/viewer authorization, and audit events.
2. Add Share existing category → shared-space migration.
3. Scope document/category queries and mutations to spaces.
4. Add members/invitations/activity screens and server-enforced role handling.
5. Add denied-access cleanup and clear error states.

**Exit criteria:** an owner invites an editor; the editor uploads a document offline; it appears for the owner after sync; a viewer cannot write through the UI or raw API; revoked users cannot retrieve signed file URLs.

### Phase 3 — hardening and scale

1. Add conflict review UI, tombstone retention/purge jobs, quotas, resumable multipart uploads, Wi-Fi-only/background controls, and attachment scanning.
2. Add monitoring dashboards for sync success, queue age, upload failure, 409 rate, and storage growth.
3. Perform load, security, restore, and chaos testing. Test token theft/revocation, invitation replay, forged provider token, stale write, interrupted upload, and clock skew.
4. Publish privacy policy, data retention/deletion behavior, support tooling, incident procedure, and backup-restore runbook.

## Test plan

| Layer | Required coverage |
| --- | --- |
| Flutter domain/data | Local mutation + outbox atomicity, retry classification, cursor application, merge rules, and conflict records. |
| Flutter UI | Signed-out backup setup, sign-in return path, offline add/edit indicators, roles, invitation states, and no blocked local save. |
| FastAPI unit | Token verification, password hashing, permission checks, role transitions, idempotency, revisions, and signed URL authorization. |
| FastAPI integration | PostgreSQL migrations, attachment lifecycle, mutation batch retries, cursor paging, tombstones, account deletion, and revoked membership. |
| End-to-end | Two devices plus an offline interval; device restart during upload; concurrent edits; invitation acceptance; revocation; restore to a new device. |

Use deterministic clocks and test object storage in CI. Record API contract fixtures so the Flutter client and FastAPI server cannot drift silently.

## Decisions to keep explicit

| Decision | Recommended first-release choice | Why |
| --- | --- | --- |
| Shared unit | Shared space displayed as a category | Meets the Family use case while supporting roles and activity. |
| Offline source of truth | SQLite | Existing app behavior stays instant and available offline. |
| Sync transport | Durable outbox + cursor pull | Safe retries and restart recovery. |
| Binary storage | Private S3-compatible object storage | Keeps files out of PostgreSQL and supports direct resumable upload. |
| Conflict policy | Revision checks, automatic safe merges, explicit review for unsafe edits | Avoids silent loss of family documents. |
| Favorites | Personal-only | One person's star should not change everyone else's view. |
| Encryption promise | TLS + encryption at rest, no E2E claim | Honest and implementable while sharing/OCR remain server-compatible. |
| Background sync | Best effort | Correctness never depends on OS background execution. |

## References

FastAPI’s guidance covers OAuth2/JWT flows and Argon2 password hashing: [OAuth2 with Password and JWT](https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/). Google requires a backend to verify the signed ID token and its audience, issuer, and expiry rather than trusting a client-provided account ID: [Authenticate with a backend server](https://developers.google.com/identity/sign-in/web/backend-auth). Apple provides public keys and a REST API for verifying Sign in with Apple identity tokens: [Sign in with Apple REST API](https://developer.apple.com/documentation/signinwithapplerestapi). SQLAlchemy supports asynchronous PostgreSQL engines for the FastAPI data layer: [SQLAlchemy PostgreSQL dialect](https://docs.sqlalchemy.org/en/20/dialects/postgresql.html).
