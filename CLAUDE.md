# CLAUDE.md

Persistent context for AI agents working in this repo. Read this before
exploring the codebase from scratch — it saves re-deriving conventions
that aren't obvious from the code alone.

## What this project is

A Flutter Clean Architecture + Provider + GetIt + go_router starter
template, now being built out into a concrete app — **Mantic Document
Organizer** — see "Product spec" below for what that app actually is.
`lib/features/auth` was the template's original example feature;
`home`/`navbar`/`search`/`favorites`/`profile`/`add_document` are the
app-specific features built on top of it so far. Mason bricks (see
below) still scaffold new features/pages the same way they always did.
If you're asked to "add a feature" or "add a page," check first whether
a brick already does it — don't hand-write what a brick would generate.

## Product spec — Mantic Document Organizer

This repo is no longer just the generic template — it's being built into
**Mantic Document Organizer**, a document-scanning/organizing app. The
full technical spec lives in `Mantic Document Organizer — Technical
Implementation Spec.md` at the repo root — read it before any feature
work beyond small fixes; this section only summarizes the parts most
likely to affect how you write code here.

**Architecture**: offline-first for all core functionality,
online-enhanced only for AI features (Phase 3+). sqflite/SQLite is the
on-device source of truth for everything in Phase 1-2 — reads/writes
never need the network. A FastAPI + PostgreSQL backend exists only for
two opt-in things: account backup/sync (Google Drive-backed) and AI
feature calls (Anthropic API). **No part of the core app should ever
gate on a signed-in user.**

**Data model** (mirrored in sqflite locally and Postgres on the
backend): `User`, `Category` (13 built-in + custom, JSON
`field_schema`), `Document` (core entity — category, JSON `fields`,
tags, favorite, soft-delete via `deleted_at`), `Page`, `Tag`, `Todo`.
Phase 2 adds `ocr_text` + `detected_dates` to Document; Phase 3 adds
`embedding`; Phase 4 adds `Vault`/`VaultMember`/`VoiceNote`.

**Navigation**: bottom tabs are **Home, All Docs, Favorites, Profile**,
with a centered raised "+" button for adding a document. Search is
**not a tab** — it's opened from Home's search bar. Trash is opened
from Profile, not a tab. Splash goes straight to Home with no auth
gate; Profile has a distinct "not signed in" state (local-only status,
"Set up backup" CTA) vs. "signed in" state.

**Phases**: 1 (local-only capture/categorize/organize, sqflite,
optional Google-backed backup) → 2 (on-device OCR, auto-categorization,
deadline detection — still fully offline) → 3 (AI search/summaries/
clustering — call-time online, everything else stays unaffected without
a connection) → 4 (shared vaults, voice notes, full sync with conflict
resolution).

### Known mismatches with the current scaffold (as of 2026-09-22)

The template/brick machinery below was built before this spec existed
and hasn't been reconciled with it yet:

- **State management**: the spec proposes Riverpod or Bloc; every
  feature built in this repo so far (auth, home, search, favorites,
  profile, add_document, navbar) uses **Provider** (`ChangeNotifier` +
  GetIt), per the template's own convention documented below.
  Unresolved — follow Provider for consistency with existing code until
  this is explicitly decided otherwise.
- **Navbar tabs**: now **Home, All Docs, Favorites, Profile** (see
  `lib/features/navbar/`), matching the spec's tab naming — but the
  `search` feature folder/classes (`SearchView`/`SearchViewModel`, under
  `lib/features/search/`) are unrenamed, and that tab still has its own
  embedded search field rather than Search being fully absorbed into
  Home's own search bar as the spec describes. `SearchView` now also
  shows category tabs (`SearchViewModel.categoryTabs`) for browsing
  by category within "All Docs".
- **Local database**: no sqflite integration exists yet —
  `Document`/`Category`/`Page`/`Tag`/`Todo` aren't modeled locally at
  all. Everything built so far (search/favorites/add_document) talks to
  the placeholder REST `ApiEndPoints` instead, which doesn't match the
  offline-first design — those datasources will need to become
  sqflite-backed repositories instead once this is tackled.

Don't treat the existing scaffold as ground truth over the spec when
they conflict — flag it and ask rather than silently extending the
mismatched pattern further.

## Architecture rules

Every feature under `lib/features/<name>/` follows the same layering:

