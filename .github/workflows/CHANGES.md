# Come On 0.2.0 — flowing stage

The home stage now fills the available screen, with the progress line at its vertical midpoint. The right half uses a moving amber gradient and 110 continuously drifting, softly fading particles. A smooth vector character replaces the pixel sprite, with breathing, blinking and a run cycle when progress changes. Task controls open in a bottom sheet. Progress calculations and saved-data format are unchanged. Reduced-motion settings stop stage animation.

## Build status
Source changes are prepared but not compiled or runtime-tested. Local Flutter setup was blocked by automatic security review; GitHub repository writes returned HTTP 403. No changes have been pushed to GitHub.

## Builds
The existing .github/workflows/build.yml produces both Android APK and Windows x64 app files. The Android job now runs analysis and widget tests before compiling. Upload these project contents to the repository root, preserving the .github directory. A push to main starts both jobs. Windows distribution must keep the EXE, DLLs, and data directory together.

The existing APK uses a debug certificate whose private key is not supplied. A newly built APK may not update the old installation. Do not uninstall an existing app with important tasks without preserving its data first.
