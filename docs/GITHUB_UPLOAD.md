# Publish Pokétran to a new GitHub repository

**The repository must exist before any upload.** Create a new repository named `Poketran` at https://github.com/new under the intended GitHub account. Leave the README, .gitignore, and license creation options unchecked; they are already in this project (or are intentionally not included). Initial visibility is your choice. For instructor review, use a public repository or explicitly add the instructor as a collaborator.

## What belongs in GitHub

Upload the project contents **inside** the `Poketran` folder at the repository root (not the ZIP as one file):

- `.github/workflows/flutter.yml`: Flutter analysis, tests, and Android release APK CI.
- `.gitignore`, `pubspec.yaml`, `analysis_options.yaml`: app configuration.
- `lib/`: the Flutter/Dart app source.
- `test/`: automated tests.
- `scripts/`, `setup_windows.bat`, `build_android_apk.bat`: developer setup/build helpers.
- `README.md`, `AI_FEATURE.md`, `AI_Usage_Log.md`, `docs/`: documentation and evidence templates.

Do **not** upload generated build output, passwords/API keys, `.dart_tool`, `.gradle`, `local.properties`, or your personal emulator files. The `.gitignore` protects against common generated files.

## Option A — upload using Git on Windows

Open PowerShell in the extracted `Poketran` folder, after creating the empty remote repository:

```powershell
git init
git branch -M main
git add .
git commit -m "Add initial Poketran Flutter source and tests"
git remote add origin https://github.com/JamisonBraxton/Poketran.git
git push -u origin main
```

If you already have a Git repository in the folder, skip `git init` and use `git status` to confirm what is staged. If the remote already exists, use `git remote -v` rather than re-adding it.

## Option B — GitHub website

Open the new, empty GitHub repository. Choose **Add file > Upload files**, then upload the project folder's **contents**, keeping the subfolders. Confirm dotfiles like `.gitignore` and `.github/workflows/flutter.yml` are included. Commit once. Do not submit the ZIP archive as the only repository file.

## Verify the repository

Confirm these paths exist:

- `lib/main.dart`
- `lib/data/database_service.dart`
- `test/database_test.dart`
- `AI_FEATURE.md`
- `.github/workflows/flutter.yml`

GitHub's **Actions** tab runs the workflow on pushes to `main`. After it succeeds, open the workflow run's **Artifacts** section to download `poketran-android-release`. GitHub artifacts are ZIP files; extract the APK from the artifact before installing it. The workflow is a setup/checking convenience, **not evidence of two-device emulator testing**.

If CI fails, inspect the exact error and fix the app locally before claiming the APK works. The repository source package has not been compiled or tested by the authoring environment.

## Academic project evidence

A single bulk upload does **not** satisfy the assignment's minimum 20 meaningful commits per person, feature branch, pull request, or ClickUp evidence requirements. Do not fabricate these: continue authentic, documented development, testing, review, and improvements. The repository also does not replace each student's final iCollege submission.