```
data/
  datasources/          — talks to DioHelper (REST) or another SDK
  models/                request_models/ + response_models/ (freezed)
  repository_impl/      — maps models -> domain entities, extends BaseRepository
domain/
  entities/              plain Dart classes, no REST/SDK-specific shape
  repositories/          abstract interface (I<Feature>Repository)
  usecases/              extends Usecase<T, Params>, calls the repository
presentation/
  <subflow>/             one folder per sub-flow (e.g. signin, signup)
    views/
    viewmodels/          extends ChangeNotifier with UseCaseExecutor
    widgets/
<feature>_exports.dart  — barrel export; the ONLY way other
                           features/core files should import this feature
```

**Never let a REST/SDK-specific type escape the repository boundary.**
`data/repository_impl/*.dart` maps `UserModel`/`FirebaseUser`/whatever ->
the feature's own `Entity` type. Domain and presentation never see
`UserModel`, `FirebaseAuthException`, or `DioException` directly.

**Error handling**: everything funnels through `Result<T>`
(`Success`/`Failure`, wrapping `AppException`) — this project's own type,
not `Either`/`fpdart`. `BaseRepository.execute()` catches whatever the
datasource throws and wraps it. `UseCaseExecutor.execute()` (mixed into
ViewModels) unwraps `Result` and manages loading/error state
automatically — look at `lib/core/shared/domain/usecase/execute_usecase.dart`
before touching a ViewModel's state-handling by hand.

**`core/widgets/`** is organized into subfolders by purpose
(`buttons/`, `inputs/`, `feedback/`, `appbar/`, `branding/`) — put new
shared widgets in the matching subfolder, not flat in `core/widgets/`.

## Reuse before you build — this template is not a blank slate

This repo already ships a large, working set of extensions/utils/widgets.
**Before writing a helper method, formatter, validator, or common
widget, check whether one already exists here.** Duplicating what's
already in `core/` is a bug, not a stylistic choice — it means two
slightly-different implementations of the same thing drifting apart over
time.

`lib/core/utils/utils_exports.dart` and `lib/core/widgets/widgets_exports.dart`
are the barrels — import from those, not individual files. Full inventory
below — check it before writing anything new.

#### `extensions.dart`

- `ContextExtensions` on `BuildContext`: `screenWidth`, `screenHeight`,
  `paddingTop`, `paddingBottom`, `pixelRatio`, `platformBrightness`,
  `isLandscape`, `isPortrait`, `locale`, `navigator`,
  `bouncingScrollPhysics`, `neverScrollableScrollPhysics`, `scaffold`,
  `overlay`, `focusScope`, `formState`, `scrollController`.
- `StringExtensions`: validation getters (see `validators.dart` below for
  the full validation set — this file re-exports/complements them).

#### `theme_utils.dart`

- `AppTextStyleExtension` on `BuildContext`: `displayLarge/Medium/Small`,
  `headlineLarge/Medium/Small`, `titleLarge/Medium/Small`,
  `bodyLarge/Medium/Small`, `labelLarge/Medium/Small`.
- `AppColorExtension` on `BuildContext`: `primary`, `primaryDark`,
  `primaryLight`, `secondary`, `secondaryDark`, `background`,
  `textSecondary`, and more theme-aware color getters (light/dark
  variants resolved automatically) — skim the file for the full set
  before hardcoding a `Color(0x...)`.

Use these instead of `Theme.of(context).textTheme...`/hardcoded colors.

#### `date_utils.dart`

- `DateTimeExtensions` on `DateTime` — **date checks**: `isToday()`,
  `isYesterday()`, `isTomorrow()`, `isPast()`, `isFuture()`,
  `isSameDay/Month/Year(other)`, `isThisWeek/Month/Year()`; **weekday**:
  `isWeekend()`, `isWeekday()`, `dayName`, `shortDayName`, `monthName`,
  `shortMonthName`; **formatting**: `formatDate()`, `formatISODate()`,
  `formatDateTime()`, `formatted`, `formattedLong`, `timeOnly`,
  `time12Hour`, `fullFormat`, `format(pattern)`; **relative time**:
  `timeAgo`, `timeAgoShort`, `timeUntil`; **age/diff**: `getAge()`,
  `differenceInDays/Months/Years/Hours/Minutes(other)`; **arithmetic**:
  `addDays/subtractDays`, `addMonths/subtractMonths`,
  `addYears/subtractYears`, `addHours`, `addMinutes`; **period
  bounds**: `startOfDay/endOfDay`, `startOfWeek/endOfWeek`,
  `startOfMonth/endOfMonth`, `startOfYear/endOfYear`,
  `startOfQuarter/endOfQuarter`; **week/month/quarter info**:
  `weekOfYear`, `firstDayOfWeek/lastDayOfWeek`, `daysInMonth`,
  `firstDayOfMonth/lastDayOfMonth`, `isLeapYear`, `quarter`; **business
  days**: `nextBusinessDay`, `previousBusinessDay`, `addBusinessDays(n)`,
  `businessDaysBetween(other)`; **`copyWith(...)`**.
