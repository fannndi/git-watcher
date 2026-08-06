# Tasks — GitHub Watcher

## Phase 1: Code Quality (HIGH)
- [ ] Add `copyWith` to WatchedRepo model
- [ ] Make WatchedRepo fields final (immutability)
- [ ] Cache SharedPreferences instance in StorageService
- [ ] Add dartdoc comments to public APIs
- [ ] Fix `DropdownButtonFormField` deprecation (use `value` instead of `initialValue`)

## Phase 2: Test Coverage (HIGH)
- [ ] Unit test: Commit.fromJson() parsing
- [ ] Unit test: AppSettings.fromJson() edge cases
- [ ] Unit test: GitHubCredentials.basicAuth output
- [ ] Unit test: SyncLog.totalCommits calculation
- [ ] Unit test: WatchedRepo.fromJson() with legacy 'full' syncMode
- [ ] Widget test: AddRepoScreen input validation
- [ ] Widget test: HomeScreen FAB visibility at max repos

## Phase 3: Architecture (MEDIUM)
- [ ] Extract dependency injection (GitHubService, StorageService)
- [ ] Add error boundary widget for screens
- [ ] Consider using Provider/Riverpod for DI (optional)

## Phase 4: Features (LOW)
- [ ] Add pull-to-refresh indicator on UpdateScreen
- [ ] Add commit count badge on RepoTile
- [ ] Add "last background sync" info on HomeScreen
