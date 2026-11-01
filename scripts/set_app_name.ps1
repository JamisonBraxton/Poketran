# Runs after flutter create generates native runner files.
# The identifier is ASCII; the visible name includes an e acute.
$root = Split-Path -Parent $PSScriptRoot
$display = 'Pok' + [char]0x00E9 + 'tran'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$manifest = Join-Path $root 'android/app/src/main/AndroidManifest.xml'
if (Test-Path $manifest) {
  $raw = [System.IO.File]::ReadAllText($manifest)
  $raw = [regex]::Replace($raw, 'android:label="[^"]*"', 'android:label="' + $display + '"')
  [System.IO.File]::WriteAllText($manifest, $raw, $utf8)
  Write-Host ('Android launcher label: ' + $display)
}
$mainCpp = Join-Path $root 'windows/runner/main.cpp'
if (Test-Path $mainCpp) {
  $raw = [System.IO.File]::ReadAllText($mainCpp)
  $raw = $raw.Replace('L"poketran"', 'L"' + $display + '"')
  [System.IO.File]::WriteAllText($mainCpp, $raw, $utf8)
  Write-Host ('Windows window title: ' + $display)
}
