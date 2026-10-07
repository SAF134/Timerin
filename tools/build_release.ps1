<#
.SYNOPSIS
    Skrip Otomasi Build Release APK dan Perhitungan Checksum SHA-256 untuk Timerin.

.DESCRIPTION
    Skrip ini memvalidasi kualitas kode, menjalankan analisis lint, unit test,
    membangun APK release (universal dan/atau split per ABI), serta menghitung
    checksum SHA-256 untuk setiap berkas APK yang dihasilkan sesuai NFR-008 dan docs/04-SECURITY.md.

.PARAMETER SplitPerAbi
    Jika diaktifkan, membagi build per arsitektur CPU (arm64-v8a, armeabi-v7a, x86_64)
    untuk meminimalkan ukuran file (< 30 MB per NFR-008).

.PARAMETER SkipTests
    Lewati langkah flutter test (tidak disarankan untuk rilis produksi).

.EXAMPLE
    .\tools\build_release.ps1
    .\tools\build_release.ps1 -SplitPerAbi
#>

[CmdletBinding()]
param (
    [switch]$SplitPerAbi = $true,
    [switch]$SkipTests = $false,
    [switch]$Clean = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "           TIMERIN RELEASE BUILD & SHA-256 AUDIT             " -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan

$projectRoot = Resolve-Path "$PSScriptRoot\.."
Set-Location $projectRoot

# 1. Cek Konfigurasi Signing
$keyPropertiesPath = Join-Path $projectRoot "android\key.properties"
if (Test-Path $keyPropertiesPath) {
    Write-Host "[OK] android/key.properties ditemukan. Build akan ditandatangani dengan keystore rilis resmi." -ForegroundColor Green
} else {
    Write-Host "[PERINGATAN] android/key.properties TIDAK ditemukan." -ForegroundColor Yellow
    Write-Host "             Build akan menggunakan fallback debug signing." -ForegroundColor Yellow
    Write-Host "             Untuk distribusi rilis publik resmi, salin android/key.properties.example" -ForegroundColor Yellow
    Write-Host "             menjadi android/key.properties dan arahkan ke keystore rilis Anda." -ForegroundColor Yellow
}

# 2. Opsional: Flutter Clean
if ($Clean) {
    Write-Host "`n[1/5] Menjalankan flutter clean..." -ForegroundColor Cyan
    flutter clean
}

# 3. Flutter Pub Get
Write-Host "`n[2/5] Mengambil dependensi (flutter pub get)..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "flutter pub get gagal!"
}

# 4. Analisis Kode & Pengujian
Write-Host "`n[3/5] Memvalidasi kode (flutter analyze)..." -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Error "flutter analyze mendeteksi issue! Perbaiki sebelum rilis."
}

if (-not $SkipTests) {
    Write-Host "`n[4/5] Menjalankan test suite (flutter test)..." -ForegroundColor Cyan
    flutter test
    if ($LASTEXITCODE -ne 0) {
        Write-Error "flutter test gagal! Rilis dibatalkan."
    }
} else {
    Write-Host "`n[4/5] Melewati flutter test (-SkipTests aktif)..." -ForegroundColor Yellow
}

# 5. Build Release APK
Write-Host "`n[5/5] Membangun APK Release..." -ForegroundColor Cyan
if ($SplitPerAbi) {
    Write-Host "Target: Split per-ABI (NFR-008: ukuran minimal per arsitektur)..." -ForegroundColor Gray
    flutter build apk --release --split-per-abi
} else {
    Write-Host "Target: Universal Fat APK..." -ForegroundColor Gray
    flutter build apk --release
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build APK gagal!"
}

# 6. Hasil & SHA-256 Checksum
Write-Host "`n=============================================================" -ForegroundColor Green
Write-Host "                   RINGKASAN BUILD & CHECKSUM                " -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green

$apkDir = Join-Path $projectRoot "build\app\outputs\flutter-apk"
$apkFiles = Get-ChildItem -Path $apkDir -Filter "*.apk" | Where-Object { $_.Name -like "*release*" }

if ($apkFiles.Count -eq 0) {
    Write-Error "Tidak ditemukan file APK rilis di $apkDir"
}

$results = @()

foreach ($apk in $apkFiles) {
    $hashResult = Get-FileHash -Path $apk.FullName -Algorithm SHA256
    $sizeMb = [math]::Round($apk.Length / 1MB, 2)
    $isNfrPass = if ($sizeMb -lt 30.0) { "LULUS (< 30 MB)" } else { "LEBIH (>= 30 MB)" }

    $results += [PSCustomObject]@{
        "Nama File"    = $apk.Name
        "Ukuran (MB)"  = "$sizeMb MB"
        "NFR-008"      = $isNfrPass
        "SHA-256 Hash" = $hashResult.Hash
    }
}

$results | Format-Table -AutoSize -Wrap

# Tulis checksum ke file sha256_checksums.txt untuk rilis
$checksumFile = Join-Path $projectRoot "build\app\outputs\flutter-apk\sha256_checksums.txt"
$results | Out-File -FilePath $checksumFile -Encoding utf8
Write-Host "Checksum tersimpan di: $checksumFile" -ForegroundColor Cyan

Write-Host "`nSelesai! APK siap untuk diunggah ke Google Drive dan didistribusikan." -ForegroundColor Green
