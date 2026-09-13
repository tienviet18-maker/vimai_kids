# Audio V3 Google Cloud preview report

This is PREVIEW ONLY.
No production WAV was modified.

Google Cloud TTS is synthetic speech (premium neural TTS).
It is not a human recording. Do not call this native human audio.

```
AUDIO_V3_GOOGLE_STATUS

Provider:
Google Cloud Text-to-Speech

Project:
MISSING

Credentials:
MISSING

VI Voice:
MISSING

JA Voice:
MISSING

Preview Manifest:
FOUND

Ready for preview:
NO

Reason:
Google Application Default Credentials not found (no GOOGLE_APPLICATION_CREDENTIALS file and no gcloud ADC); GOOGLE_CLOUD_PROJECT is unset; VI_VOICE_NAME is empty (will not invent a Google voice ID); JA_VOICE_NAME is empty (will not invent a Google voice ID)

Production WAV modified:
0
```

Provider: Google Cloud Text-to-Speech
Project: MISSING
Model: configuration-driven (not invented); unused until voices are set
VI Voice: (empty)
JA Voice: (empty)
Preview Manifest: tool/audio_preview_manifest.json (exactly 18 items)
Preview output root: tool/audio_v3_preview/ (never assets/audio/)
Preview generated: 0/18

TECHNICAL_QA: NOT_RUN
MANUAL_LISTENING_QA: NOT_RUN
READY_FOR_MANUAL_QA: NO
Detected issues: Google Cloud credentials/project/voice IDs missing — generation STOPPED
PRODUCTION_WAV_SAFETY_CHECK: PASS
Production WAV modified: 0
Production generation executed: NO

Configuration source: tool/audio_generation/google_tts_config.json + env

Audio was not generated because Google Cloud TTS is not ready.
Do not invent voice IDs. Do not fall back to Piper/SAPI for this preview.