- `NullableDateTimeExtensions` on `DateTime?`: `orNow`,
  `orDefault(date)`, `formatOrEmpty([pattern])`, `timeAgoOrEmpty`,
  `isNullOrPast`, `isNullOrFuture`.
- `StringToDateTime` on `String`: `toDateTime`, `parseDate(format)`,
  `parseCommonDate`, `isValidDate`.
- `DurationExtensions` on `Duration`: `formatted` ("HH:mm:ss"),
  `formattedShort` ("2h 30m"), `readable`.
- `IntToDuration` on `int`: `.days`, `.hours`, `.minutes`, `.seconds`,
  `.milliseconds` (e.g. `5.minutes`).
- `DurationFormatting` on `num`: `asMinutesSeconds`, `asDuration`,
  `asMilliseconds`.

#### `math_utils.dart`

- `PercentageFormatting` on `num`: `asPercentage`, `toPercentage({decimals})`,
  `asPercentageWithSign`.
- `DecimalFormatting` on `num`: `toDecimal(places)`, `rounded`,
  `roundedUp`, `roundedDown`, `to2Decimals`, `to0Decimals`,
  `withoutTrailingZeros`.
- `FileSizeFormatting` on `num`: `asFileSize`, `toFileSize({decimals})`.
- `OrdinalFormatting` on `int`: `asPosition` (1 -> "1st").
- `NumberValidation` on `num`: `isBetween(min, max)`, `isPositive`,
  `isNegative`, `isZero`, `isEven`, `isOdd`, `clampValue(min, max)`.
- `NullableNumberExtensions` on `num?`: `orZero`, `orDefault(v)`,
  `asCurrencyOrEmpty`, `withCommasOrEmpty`, `isNullOrZero`.

#### `currency_utils.dart`

- `CurrencyFormatting` on `num`: `withCommas`, `asCurrency`,
  `formatCurrency({symbol, locale, decimalDigits})`, `asPrice`,
  `formatPrice({symbol})`, `asCompactCurrency`, `asPKR`, `asEUR`, `asGBP`,
  `asCompact`, `asCompactWithDecimals`, `toCompact({decimals})`,
  `asSocialCount`.
- `StringToNumber` on `String`: `toIntOrNull`, `toDoubleOrNull`,
  `toIntOr(default)`, `toDoubleOr(default)`, `parseNumber`,
  `parseCurrency`.

#### `validators.dart`

- `StringValidationExtensions` on `String`: `isValidEmail`,
  `isValidPhone`, `isValidPakistaniPhone`, `isValidUSPhone`,
  `isValidPassword`, `isStrongPassword`, `isMediumPassword`,
  `passwordStrength`, `isValidName`, `isValidFullName`,
  `isValidUsername`, `isNumeric`, `isInteger`, `isAlpha`,
  `isAlphanumeric`, `isValidURL`, `isValidDomain`, `isValidIP`,
  `isValidCNIC`, `isValidPakistaniPassport`, `isValidCreditCard`,
  `isValidDate`, `isValidTime`, `isValidHexColor`, `isValidPostalCode`,
  `isValidISBN`, `isBlank`, `isNotBlank`, `isWhitespace`, `isLowerCase`,
  `isUpperCase`, `containsEmoji`, `isPalindrome`.
