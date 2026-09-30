# Categories, documents, and favorites

The dependency direction is presentation → domain ← data. `core/di/injection_container.dart` is the composition root and is the only place that chooses concrete repositories and device adapters.

- Domain owns immutable category/document values, repository contracts, use cases, and the shared expiry/trash policy. It imports only Dart and other domain code.
- Presentation owns controllers, form state, filtering for display, and rendering. It calls use cases for persistence, attachment capture/import, OCR/AI enrichment, sharing, and PDF export. It never imports a data implementation. Feature presentation barrels export presentation only.
- Data implements the contracts using SQLite and device/service adapters. SQLite mapping remains in `AppDatabase`; feature-local datasource interfaces make repository behavior testable without platform channels. Repository caches publish changes only after persistence succeeds, and serialize mutations. Notification failures are reported separately from persistence failures.
- Favorites is a projection of the document repository, not a second table or independent cache. Favorite changes made on any screen are visible everywhere.

Startup initializes the database and notifications, then hydrates repositories through the domain use cases. A new remote source belongs in data and must map transport payloads to domain values. The removed generated REST scaffolds had no production callers or configured document backend; this change does not add cloud synchronization.

Write use cases return futures. Views await completion through `persistAction` before showing success or navigating, and retain the form on failure. Save buttons expose busy state. File/PDF preview widgets may use rendering SDKs; file copying, capture, sharing, and export stay behind domain contracts.

Run `flutter test --no-pub --no-test-assets test/architecture test/features/documents` for dependency-boundary and persistence regression checks. The architecture tests also traverse local imports from data to catch hidden presentation dependencies in core barrels.
