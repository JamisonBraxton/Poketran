#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v flutter >/dev/null || { echo 'Flutter SDK not found in PATH' >&2; exit 1; }
case "$(uname -s)" in
  Darwin) platforms=android,ios,macos ;;
  *) platforms=android,linux ;;
esac
flutter create --project-name poketran --platforms="$platforms" .
# Adjust the Android display name without changing the ASCII package identifier.
python3 - <<'PYSET'
from pathlib import Path
p = Path('android/app/src/main/AndroidManifest.xml')
if p.exists():
    import re
    text = p.read_text(encoding='utf-8')
    p.write_text(re.sub(r'android:label="[^"]*"', 'android:label="Pokétran"', text), encoding='utf-8')
PYSET
flutter pub get
flutter analyze
flutter test
printf '\nSetup complete. Run flutter devices, then flutter run.\n'
