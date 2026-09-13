# Audio V3 — Google Cloud TTS audit

Date: 2026-08-30  
Flutter project root: `E:\mai_an_learning`  
No audio was generated during this audit. Production WAV files were not written.

```
GOOGLE_CLOUD_TTS_STATUS: NOT_READY
GOOGLE_PROJECT_STATUS: MISSING
CREDENTIAL_STATUS: MISSING
TTS_API_STATUS: UNKNOWN (cannot call API without credentials)
PYTHON_PACKAGE_STATUS: INSTALLED (google-cloud-texttospeech 2.37.0)
VI_VOICE_CONFIGURED: NO
JA_VOICE_CONFIGURED: NO
PREVIEW_MANIFEST_STATUS: FOUND (tool/audio_preview_manifest.json, 18 items)
PRODUCTION_WAV_MODIFIED: 0
```

## Determined facts

| Item | Result |
|---|---|
| A. Flutter root | `E:\mai_an_learning` (`pubspec.yaml` name `mai_an_learning`) |
| B. Runtime audio | `lib/core/audio/audio_service.dart` — bundled WAV first, same-language TTS fallback, playbackRate 1.0 |
| C. Production paths | `assets/audio/vi/**`, `assets/audio/ja/**` |
| D. Manifest | `assets/audio/audio_manifest.json` — 913 (505 vi, 408 ja) |
| E. HUMAN_REQUIRED | 150 in `tool/human_audio_inventory.json` |
| F. Preview spec | 18 IDs in `tool/audio_preview_manifest.json` |
| G/H. Python | 3.14.7 |
| I. google-cloud-texttospeech | INSTALLED 2.37.0 |
| J. ADC | no `%APPDATA%\gcloud\application_default_credentials.json` |
| K. GOOGLE_APPLICATION_CREDENTIALS | UNSET |
| L. GOOGLE_CLOUD_PROJECT | UNSET |
| M. TTS API enabled | cannot verify without credentials |
| N. Existing generators | `tool/generate_audio_assets.py` (Piper), `tool/generate_audio_v3.py` (Google Cloud preview, production locked) |
| gcloud CLI | MISSING |
| `tool/.env.audio.v3` | does not exist |

## Preview IDs (existing, not invented)

preview_vi_a, preview_vi_as, preview_vi_ows, preview_vi_bo, preview_vi_co, preview_vi_do, preview_vi_ddo, preview_vi_gioi_lam, preview_vi_dung_roi, preview_vi_thu_lai, preview_ja_h_a, preview_ja_h_i, preview_ja_h_u, preview_ja_h_e, preview_ja_h_o, preview_ja_h_ka, preview_ja_h_ki, preview_ja_jouzu

## Flutter

No Google Cloud dependency in `pubspec.yaml`. AudioService must stay unchanged.

## STOP

Preview generation requires: Google ADC or `GOOGLE_APPLICATION_CREDENTIALS`, `GOOGLE_CLOUD_PROJECT`, and `VI_VOICE_NAME` / `JA_VOICE_NAME` verified against Google `list_voices` — not invented. The Python package is installed. Credentials, project, and voice names are still missing, so generation is stopped.
