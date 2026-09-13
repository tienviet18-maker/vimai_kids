# Dev audio pipeline — ViMai Kids

Production learning audio is **bundled WAV** generated at development time.
Piper models stay in `tool/.cache` and must **not** be copied into the APK.

## Voices

| Language | Engine | Model | License |
|---|---|---|---|
| Vietnamese | Piper | `vi_VN-vais1000-medium` | CC BY 4.0 |
| Japanese | Piper Plus (preferred) | Tsukuyomi-chan | Tsukuyomi-chan corpus terms (credit required) |
| Japanese | Windows SAPI `ja-JP` (build-time fallback) | Installed Japanese voice | Microsoft / OS voice used only to bake WAV files |

## Generate

Full rebuild (rarely needed):

```bash
python tool/build_content_and_audio_jobs.py
python tool/generate_audio_assets.py
python tool/check_audio_assets.py
python tool/audit_audio_ux.py
```

Replace only Vietnamese clips marked `NEEDS_REPLACEMENT` / `too_fast_or_short` / `praise_too_fast` in `tool/audio_inventory.json` (does **not** rewrite VALID files or Japanese audio, does **not** rebuild content JSON):

```bash
python tool/audit_audio_ux.py
python tool/generate_audio_assets.py --replace-invalid-vi
python tool/check_audio_assets.py
python tool/audit_audio_ux.py
```

`--replace-invalid-vi` prints the replacement count first and refuses to run if that count is 913.

`--force-vi` still exists but overwrites every Vietnamese WAV. Prefer `--replace-invalid-vi` for UX hotfixes.

`generate_audio_assets.py` will:

1. Rebuild Vietnamese JSON + audio job list
2. Download Piper (Windows/Linux) into `tool/.cache/piper` if needed
3. Download the Vietnamese ONNX voice
4. Install/download Piper Plus Tsukuyomi-chan into `tool/.cache/piper-plus-models`
5. Synthesize every clip, trim silence, peak-normalize, save stable filenames.
   Japanese: try Piper Plus Tsukuyomi-chan, then official Piper `ja_JA-hi_fi_captain-medium`.
   If those engines cannot run on this machine (Python 3.14 / phoneme errors), bake WAV with the installed Windows `ja-JP` voice. Runtime still plays the bundled file only.
6. Write `assets/audio/audio_manifest.json`
7. Exit non-zero if any clip is missing

No API keys are required. Do not commit `tool/.cache`.

## Validate before release

```bash
python tool/check_audio_assets.py
flutter test
flutter build web
flutter build apk
```

Android Gradle `preBuild` also runs the Python checker. A missing WAV fails the release build.

## Runtime contract

`AudioService` plays **bundled WAV first**, then same-language `flutter_tts` only if no asset exists
and a matching-language voice is installed. Vietnamese never falls back to Japanese (or the reverse).

Device TTS is **not** human-quality pronunciation. There are **no human recordings** in this
repository (`HUMAN_AUDIO_BLOCKED`). See `tool/human_audio_inventory.json`.

Do not claim Piper, SAPI, or flutter_tts is a human voice.

## Audio V3 (Google Cloud TTS — preview only)

The Flutter app never calls Google Cloud TTS. Children play bundled WAV via `AudioService`.

Provider: Google Cloud Text-to-Speech via `google-cloud-texttospeech` and Application Default Credentials.

1. Copy `tool/.env.audio.v3.example` to `tool/.env.audio.v3` (do not commit).
2. Set `GOOGLE_CLOUD_PROJECT`, ADC (`GOOGLE_APPLICATION_CREDENTIALS` or `gcloud auth application-default login`), and real `VI_VOICE_NAME` / `JA_VOICE_NAME` from `list_voices`. Do not invent voice IDs.
3. Preview writes only under `tool/audio_v3_preview/` (18 existing IDs). Production `assets/audio/**` is never written.

```bash
python -m pip install -r tool/requirements-audio-v3.txt
python tool/generate_audio_v3.py --preview
```

If credentials or voices are missing, the generator STOPS and writes no WAV.

4. Listen using `tool/audio_v3_manual_qa.md`. Google Cloud TTS is still synthetic speech.
5. Production replacement of the 150 HUMAN_REQUIRED IDs stays locked until explicit approval.

Do not use `--force-vi`. Do not regenerate 913 files. Label: **PREMIUM_AI_VOICE**, never HUMAN_RECORDING.
