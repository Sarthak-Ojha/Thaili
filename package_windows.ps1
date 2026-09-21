<#
.SYNOPSIS
    Automated packaging script for Thaili Windows Release.

.DESCRIPTION
    1. Runs automated tests (flutter test).
    2. Compiles production release binary (flutter build windows --release).
    3. Bundles full release folder into dist/Thaili-v<version>-Windows-Portable.zip.
    4. Compiles Inno Setup installer into dist/ThailiSetup-v<version>.exe (if Inno Setup is installed).

.EXAMPLE
    .\package_windows.ps1
    .\package_windows.ps1 -SkipTests
#>

param (
    [switch]$SkipTests = $false
)

$ErrorActionPreference = "Stop"

$appVersion = "1.0.0"
$buildDir = "$PSScriptRoot\build\windows\x64\runner\Release"
$distDir = "$PSScriptRoot\dist"

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   Thaili - Windows Free Release Packaging Script     " -ForegroundColor Cyan
Write-Host "=======================================================`n" -ForegroundColor Cyan

# 1. Run Unit/Widget Tests
if (-not $SkipTests) {
    Write-Host "[1/4] Running automated test suite..." -ForegroundColor Yellow
    flutter test
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Tests failed! Aborting release packaging." -ForegroundColor Red
        exit 1
    }
    Write-Host "All tests passed cleanly!`n" -ForegroundColor Green
} else {
    Write-Host "[1/4] Skipping tests (-SkipTests specified).`n" -ForegroundColor DarkGray
}

# 2. Build Release Windows Binary
Write-Host "[2/4] Compiling Flutter Windows release binary..." -ForegroundColor Yellow

# Ensure no existing instance is holding a lock on the output binary
$existing = Get-Process -Name thaili -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Closing running instance(s) of Thaili before build..." -ForegroundColor DarkYellow
    Stop-Process -Name thaili -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build windows failed!" -ForegroundColor Red
    exit 1
}
Write-Host "Windows release build succeeded!`n" -ForegroundColor Green

# 3. Create dist/ directory and Portable ZIP
Write-Host "[3/4] Packaging portable ZIP distribution..." -ForegroundColor Yellow
if (-not (Test-Path -Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}

$zipFileName = "Thaili-v$appVersion-Windows-Portable.zip"
$zipFilePath = Join-Path $distDir $zipFileName

if (Test-Path -Path $zipFilePath) {
    Remove-Item -Path $zipFilePath -Force
}

if (Test-Path -Path "$PSScriptRoot\dist_docs\HOW_TO_RUN_WINDOWS.txt") {
    Copy-Item -Path "$PSScriptRoot\dist_docs\HOW_TO_RUN_WINDOWS.txt" -Destination "$buildDir\HOW_TO_RUN.txt" -Force
}

Compress-Archive -Path "$buildDir\*" -DestinationPath $zipFilePath -CompressionLevel Optimal
$zipItem = Get-Item $zipFilePath
$zipSizeMb = [math]::Round($zipItem.Length / 1MB, 2)
Write-Host "Portable ZIP created: $zipFilePath ($zipSizeMb MB)`n" -ForegroundColor Green

# 4. Check for Inno Setup compiler to create Windows installer
Write-Host "[4/4] Checking for Inno Setup compiler (iscc.exe)..." -ForegroundColor Yellow
$isccPath = $null
$possiblePaths = @(
    "iscc",
    "${env:ProgramFiles(x86)}\Inno Setup 6\iscc.exe",
    "${env:ProgramFiles}\Inno Setup 6\iscc.exe",
    "${env:LocalAppData}\Programs\Inno Setup 6\iscc.exe"
)

foreach ($path in $possiblePaths) {
    try {
        $cmd = Get-Command $path -ErrorAction SilentlyContinue
        if ($cmd) {
            $isccPath = $cmd.Source
            break
        } elseif (Test-Path -Path $path) {
            $isccPath = $path
            break
        }
    } catch {}
}

if ($isccPath) {
    Write-Host "Found Inno Setup at: $isccPath" -ForegroundColor Green
    Write-Host "Compiling setup installer..." -ForegroundColor Yellow
    & $isccPath "$PSScriptRoot\windows_installer.iss"
    if ($LASTEXITCODE -eq 0) {
        $setupExe = Join-Path $distDir "ThailiSetup-v$appVersion.exe"
        if (Test-Path $setupExe) {
            $setupItem = Get-Item $setupExe
            $setupSizeMb = [math]::Round($setupItem.Length / 1MB, 2)
            Write-Host "Installer created: $setupExe ($setupSizeMb MB)`n" -ForegroundColor Green
        }
    }
} else {
    Write-Host "Inno Setup compiler (iscc.exe) not found." -ForegroundColor DarkYellow
    Write-Host "   -> You can install Inno Setup for free from: https://jrsoftware.org/isinfo.php" -ForegroundColor DarkGray
    Write-Host "   -> Or run: winget install JRSoftware.InnoSetup" -ForegroundColor DarkGray
    Write-Host "   -> Portable ZIP package is already ready for distribution!`n" -ForegroundColor Cyan
}

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "   RELEASE ARTIFACTS READY IN dist/                   " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Get-ChildItem $distDir | Select-Object Name, @{Name="Size(MB)";Expression={[math]::Round($_.Length/1MB, 2)}}, LastWriteTime | Format-Table -AutoSize
