# Copy ic_launcher_round.png into Android mipmap folders as ic_launcher.png and ic_launcher_round.png
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
$src = Join-Path $projectRoot "assets\images\ic_launcher_round.png"
if (-not (Test-Path $src)) {
  Write-Error "Source icon not found: $src"
  exit 1
}
$mipmaps = @(
  "android\app\src\main\res\mipmap-mdpi",
  "android\app\src\main\res\mipmap-hdpi",
  "android\app\src\main\res\mipmap-xhdpi",
  "android\app\src\main\res\mipmap-xxhdpi",
  "android\app\src\main\res\mipmap-xxxhdpi"
)
foreach ($m in $mipmaps) {
  $full = Join-Path $projectRoot $m
  if (-not (Test-Path $full)) {
    Write-Output "Skipping missing folder: $full"
    continue
  }
  Copy-Item -Path $src -Destination (Join-Path $full "ic_launcher.png") -Force
  Copy-Item -Path $src -Destination (Join-Path $full "ic_launcher_round.png") -Force
  Write-Output "Copied icons to $full"
}
Write-Output "Done. Uninstall the app from device/emulator and reinstall to see changes."