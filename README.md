# TerraBite

A cross-platform recipe discovery app built with Flutter. Browse meal categories, search dishes by name, and save personal cooking notes that persist across app restarts. All recipe data is fetched live from [TheMealDB](https://www.themealdb.com).

> **Course project** — DPRG611 Mobile Application Development
> **Domain** — Recipe / Food App
> **Team size** — 3 (Abdelrahman Sherbiny · Hadi Ghareeb · Mohamed Atef)
> **Total marks** — 40

---

## Table of contents

1. [Concept & design philosophy](#concept--design-philosophy)
2. [Feature tour](#feature-tour)
3. [Tech stack](#tech-stack)
4. [Architecture](#architecture)
5. [Folder structure](#folder-structure)
6. [Routing map](#routing-map)
7. [Data layer](#data-layer)
8. [Theming system](#theming-system)
9. [Running the app](#running-the-app)
10. [Rubric coverage](#rubric-coverage)
11. [Team task ownership](#team-task-ownership)
12. [Known limitations](#known-limitations)

---

## Concept & design philosophy

TerraBite is a **dark-themed, tech-forward recipe explorer** that uses a small handful of color-psychology tricks to subtly stimulate appetite without looking like a fast-food clone.

| Element        | Choice                                    | Why                                                                              |
| -------------- | ----------------------------------------- | -------------------------------------------------------------------------------- |
| Background     | Near-black with warm tint (`#0F0D0B`)     | Mimics high-end menu design — food images pop against a dark canvas              |
| Primary accent | Burnt amber / saffron (`#E07A1F`)         | Warm tones (red/orange/yellow) are clinically associated with appetite arousal   |
| Secondary      | Deep paprika (`#9F2D0A`)                  | Reinforces the "warm" palette without leaning red                                 |
| Body font      | **Space Grotesk** (geometric sans)        | Keeps UI chrome feeling modern and technical                                     |
| Display font   | **Fraunces** (serif with curves)          | Curved letterforms read as warm/handcrafted — appetite-cue without being obvious |
| Cards          | Subtle elevated dark surfaces with border | Reduces visual noise so food photography stays the focus                         |

The result feels like a tech product, but the warm palette and serif headings work on the user's subconscious cravings.

---

## Feature tour

### 1. Splash screen
- Animated logo + brand name on app launch
- 2-second `Future.delayed`/`Timer` inside `initState`, then `context.go('/home')`
- No back button after redirect (replaces the route, doesn't push)

### 2. Home — Categories
- `StatefulWidget` with `Drawer`, `AppBar`, refresh action, and a responsive `GridView`
- Live data from `GET /categories.php` displayed via `FutureBuilder`
- `Drawer` mirrors the bottom-nav links and adds an **About** dialog
- Each card is a `Stack` of image + dark gradient overlay + name (hero-style)

### 3. Category meals
- Dynamic `GridView` of every meal in the chosen category
- Live data from `GET /filter.php?c={category}`
- Hot pill chip showing dish count

### 4. Recipe detail
- `SliverAppBar` with parallax hero image (`Stack` overlay)
- `CircleAvatar` for category badge, `Icon` for meta info, `RichText` for ingredient lines
- `ElevatedButton` (Save), `OutlinedButton` (Share — copies to clipboard), `TextButton` (in app bar)
- `TextField` placeholder for notes (links out to the Edit Note form)
- Live data from `GET /lookup.php?i={id}`

### 5. Search
- `StatefulWidget` with `TextField`, **300 ms debounce** via `Timer`
- Cancels stale requests using a request-id counter (no race conditions)
- `dispose()` cancels the debounce timer + disposes controllers
- Empty / loading / error / results states handled separately

### 6. Favorites — full CRUD
- `ListView.builder` of saved recipes from sqflite
- **Read** — `getAllFavorites()` ordered by save date
- **Create** — Save button on detail page (`saveMeal`)
- **Update** — Long-press tile or tap pencil icon → Edit Note form
- **Delete** — `Dismissible` swipe-to-delete with confirmation dialog
- `StreamBuilder` re-renders on every CRUD operation

### 7. Edit note form
- `Form` with `GlobalKey<FormState>` and two `TextFormField`s
- **Title** — required, max 60 chars (enforced by validator + `LengthLimitingTextInputFormatter`)
- **Body** — required, min 10 chars
- `FloatingActionButton.extended` triggers `form.validate()` → `form.save()` → `updateNote()`
- `PopScope` blocks accidental data loss with a discard confirmation dialog
- `SnackBar` confirmation on save

### 8. 404 — unknown route
- Reached via `GoRouter.errorBuilder`
- Friendly recovery button back to home

---

## Tech stack

| Concern             | Choice                                                 |
| ------------------- | ------------------------------------------------------ |
| Framework           | Flutter 3.41.2 (Dart 3.11)                             |
| Routing             | `go_router ^14.6` — declarative + `StatefulShellRoute` |
| HTTP                | `http ^1.2`                                            |
| Local persistence   | `sqflite ^2.4` (mobile) + `sqflite_common_ffi` (desktop) |
| Image cache         | `cached_network_image ^3.4`                            |
| Typography          | `google_fonts ^6.2` — Space Grotesk + Fraunces         |
| Path resolution     | `path` + `path_provider`                               |
| State management    | Built-in `setState` + `InheritedWidget` (no Provider/Riverpod — keeps it course-aligned) |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    main.dart (entry)                         │
│  Initializes services → wraps app in AppScope (Inherited)    │
└────────────────────────────┬────────────────────────────────┘
                             │
              ┌──────────────┴───────────────┐
              ▼                              ▼
   ┌─────────────────────┐         ┌─────────────────────┐
   │   AppScope          │         │   AppRouter         │
   │   (InheritedWidget) │◀────────│   (GoRouter)        │
   │                     │         │                     │
   │   • api             │         │   • routes          │
   │   • favorites       │         │   • ShellRoute      │
   └──────────┬──────────┘         │   • errorBuilder    │
              │                    └──────────┬──────────┘
              │                               │
              ▼                               ▼
   ┌─────────────────────┐         ┌─────────────────────┐
   │   Services          │         │   Screens           │
   │                     │         │                     │
   │   MealApiService    │◀────────│   • Read API via    │
   │   FavoritesRepo     │         │     AppScope.of()   │
   │                     │         │   • Local setState  │
   └──────────┬──────────┘         └──────────┬──────────┘
              │                               │
   ┌──────────▼──────────┐         ┌──────────▼──────────┐
   │   Models            │         │   Widgets           │
   │                     │         │                     │
   │   • MealCategory    │         │   • MealCard        │
   │   • Meal            │         │   • CategoryCard    │
   │   • MealDetail      │         │   • AppDrawer       │
   │   • FavoriteMeal    │         │   • LoadingView     │
   │                     │         │   • ErrorView       │
   └─────────────────────┘         │   • EmptyView       │
                                   └─────────────────────┘
```

**Service injection** uses `InheritedWidget` (`AppScope`). Any widget can call `AppScope.of(context).api` or `.favorites` to access services. This avoids the Provider/Riverpod dependency and keeps the dependency graph tree-explicit.

---

## Folder structure

```
terrabite/
├── lib/
│   ├── main.dart                   # Bootstraps services, builds the app
│   ├── app_scope.dart              # InheritedWidget that exposes services
│   │
│   ├── theme/                      # All visual styling — single source of truth
│   │   ├── app_colors.dart         # Color palette constants
│   │   ├── app_text_styles.dart    # Google Fonts text style presets
│   │   └── app_theme.dart          # ThemeData + reusable BoxDecoration / spacing constants
│   │
│   ├── models/                     # Pure data classes — no Flutter imports
│   │   ├── meal_category.dart      # fromJson + equality + toString
│   │   ├── meal.dart
│   │   ├── meal_detail.dart        # Flattens 20 ingredient/measure pairs from API
│   │   └── favorite_meal.dart      # SQLite-friendly toMap / fromMap
│   │
│   ├── services/                   # External-world boundaries
│   │   ├── meal_api_service.dart                # http + json + timeout + try/catch
│   │   ├── favorites_repository.dart            # Abstract interface + sqflite impl
│   │   └── in_memory_favorites_repository.dart  # Web fallback (sqflite ≠ web)
│   │
│   ├── routing/
│   │   └── app_router.dart         # GoRouter config + named routes + 404
│   │
│   ├── widgets/                    # Reusable UI building blocks
│   │   ├── app_drawer.dart
│   │   ├── meal_card.dart
│   │   ├── category_card.dart      # Stack hero-overlay treatment
│   │   ├── network_image_box.dart  # Wraps cached_network_image
│   │   ├── loading_view.dart
│   │   ├── error_view.dart
│   │   └── empty_view.dart
│   │
│   └── screens/                    # One file per screen — each is a Flutter route target
│       ├── splash_screen.dart
│       ├── main_shell.dart         # BottomNavigationBar wrapper for the 3 tabs
│       ├── home_screen.dart
│       ├── category_meals_screen.dart
│       ├── meal_detail_screen.dart
│       ├── search_screen.dart
│       ├── favorites_screen.dart
│       ├── edit_note_screen.dart
│       └── not_found_screen.dart
│
├── test/
│   └── widget_test.dart            # Smoke test
│
├── android/  ios/  macos/  web/    # Platform shells (auto-managed)
├── pubspec.yaml                    # Dependencies + metadata
└── README.md                       # ← you are here
```

### Naming conventions

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Private classes/widgets: prefixed with `_` (e.g. `_CategoryGrid`)
- Constants live as `static const` on a single sealed-style class (`AppColors._()`)

---

## Routing map

All routes are declared in [`lib/routing/app_router.dart`](lib/routing/app_router.dart):

| Path                  | Name        | Screen                | In bottom nav? | Notes                                         |
| --------------------- | ----------- | --------------------- | -------------- | --------------------------------------------- |
| `/splash`             | `splash`    | `SplashScreen`        | —              | Initial location                              |
| `/home`               | `home`      | `HomeScreen`          | Tab 1          | Inside `StatefulShellBranch`                  |
| `/home/category/:id`  | `category`  | `CategoryMealsScreen` | (sub-route)    | Reads `?name=` query param                    |
| `/search`             | `search`    | `SearchScreen`        | Tab 2          |                                               |
| `/favorites`          | `favorites` | `FavoritesScreen`     | Tab 3          |                                               |
| `/detail/:id`         | `detail`    | `MealDetailScreen`    | full-screen    | Receives optional `Meal` via `extra`          |
| `/edit-note/:id`      | `editNote`  | `EditNoteScreen`      | full-screen    | Form for editing a saved favorite             |
| `*` (unknown)         | —           | `NotFoundScreen`      | —              | Triggered by `GoRouter.errorBuilder`          |

### Argument passing

`Meal` instances are passed from list/grid items into `/detail/:id` via GoRouter's `extra` parameter:

```dart
context.push('/detail/${meal.id}', extra: meal);
```

The detail screen uses the preview to render an immediate placeholder hero image while `MealDetail` is fetched — no flash of empty state.

---

## Data layer

### TheMealDB endpoints used

| Method | Endpoint                          | Service method                  |
| ------ | --------------------------------- | ------------------------------- |
| GET    | `/categories.php`                 | `fetchCategories()`             |
| GET    | `/filter.php?c={category}`        | `fetchMealsByCategory(name)`    |
| GET    | `/search.php?s={query}`           | `searchMealsByName(query)`      |
| GET    | `/lookup.php?i={id}`              | `fetchMealDetail(id)`           |

All requests:
- Use the `http` package
- Have a **10-second timeout** (`TimeoutException` → friendly error)
- Wrap `jsonDecode` in `try/catch` for `FormatException`
- Surface a non-200 status as `MealApiException` with the code

### Local persistence (sqflite)

Schema: a single `favorites` table.

```sql
CREATE TABLE favorites (
  id           TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  thumbnailUrl TEXT NOT NULL,
  category     TEXT NOT NULL,
  area         TEXT NOT NULL,
  noteTitle    TEXT NOT NULL,
  noteBody     TEXT NOT NULL,
  savedAt      TEXT NOT NULL    -- ISO 8601
);
```

The `FavoritesRepository` interface defines:

```dart
Future<void> init();
Future<List<FavoriteMeal>> getAllFavorites();
Future<FavoriteMeal?> getById(String id);
Future<bool> isFavorite(String id);
Future<void> saveMeal(FavoriteMeal meal);
Future<void> updateNote({required String id, required String noteTitle, required String noteBody});
Future<void> deleteMeal(String id);
Stream<List<FavoriteMeal>> watchFavorites();
```

Two implementations live behind this interface:

| Implementation                 | Used on                   | Persistent?     |
| ------------------------------ | ------------------------- | --------------- |
| `SqfliteFavoritesRepository`   | iOS, Android, macOS, etc. | Yes             |
| `InMemoryFavoritesRepository`  | Web (sqflite ≠ web)       | No (in-RAM)     |

`main.dart` picks the right implementation based on `kIsWeb`.

---

## Theming system

Three files under [`lib/theme/`](lib/theme/) own all visual constants:

- **[app_colors.dart](lib/theme/app_colors.dart)** — single source of truth for color tokens. No screen ever uses a raw hex literal.
- **[app_text_styles.dart](lib/theme/app_text_styles.dart)** — `TextStyle` presets keyed by semantic role (`display`, `heading`, `body`, `caption`, …). Built on Google Fonts.
- **[app_theme.dart](lib/theme/app_theme.dart)** — assembles a `ThemeData` for `MaterialApp.theme`, plus reusable `BoxDecoration` presets and spacing constants (`spaceXs`, `spaceMd`, …).

Anything visual — buttons, cards, inputs, snackbars, drawer — is themed once in `AppTheme.build()`. Screens consume the theme; they don't override it.

---

## Running the app

> **Prerequisite** — Flutter SDK 3.41+ and Dart 3.11+

```bash
cd terrabite
flutter pub get
```

### Chrome (web) — fastest, no extra setup

```bash
flutter run -d chrome
```

> Favorites won't persist on Chrome — uses the in-memory fallback.

### macOS desktop — full persistence

Requires CocoaPods:

```bash
sudo gem install cocoapods
flutter run -d macos
```

### iOS Simulator

```bash
flutter run -d "iPhone 15"   # or whatever simulator name
```

### Android emulator

```bash
flutter run -d emulator-5554   # or whatever emulator id
```

### Verifying the codebase

```bash
flutter analyze        # → No issues found!
flutter test           # → All tests passed!
```

---

## Rubric coverage

| # | Component                  | Marks         | Status | Where it lives                                                    |
| - | -------------------------- | ------------- | ------ | ----------------------------------------------------------------- |
| 1 | UI Design & Responsiveness | 6             | Done   | `lib/theme/`, `lib/screens/`, `lib/widgets/`                      |
| 2 | Core Flutter Features      | 8             | Done   | StatefulWidgets in Home/Search/Detail/EditNote, GoRouter, Splash  |
| 3 | External API Integration   | 10            | Done   | `meal_api_service.dart`, `models/*.dart`, `FutureBuilder` in screens |
| 4 | Data Persistence & CRUD    | 8             | Done   | `favorites_repository.dart`, `favorites_screen.dart`, `edit_note_screen.dart` |
| 5 | Code Quality               | 4             | Done   | Modular folders, no dead code, `flutter analyze` clean            |
| 6 | Discussion & Demo          | 4             | —      | Live presentation                                                 |
| + | Bonus: search query        | +bonus        | Done   | `searchMealsByName()` + `search_screen.dart` (300ms debounce)     |
|   | **Total target**           | **40 + bonus** |        |                                                                   |

### Detailed checklist

**UI & widgets** — `Scaffold`, `AppBar`, `FloatingActionButton`, `Drawer`, `BottomNavigationBar`, `Text`, `Image` (via `cached_network_image`), `CircleAvatar`, `Icon`, `ElevatedButton` / `OutlinedButton` / `TextButton`, `RichText`, `TextField`, `Column`, `Row`, `Container`, `Expanded`, `Stack`, `SafeArea`, `ListView.builder`, `GridView`, `BoxDecoration`, `Card`-styled containers — **all present**.

**State management** — Home, Search, Detail, and EditNote are `StatefulWidget`s; Search uses `dispose()` to cancel its debounce timer, EditNote uses `dispose()` on its controllers.

**Navigation** — GoRouter with named routes, splash redirect, argument passing via `extra`, sub-routes for category drilldown, and a 404 fallback.

**Forms & async** — Edit Note has a `Form` keyed by `GlobalKey<FormState>`, two validated `TextFormField`s, and uses `async`/`await` for storage. Multiple `FutureBuilder`s across screens.

**External API** — `http` GET, `jsonDecode` → `fromJson` constructors, `FutureBuilder` for loading/error/data, friendly error messages with retry. Bonus search bar with debounce.

**Persistence & CRUD** — sqflite with full Create/Read/Update/Delete. `Dismissible` swipe-to-delete, edit-note flow, `SnackBar` confirmations. Survives full app restart.

---

## Team task ownership

Per the supervisor-approved task distribution:

### Abdelrahman Sherbiny — UI/UX & Navigation Lead (~14 marks)
- All files in `lib/theme/`
- `lib/widgets/app_drawer.dart`, `category_card.dart`, `meal_card.dart`, `network_image_box.dart`, error/loading/empty views
- `lib/screens/splash_screen.dart`, `main_shell.dart`, `home_screen.dart`, `category_meals_screen.dart`, `not_found_screen.dart`
- `lib/routing/app_router.dart`

### Hadi Ghareeb — API Integration & State Management Lead (~14 marks)
- `lib/services/meal_api_service.dart`
- `lib/models/meal_category.dart`, `meal.dart`, `meal_detail.dart`
- `lib/screens/search_screen.dart`, `meal_detail_screen.dart`
- StatefulWidget lifecycle / `FutureBuilder` integration across screens

### Mohamed Atef — Data Persistence, Forms & Code Quality Lead (~12 marks)
- `lib/services/favorites_repository.dart` + `in_memory_favorites_repository.dart`
- `lib/models/favorite_meal.dart`
- `lib/screens/favorites_screen.dart`, `edit_note_screen.dart`
- `lib/app_scope.dart` (service injection)
- `lib/main.dart` (composition root)
- Code quality pass + `flutter analyze` enforcement

### Shared
- Live demo & discussion (4 marks)
- Integration testing
- Git workflow

---

## Known limitations

- **Web persistence**: sqflite has no web implementation, so favorites are kept in memory on Chrome and lost on refresh. Run on macOS/iOS/Android for persistent storage.
- **Share button**: copies a recipe summary to the clipboard rather than invoking a native share sheet (would require the `share_plus` plugin).
- **Offline mode**: API calls require network; no offline cache for recipes themselves (only images, via `cached_network_image`).
- **Authentication**: TheMealDB's free v1 API is unauthenticated, so there is no login flow.

---

## License & attribution

Recipe data: [TheMealDB](https://www.themealdb.com) (free to use under their terms).
Fonts: Space Grotesk (Florian Karsten) and Fraunces (Undercase Type) — both via Google Fonts under the Open Font License.