- `Validator` class (static, all return `String?` for use directly as a
  `TextFormField`/`CustomTextFormField` `validator:`): `validateRequired`,
  `validateEmail`, `validatePhone`, `validatePakistaniPhone`,
  `validatePassword`, `validateStrongPassword`, `validatePasswordMatch`,
  `validateName`, `validateFullName`, `validateUsername`,
  `validateMinLength`, `validateMaxLength`, `validateLengthRange`,
  `validateExactLength`, `validateNumeric`, `validateInteger`,
  `validateNumberRange`, `validateMinValue`, `validateMaxValue`,
  `validateURL`, `validateDomain`, `validateIP`, `validateCNIC`,
  `validateCreditCard`, `validateDate`, `validateAge`,
  `validateFutureDate`, `validatePastDate`, `validateRegex`,
  `validateMultiple`, `combineAnd(...)` (composes multiple validators
  into one). Also exports `PasswordStrengthIndicator`, a ready widget.

#### `widget_utils.dart`

- `WidgetExtensions` on `Widget` — chain these directly on any widget
  instead of wrapping by hand: `withPadding(edgeInsets)`,
  `withMargin(edgeInsets)`, `showIf(condition)`, `onTap(callback, {opaque})`,
  `center()`, `withBorder({color, width, borderRadius})`,
  `withBackground(color, {borderRadius})`, `withTooltip(message, {decoration, height})`,
  `withSize({width, height})`, `expanded({flex})`, `flexible({flex, fit})`,
  `withHero({tag})`, `withRotation(angle, {origin})`,
  `withScale(scale, {origin})`, `withTranslation(offset)`,
  `withFadeAnimation(controller)`, `withOpacity(opacity)`,
  `align(alignment)`, `withShadow({color, blurRadius, offset, spreadRadius})`,
  `withRoundedCorners(radius)`, `onLongPress(callback, {opaque})`,
  `onDoubleTap(callback, {opaque})`, `withInkWell({onTap, onLongPress, onDoubleTap, borderRadius})`,
  `positioned({top, bottom, left, right, width, height})`,
  `withAspectRatio(ratio)`, `constrained({minWidth, maxWidth, minHeight, maxHeight})`,
  `fitted({fit, alignment})`, `clipOval()`,
  `asCard({color, elevation, shape, margin, clipBehavior})`,
  `safeArea({top, bottom, left, right, minimum})`,
  `scrollable({scrollDirection, physics, padding})`,
  `visible(visible, {replacement})`, `decorated(decoration)`,
  `withGradient(gradient, {borderRadius})`, `intrinsicHeight()`,
  `intrinsicWidth()`, `baseline({baseline, baselineType})`,
  `absorbPointer({absorbing})`, `ignorePointer({ignoring})`,
  `withSlideAnimation(position)`, `withScaleAnimation(scale)`,
  `withRotationAnimation(turns)`, `container({width, height, color,
  padding, margin, decoration, alignment, constraints})`, `color(color)`.
  (e.g. `MyWidget().withPadding(.all(12)).onTap(() {...})` instead of
  nesting `GestureDetector(child: Padding(...))` by hand.)
- Ready-made wrapper widgets — use instead of writing your own: `UnfocusWrapper`
  (tap-outside-to-dismiss-keyboard, already used in `SigninPage`/`SignupPage`),
  `KeyboardDismisser`, `LoadingOverlay`, `ResponsiveBuilder`
  (mobile/tablet/desktop breakpoints), `ConditionalWrapper`,
  `SafeAreaWrapper`, `PaddingWrapper`, `EmptyStateWidget`,
  `ErrorStateWidget`, `ShimmerLoading`, `AsyncBuilder<T>` (wraps
  `FutureBuilder` with loading/error states), `StreamBuilderWrapper<T>`,
  `DebouncedTextField`, `AnimatedVisibility`, `DividerWithText`,
  `CardWrapper`, `ScrollToHide`, `PullToRefreshWrapper`,
  `StatusBarColor`, `GradientContainer`, `PlaceholderBox`.

#### `apptoast_utils.dart`

