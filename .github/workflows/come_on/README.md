# Come On — Android and Windows build source

This archive contains corrected source and build automation, not compiled binaries.
The Dart files are now in the root lib/ folder required by Flutter.

## Build in GitHub Actions
1. Create a GitHub repository and upload the CONTENTS of this folder at its root, including .github/workflows/build.yml.
2. Open Actions and enable workflows if prompted.
3. Choose "Build Come On (Android APK & Windows EXE)", then "Run workflow". A push to main/master also starts builds.
4. After both jobs succeed, download the artifacts at the bottom of the workflow run:
   - come_on-android-apk: unzip and install app-release.apk.
   - come_on-windows-x64: unzip and run come_on.exe. Keep all DLLs and the data folder alongside it.

## Local Windows build
Install Flutter 3.24.5, Android SDK / Android Studio and Visual Studio with the Desktop development with C++ workload. Run flutter doctor, resolve its Android/Windows requirements and accept Android SDK licences with flutter doctor --android-licenses. Run build_all.bat.

## Local Android build (Linux/macOS)
Install Flutter 3.24.5, JDK 17 and Android SDK, resolve flutter doctor requirements, then run bash build_apk.sh.

Generated platform runners use Flutter's default application identifier and Android release signing configuration. Set your own identifier and permanent release keystore before store publication or long-term update distribution. Preserve that keystore for subsequent updates.

Builds were not executed in the preparation environment because Flutter/Android SDKs and a Windows compiler were unavailable. Workflow runs require network access to SDKs, dependencies and GitHub Actions.
