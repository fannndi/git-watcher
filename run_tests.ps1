# run_tests.ps1 — Run all tests for git-watcher
# Usage: .\run_tests.ps1 [-Type "unit|widget|integration|all"]

param(
    [ValidateSet("unit", "widget", "integration", "all")]
    [string]$Type = "all"
)

Write-Host "=== Git Watcher Tests ===" -ForegroundColor Cyan
Write-Host ""

switch ($Type) {
    "unit" {
        Write-Host "Running unit tests..." -ForegroundColor Yellow
        flutter test test/unit/
    }
    "widget" {
        Write-Host "Running widget tests..." -ForegroundColor Yellow
        flutter test test/widget/
    }
    "integration" {
        Write-Host "Running integration tests..." -ForegroundColor Yellow
        flutter test test/integration/
    }
    "all" {
        Write-Host "Running all tests..." -ForegroundColor Yellow
        flutter test
    }
}

Write-Host ""
Write-Host "=== Tests Complete ===" -ForegroundColor Cyan
