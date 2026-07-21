# GitHub Actions — Build iOS IPA unsigned

## Enable Actions first

Repo → **Settings** → **Actions** → **General** → Allow actions → Save

Or open **Actions** tab and click **I understand my workflows, go ahead and enable them**.

## Trigger

- Manual: Actions → **Build iOS IPA unsigned** → Run workflow
- Also runs when this workflow file is pushed to `camaera1.0.1`

No signing secrets required.

## Artifact

`watermark-camera-ipa-unsigned`  
e.g. `watermark_camera-unsigned-<run_number>.ipa`

## Notes

- Built with `flutter build ios --release --no-codesign`, then zipped as Payload IPA
- Cannot install on normal devices or upload to App Store without re-signing
