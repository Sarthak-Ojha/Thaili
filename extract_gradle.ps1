$hash = '9ot9r568e8zfvvd4mn8rbu1j0'
$dir = Join-Path $env:USERPROFILE ".gradle\wrapper\dists\gradle-9.3.1-all\$hash"
$zipPath = Join-Path $dir "gradle-9.3.1-all.zip"
$okFile = Join-Path $dir "gradle-9.3.1-all.zip.ok"

Remove-Item $okFile -Force -ErrorAction SilentlyContinue

Write-Host "Unzipping Gradle 9.3.1 into $dir..."
Expand-Archive -Path $zipPath -DestinationPath $dir -Force

New-Item -Path $okFile -ItemType File -Force | Out-Null
Write-Host "Unzipped successfully! Content:"
Get-ChildItem -Path $dir
