# Flutterセットアップスクリプト
# flutter.zip がホームフォルダにある前提で実行（ダウンロード先）

# flutter.zip の場所を探す（ホームフォルダ優先、なければ Downloads）
$zip = "$env:USERPROFILE\flutter.zip"
if (-not (Test-Path $zip)) {
    $zip = "$env:USERPROFILE\Downloads\flutter.zip"
}
if (-not (Test-Path $zip)) {
    Write-Error "flutter.zip が見つかりません。$env:USERPROFILE か Downloads に配置してください"
    exit 1
}
$dest = "C:\"

Write-Host "=== Flutter展開中 ==="
Expand-Archive -Path $zip -DestinationPath $dest -Force
Write-Host "展開完了: C:\flutter"

Write-Host "=== PATH設定 ==="
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*C:\flutter\bin*") {
    [System.Environment]::SetEnvironmentVariable(
        "PATH",
        "$currentPath;C:\flutter\bin",
        "User"
    )
    Write-Host "PATHに C:\flutter\bin を追加しました"
} else {
    Write-Host "PATHに既に登録されています"
}

$env:PATH = "$env:PATH;C:\flutter\bin"

Write-Host "=== Flutter doctor ==="
C:\flutter\bin\flutter.bat doctor

Write-Host ""
Write-Host "=== セットアップ完了 ==="
Write-Host "新しいターミナルを開いて以下を実行してください:"
Write-Host "  cd D:\programing-practice\stock_simulator_kids"
Write-Host "  flutter pub get"
Write-Host "  dart run build_runner build --delete-conflicting-outputs"
Write-Host "  flutter run"
