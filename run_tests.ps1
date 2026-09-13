# run_tests.ps1 — quality gates for GitHub Watcher
# Usage: .\run_tests.ps1 [-Type "unit|widget|integration|all"]

param(
    [ValidateSet("unit", "widget", "integration", "all")]
    [string]$Type = "all"
)

Write-Host "=== GitHub Watcher Quality Gates ===" -ForegroundColor Cyan

Write-Host "flutter analyze" -ForegroundColor Yellow
flutter analyze

switch ($Type) {
    "unit" { flutter test test/unit/ }
    "widget" { flutter test test/widget/ }
    "integration" { flutter test test/integration/ }
    "all" { flutter test }
}

Write-Host "=== Done ===" -ForegroundColor Cyan
