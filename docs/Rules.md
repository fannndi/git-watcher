# Rules — GitHub Watcher

## Naming Conventions
- **Files:** snake_case (`home_screen.dart`, `github_service.dart`)
- **Classes:** PascalCase (`HomeScreen`, `GitHubService`)
- **Variables:** camelCase (`_isLoading`, `lastSyncAt`)
- **Constants:** camelCase (`maxWatchedRepos`, `githubBaseUrl`)
- **Private:** underscore prefix (`_controller`, `_repos`)

## State Management
- Global: `AppSettingsController` (ValueNotifier singleton)
- Local: `StatefulWidget` + `setState()`
- Reactive: `ValueListenableBuilder` for settings changes

## Error Handling
- try-catch with user-facing SnackBar messages
- Non-fatal errors: debugPrint + continue
- Background errors: return false for retry
- Storage errors: fallback to defaults

## File Organization
- Models: pure data classes with fromJson/toJson
- Services: business logic, no UI
- Screens: full-page widgets with state
- Widgets: reusable UI components
- Workers: background isolate entry points

## Platform Pattern
- Interface: `notification_service.dart` (conditional export)
- Mobile: `notification_service_mobile.dart`
- Stub: `notification_service_stub.dart`

## Localization
- `AppStrings` class with language code constructor
- `stringsFor(code)` factory function
- Indonesian (id) default, English (en) optional

## UI Patterns
- Material Design 3 with flat cards (elevation: 0)
- Border radius: 14-16px for cards
- Consistent colorScheme usage
- Empty states with icon + title + subtitle
- Loading states with CircularProgressIndicator
- Error states with retry button
