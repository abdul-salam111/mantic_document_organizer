# Sub-folders within a category

## Context

Today a category is a single flat bucket — a document's `category_id`
points straight at one category row, and the category list (local and
synced) is one level deep everywhere (`manage_categories_view.dart`'s
list, the `category_picker_sheet.dart` grid, the backend's
`GET /spaces/{id}/categories`). The user wants to nest one more level
inside a category — e.g. a shared "Family Documents" category with
sub-folders "A", "B", "C", one per child — so a document can be filed
into a specific child's folder instead of the shared bucket as a whole.
This isn't limited to shared categories; any category (personal or
shared, built-in or custom) should be able to have sub-folders.

The design that reuses the most existing machinery: **a sub-folder is
just another category row, with a new nullable `parent_category_id`
pointing at its parent, capped at one level deep.** Because a document
already references "the category it's in" by a single `category_id`
with no notion of depth, filing a document into a sub-folder needs *no
document-schema change at all* — it just points at the sub-folder's row
instead of the parent's. Category sync, Drive-folder-per-category
resolution, and the built-in-promotion mechanism (ADR 0002) all already
operate per-row and need only minor extensions, not new subsystems.

Confirmed with the user: sub-folder creation in a shared space is
**Owner-only** (same rule as every other category mutation today — no
new permission tier). Adding a sub-folder under an untouched built-in
category **auto-promotes it first**, reusing the existing promotion
mechanism from ADR 0002 Phase 2, since a built-in gaining structure is
itself a customization. One level of nesting only (no sub-sub-folders) —
enforced both server-side and in the UI.

## Backend (`mantic_doc_org_backend`)

### 1. Migration + model
New Alembic revision (`down_revision` = `b2c3d4e5f6a7`):
- `categories`: add nullable `parent_category_id uuid REFERENCES
  categories.id ON DELETE CASCADE` (deleting a parent removes its
  sub-folders too — a sub-folder has no independent existence).
- `app/modules/spaces/models.py`'s `Category`: add the matching
  `parent_category_id: Mapped[uuid.UUID | None]` column.

### 2. Schemas (`app/modules/spaces/schemas.py`)
- `CategoryCreateRequest`: add `parent_category_id: uuid.UUID | None =
  None`.
