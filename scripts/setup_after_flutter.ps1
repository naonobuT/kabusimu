# Flutter インストール後の初期セットアップスクリプト
# 実行方法: .\scripts\setup_after_flutter.ps1
# 前提: C:\flutter\bin が PATH に追加済みであること

Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "=== 1. flutter pub get ===" -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Error "flutter pub get failed"; exit 1 }

Write-Host "`n=== 2. Drift コード生成 ===" -ForegroundColor Cyan
dart run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) { Write-Error "build_runner failed"; exit 1 }

Write-Host "`n=== 3. サンプル株価データ生成 ===" -ForegroundColor Cyan
dart scripts/generate_sample_data.dart
if ($LASTEXITCODE -ne 0) { Write-Error "generate_sample_data failed"; exit 1 }

Write-Host "`n=== 4. ユニットテスト ===" -ForegroundColor Cyan
flutter test test/unit/
if ($LASTEXITCODE -ne 0) { Write-Error "tests failed"; exit 1 }

Write-Host "`n=== 5. 起動確認（iOS Simulator）===" -ForegroundColor Cyan
Write-Host "以下のコマンドでiPad Simulatorで起動してください:" -ForegroundColor Yellow
Write-Host "  flutter run -d 'iPad Pro'"

Write-Host "`n✅ セットアップ完了！" -ForegroundColor Green
