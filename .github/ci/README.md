# Penguin Wars Android CI signing

This folder contains the **public development-only** signing identity used for GitHub Actions debug APKs.

It is intentionally not a release/store key.

Purpose:
- every cloud debug APK is signed with the same certificate;
- a newer GitHub Actions debug APK can replace an older cloud debug APK on a test phone without uninstalling first;
- CI does not depend on hidden runner state, caches, or machine-specific keystores.

Never use this key for:
- Google Play
- release builds
- production distribution
- any package whose signing identity must be secret

Debug signing identity:
- alias: `androiddebugkey`
- store/key password: `android`
- SHA-256 certificate fingerprint:
  `0D:26:1E:DD:FE:5B:A7:A4:D0:0C:6D:21:EA:28:D1:C2:B4:C5:B1:E0:08:83:36:68:33:12:65:8E:84:BC:A1:BE`

The workflow decodes `android-debug.keystore.b64` into the runner's temporary directory and verifies this fingerprint before export. A mismatch fails the build.

If Penguin Wars ever moves to store/release signing, create a separate secret release keystore and a separate release workflow. Do not modify this debug identity into a release key.