- `CategoryResponse`: add `parent_category_id: uuid.UUID | None = None`.
- No change to `CategoryUpdateRequest` — a sub-folder's parent is set
  once at creation, not editable afterward (v1 scope cut; moving a
  sub-folder between parents isn't supported yet).

### 3. Repository (`app/modules/spaces/repository.py`)
- `create_category`: accept `parent_category_id: uuid.UUID | None =
  None`, pass through to `Category(...)`.
- No other repo changes needed — `list_categories`/`get_category`
  already return full rows including the new column.

### 4. Service (`app/modules/spaces/service.py`)
- `create_category`: validate depth before creating —
  if `parent_category_id` is set, load that parent via
  `get_category` and raise `ConflictError` (one-level-only) if the
  parent *itself* already has a `parent_category_id`. Reuses the
  existing `_promote_builtin_category` path unchanged: a client
  creating a sub-folder under a still-untouched built-in first calls
  the existing promote-by-`promoted_from_builtin_key` create (no new
  code there), *then* creates the sub-folder with
  `parent_category_id` = the promoted row's id — two calls client-side,
  zero new promotion logic server-side.

### 5. Routes (`app/api/v1/spaces.py`)
- `create_category`: pass `payload.parent_category_id` through to the
  service call — same `OwnerMembershipDep` gate every other category
  mutation already uses (matches the confirmed Owner-only decision, no
  new dependency needed).
- `list_categories`: no change — sub-folders are additional rows in the
  same flat response; the Flutter client groups them by
  `parent_category_id` for display (keeps the backend response shape
  stable, matches how built-in merging already works client-side).

### 6. Tests (`app/tests/integration/test_spaces_and_documents.py`)
- Creating a sub-folder under a custom category succeeds and the
  response carries the right `parent_category_id`.
- Creating a sub-folder under a sub-folder (depth 2) is rejected.
- Creating a sub-folder under an untouched built-in: promote first,
  then attach — full round trip, document filed into the sub-folder,
  confirm it appears correctly in the space's document listing.
- A Viewer/Editor (non-Owner) attempting to create a sub-folder in a
  shared space gets 403 (same existing `OwnerMembershipDep` test
  pattern already used for plain category creation).

## Flutter (`mantic_document_organizer`)

### 1. Local schema (`lib/core/database/app_database.dart`)
Bump `version` 8 → 9. New `onUpgrade` step:
`ALTER TABLE categories ADD COLUMN parent_id TEXT` (nullable, no FK —
matches this table's existing lack of declared FKs). Update
`_categoryToRow`/`_categoryFromRow` to read/write it.

### 2. Entity (`lib/features/categories/domain/entities/category_item.dart`)
Add `final String? parentId` + thread through the constructor and
`copyWith`. Add a `bool get isSubfolder => parentId != null` getter,
mirroring the existing `isShared`/`isViewerOnly` getters.

### 3. Sync (`document_sync_service.dart`)
- Push loop (new-category creation): push parents before children
  within the same run — sort `fetchCategories()` so `parentId == null`
  entries are pushed first, since a child's POST needs its parent's
  *remote* id already resolved via `remoteCategoryIdForLocalId`.
  Include `parent_category_id` in the POST payload (resolved local →
  remote id; omit/null if the parent hasn't synced yet, which can't
  happen given the ordering above).
  - A built-in that only differs from its default by *having a local
    sub-folder* (name/icon/color otherwise untouched) must still be
    promoted — extend the existing `builtInCategoryDivergesFromDefault`
    check (or add a sibling check) so "has at least one local
    sub-folder" also counts as divergence, consistent with "gaining
    structure is a customization" from the ADR.
- Pull loop: map remote `parent_category_id` → local id via
  `localCategoryIdForRemoteId` when building/reconciling a local
  `CategoryItem`.

### 4. UI
- **Manage categories** (`manage_categories_view.dart`/viewmodel): add
  an "Add sub-folder" action to a top-level category's row menu
  (hidden for a row that's already a sub-folder, enforcing the one-level
  cap in the UI). It opens the existing `AddCategoryView`/
  `AddCategoryViewModel` with the parent pre-set and locked (not a new
  screen) — reuses ~95% of the existing add/edit flow. The normal
  "Add Category" entry point (top-level, from Home) stays unchanged, no
  parent picker shown there.
- **Category picker** (`category_picker_sheet.dart`): if the tapped
  top-level category tile has sub-folders, push the *same* sheet widget
  again, this time showing just that category's children (plus the
  parent itself, for "file directly in the category, no sub-folder") —
  the sheet is already generic over `List<CategoryItem>`, so this is a
  recursive call with a filtered list, not a new widget.
- **Category documents screen**
  (`category_documents_viewmodel.dart`/view): when the opened category
  has sub-folders, show a horizontal filter chip row above the document
  list ("All" / each sub-folder name), filtering the same list by
  `categoryId == subfolder.id` vs the parent's own id.
- **Home tile document count** (`HomeViewModel.documentCountFor`): a
  top-level category's badge should count documents filed in it *and*
  in any of its sub-folders, not just an exact id match — change the
  count to match against `{category.id, ...subfolderIdsOf(category)}`.

## Verification

- Backend: run the new integration tests; `ruff check` on changed
  files; apply the migration up/down against the local throwaway
  Postgres db (`dropdb`/`createdb` + `alembic upgrade head` /
  `downgrade -1`) before touching the Neon production branch, then
  apply to production and redeploy (`uv run fastapi deploy`), same
  process used for ADR 0002's migrations.
- Flutter: `flutter analyze --fatal-infos`, `flutter test` (expect the
  same pre-existing 12-failure baseline, zero new regressions), plus a
  manual pass: create a sub-folder under a custom category, under a
  freshly-created shared category, and under an untouched built-in;
  file a document into each; confirm the Home tile's document count
  includes sub-folder documents; confirm a second device syncing the
  same shared space sees the sub-folder and the filed document under
  it, not duplicated.