`AppToastsUtils` (static, already what `UseCaseExecutor` calls on
failure — don't add a second toast/snackbar mechanism): `show(...)`,
`showSuccess/showError/showWarning/showInfo(...)`,
`success/error/warning/info(message, {title, position})`,
`loading(message, {position})`, `withAction({...})`, `custom({...})`,
and positioned shortcuts `showSuccessTop/showErrorTop/showWarningTop/showInfoTop`
and `.../Bottom` variants.

#### `file_picker.dart`, `type_conversion.dart`

Also worth skimming before writing file-selection or type-coercion
helpers by hand — same "check first" rule applies.

#### `core/widgets/`

`CustomButton` (buttons/), `CustomTextFormField`, `CustomDropdownTextField`,
`CustomSearchField` (inputs/), `CustomAppBar` (appbar/), `AppLogo`
(branding/), `LoadingIndicator`, `LoadingPopup` (feedback/). Use these
for any new page instead of raw `ElevatedButton`/`TextField`/`AppBar`.

If something genuinely doesn't exist yet, add it to the right existing
file (matching its section/extension) rather than creating a new
similarly-named file next to it — e.g. a new number formatter goes in
`math_utils.dart` or `currency_utils.dart`, not a new `format_utils.dart`.

## Dart style

Prefer modern Dart 3 shorthand over older, more verbose patterns:

- **Pattern matching / switch expressions** over `if`/`else if` chains on
  a type or sealed class — see `Result.fold()` in
  `core/shared/domain/result/result.dart` for the style already used
  here (`switch (self) { Success<T>() => ..., Failure<T>() => ... }`).
- **Records** for returning more than one value instead of a tiny
  one-off class.
- **Null-aware operators** (`?.`, `??`, `??=`, `...?` spread) instead of
  explicit null checks where they read at least as clearly.
- **Collection `if`/`for`** and spread (`...`) inside list/map literals
  instead of building a list imperatively then adding to it.
- **Cascades** (`..`) when configuring one object with several calls.
- **`const` constructors** wherever the value is compile-time constant —
  this template's `flutter_lints` config flags avoidable non-const
  widgets.
- **Arrow syntax** (`=>`) for single-expression functions/getters,
  matching the extension methods throughout `core/utils/`.

Don't reach for these where they'd hurt readability (e.g. don't force a
switch expression that's less clear than a plain `if`) — the point is
matching this codebase's existing idiom, not being clever.

### Dot-shorthand syntax — use it wherever the target type is known

This SDK (`^3.10.0`, language version >= 3.10) supports Dart's
dot-shorthand syntax: when a parameter/variable/return/equality-check
type is statically known, drop the type name and write just `.member` —
the same idea as Swift's leading-dot syntax. It's an *implicit static
access on the apparent context type*: if the compiler knows an
expression must be type `T`, `.foo` means `T.foo` and `.new(args)` means
`T.new(args)`/`T(args)`. **This codebase already uses it** — e.g.
`padding: .all(12)` in
`lib/features/auth/presentation/signin/views/signin_page.dart` (and
`signup_page.dart`), short for `EdgeInsets.all(12)`. Prefer it over the
fully-qualified form in any new code where the surrounding type is
unambiguous. It applies to more than enums — four categories, all valid:

**1. Enum values**

| Instead of | Write |
|---|---|
| `MainAxisAlignment.center` / `.spaceBetween` / `.spaceEvenly` / `.spaceAround` | `.center` / `.spaceBetween` / `.spaceEvenly` / `.spaceAround` |
| `CrossAxisAlignment.start` / `.end` / `.center` / `.stretch` | `.start` / `.end` / `.center` / `.stretch` |
| `Axis.horizontal` / `.vertical` | `.horizontal` / `.vertical` |
| `TextAlign.center` / `.left` / `.right` / `.justify` | `.center` / `.left` / `.right` / `.justify` |
| `BoxFit.cover` / `.contain` / `.fill` | `.cover` / `.contain` / `.fill` |
| `BoxShape.circle` / `.rectangle` | `.circle` / `.rectangle` |
| `TextDirection.ltr` / `.rtl` | `.ltr` / `.rtl` |
| `FontStyle.italic` / `.normal` | `.italic` / `.normal` |
| any project-defined `enum` (e.g. `ApiStatus.loading`) | `.loading` |

**2. Static getters/constants** (not technically enums, but same syntax)

| Instead of | Write |
|---|---|
| `FontWeight.bold` / `.w600` / ... | `.bold` / `.w600` |
| `Alignment.center` / `.topCenter` / `.bottomLeft` etc. | `.center` / `.topCenter` / `.bottomLeft` |
| `Curves.easeInOut` / `.bounceIn` etc. | `.easeInOut` / `.bounceIn` |
| `Duration.zero` | `.zero` |
| `BigInt.zero` | `.zero` |
| `Colors.transparent` (a `Color` static constant) | `.transparent` |

**3. Constructors — named and unnamed**

| Instead of | Write |
|---|---|
| `EdgeInsets.all(12)` | `.all(12)` |
| `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` | `.symmetric(horizontal: 16, vertical: 8)` |
| `EdgeInsets.only(top: 8)` | `.only(top: 8)` |
| `BorderRadius.circular(8)` | `.circular(8)` |
| `BorderRadius.only(topLeft: Radius.circular(8))` | `.only(topLeft: .circular(8))` (both shorthands nest) |
| `Radius.circular(8)` | `.circular(8)` |
| `ScrollController()` (unnamed constructor) | `.new()` |
| `AnimationController(vsync: this)` | `.new(vsync: this)` |
| `List.filled(5, 0)` | `.filled(5, 0)` |
| `Point.origin()` (named constructor) | `.origin()` |

**4. Static methods**

| Instead of | Write |
|---|---|
| `int.parse('8080')` | `.parse('8080')` |
| `String.fromCharCode(72)` | `.fromCharCode(72)` |
| `.fromCharCode(72).toLowerCase()` (chaining after) | works the same — the shorthand only applies to the first call, the rest is normal method chaining |

**Works in**: any parameter with a known type, a typed variable
declaration (`EdgeInsets padding = .all(8);`), a typed return, `const`
contexts (`const .running`, `const .origin()`), inside typed collection
literals (`List<Point> pts = [.origin(), .new(1.0, 1.0)];`), and on the
**right-hand side** of an equality check when the left side's type is
known (`myColor == .green` means `myColor == Color.green`).

**Does NOT work — keep the fully-qualified form here**:
- As the start of an expression statement (`.log('hi');` alone is
  invalid — needs an assignment/argument context to infer from).
- On the **left**-hand side of `==`/`!=` (`.red == myColor` fails; only
  the right side gets shorthand treatment).
- When the other side of `==` is a complex/ambiguous expression the
  compiler can't pin a single type to.
- Right after a type cast that obscures the context type (e.g.
  `(myColor as Object) == .green`).
- To reach `Null`'s members through a nullable type, or `Future`'s
  members through a `FutureOr<T>` — the context type there isn't
  concrete enough.
- Anywhere the target type is `dynamic`, untyped (`var x = .all(8);`
  with nothing else pinning the type), or otherwise ambiguous.

Sources: [Dart language: dot shorthands](https://dart.dev/language/dot-shorthands), [Dot shorthands in Flutter](https://docs.flutter.dev/ui/dot-shorthands), [dot-shorthands feature specification (dart-lang/language)](https://github.com/dart-lang/language/blob/main/accepted/3.10/dot-shorthands/feature-specification.md)

## The marker-comment convention

`lib/routes/route_names.dart`, `route_paths.dart`, `app_router.dart`, and
`lib/core/di/injection_container.dart` contain stable anchor comments:

```
// GENERATED_IMPORTS_START / _END
// GENERATED_ROUTE_NAMES_START / _END
// GENERATED_ROUTE_PATHS_START / _END
// GENERATED_ROUTES_START / _END
// GENERATED_SETUP_CALLS_START / _END
// GENERATED_DEPENDENCIES_END        (no _START — inserts go at end of file)
```

Every brick that wires a new feature/page into these files inserts text
immediately before the matching `_END` marker — never by brace-counting
or guessing indentation. **If you ever hand-edit these files, do not
delete these markers.** A missing marker makes every brick that touches
that file fail loudly (by design — it refuses to guess where to insert
rather than risk corrupting the file). If a marker goes missing, restore
it from git history rather than have a brick work around its absence.

## Bricks — what each one does

All defined in `mason.yaml`, source in `bricks/`. Run `mason get` once
per clone (or after editing any brick) before `mason make`.

| Brick | Use when | Vars |
|---|---|---|
| `setup_project_architecture` | Scaffolding this template's structure + the `auth` example feature into a brand-new/empty project. Never on a project that already has `lib/features/auth`. | none |
| `create_feature` | Adding a brand-new feature module (own data/domain/presentation). | `page_name` (feature name, despite the var name) |
| `add_page` | Adding another sub-flow to a feature that already exists (e.g. `change_password` alongside auth's `signin`/`signup`) — shares the feature's existing data/domain, only scaffolds presentation + a usecase stub. | `feature_name`, `page_name` |
| `add_firebase` | Adding Firebase Auth as a **drop-in alternative** to REST auth — implements the same `IAuthRepository` interface. Does **not** activate itself (see below). | `confirm` |
| `remove_page` | Deleting one page/sub-flow and its wiring. | `feature_name`, `page_name`, `confirm` |
| `remove_feature` | Deleting an entire feature module and everything it contains. | `feature_name`, `confirm` |
| `remove_firebase` | Undoing `add_firebase`. Refuses to run if Firebase is currently the active `IAuthRepository`. | `confirm` |
| `asset_generator` | Regenerating asset path constants after adding files under `assets/`. | `project_name` |

**`add_firebase` never flips `IAuthRepository` to
`FirebaseAuthRepositoryImpl` itself** — that's a deliberate one-line
manual edit in `authDependencies()` (`lib/core/di/injection_container.dart`),
documented in the brick's own console output. Never make a brick change
which backend is *active* without the user asking for that specific
switch.

**Boolean vars need `=` on the CLI**: `--confirm=true`, not bare
`--confirm` (that errors with "Missing argument"). Interactive runs
(`mason make remove_page` with no flags) prompt y/N instead.

**Removal bricks scan `lib/` for external references before deleting**,
and warn about anything outside brick-generated files that still points
at what's being removed (e.g. `core/services/session_manager.dart`
depends on `AuthEntity`, so removing the `auth` feature warns about it).
This is a *warning*, not a block — `confirm` is the actual gate. When
writing a new removal brick, exclude from that scan whatever files the
brick's own `post_gen.dart` already auto-fixes — otherwise the warning
is just noise about work that's about to happen anyway.

## Verification workflow — do not skip this

**Never run `mason make`/`build_runner`/`flutter pub get` directly
against this repo's own tracked working tree when developing or testing
a brick.** Copy the repo to a scratch temp directory first, run the brick
there, verify, then discard the copy. This project's own scratch-copy
history has caught real bugs (missing files, broken markers, stale
caches) that only surfaced when tested this way.

```sh
robocopy "D:\path\to\this\repo" "C:\path\to\scratch\dir" //E //XD .git build .dart_tool //XF *.dill
```

Use `//E` (double slash) on Windows/Git Bash — a single `/E` gets mangled
by MSYS path conversion into `E:/`. Verify the destination path landed
correctly before trusting the copy (a wrong prefix can silently
misdirect it).

After copying, if the scratch copy's `.mason/bricks.json` was copied
from this repo, it still points at absolute paths (this repo's real
`bricks/` directory) rather than its own copy — **always** `rm -rf
.mason mason-lock.json && mason get` in the scratch copy before running
anything there. A brick that isn't found, or a var that mysteriously
doesn't exist, is almost always this stale-cache problem, not a bug in
the brick.

Round-trip test any add/remove brick pair by running both in the same
scratch copy and diffing the touched files against their pre-`add_*`
state — they should be identical except for incidental blank-line
differences from `dart format`. If they're not, something in the removal
regex/marker logic is wrong.

After verifying in scratch, run `flutter analyze --fatal-infos` and
`flutter test` in the real repo as a final sanity check — this repo's CI
runs analyze with `--fatal-infos`, so an info-level lint is a real
failure here, not just a suggestion.

## Line endings

Files in this repo are CRLF (Windows/git `autocrlf`). Any brick hook
that does plain string/regex matching against existing file content
(not the marker-based `RegExp`/`multiLine` helpers, whose `$` already
treats `\r\n` as a line terminator) needs to normalize CRLF -> LF before
matching and convert back before writing, or the match silently fails
against real files despite working in a mental model built on LF. See
the `_RawFile` helper class duplicated across `add_firebase`,
`remove_page`, `remove_feature`, and `remove_firebase`'s `hooks/post_gen.dart`.

## Mason build cache

`bricks/*/hooks/build/hooks/{pre_gen,post_gen}/*.dill` and
`bricks/*/hooks/pubspec.lock` are committed (matches this repo's existing
convention) — they're compiled hook caches that speed up `mason make`.
They get new hashes and should be re-committed after editing a hook's
`.dart` source. `.mason/bricks.json` also needs a refresh (`rm -rf
.mason mason-lock.json && mason get`) after renaming/adding/removing a
brick, since mason doesn't auto-prune stale entries on its own.
