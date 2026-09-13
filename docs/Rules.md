# Rules — GitHub Watcher

## Naming

- Files: `snake_case.dart`; classes: `PascalCase`; members: `camelCase`
- Constants: `camelCase` in `lib/utils/constants.dart`, no magic literals elsewhere
- Private members: `_` prefix

## State management

- Global settings: `appSettingsController` (`ValueNotifier<AppSettings>`)
- Language/theme reactivity: wrap screen content in
  `ValueListenableBuilder(valueListenable: appSettingsController, ...)`
- Local screen state: `StatefulWidget` + `setState`, nothing else

## Layering

- `models/`: pure immutable data classes with `fromJson`/`toJson`, no Flutter imports
- `services/`: business logic, no widgets; `StorageService` is the only
  SharedPreferences access point
- `screens/`: one screen per file, UI + local state only
- `widgets/`: reusable UI, no business logic
- `workers/`: background isolate entry points only

## Error handling

- User-facing failures: `SnackBar` with an `AppStrings` message
- Non-critical failures: `debugPrint` and continue (per-repo sync isolation)
- Storage corruption: fall back to empty/default values in `StorageService`
- Network: timeouts via `apiTimeout`, one retry for 5xx, anonymous fallback on 401

## Localization

- All user-visible text through `AppStrings` (`stringsFor(languageCode)`)
- `id` is the default; every new string must be added for both languages

## UI

- Material 3, flat cards (elevation 0), radius 8–16 px
- Empty/loading/error states on every data screen
- Shared chips and entrance animations via `lib/widgets/chips.dart` and
  `lib/utils/animations.dart`

## Hygiene

- `flutter analyze` must report zero issues; `flutter test` must stay green
- No dead code, no commented-out blocks, no duplicate constants/files
- Android-only: do not reintroduce platform folders, conditional exports, or `.kts`
  Gradle duplicates
