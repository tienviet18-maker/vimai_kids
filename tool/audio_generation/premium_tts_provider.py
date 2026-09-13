"""Premium TTS adapters.

Only documented provider APIs are used:
- OpenAI Audio Speech: POST /v1/audio/speech
- ElevenLabs: POST /v1/text-to-speech/{voice_id}

Revid is not wired: no MCP tools and no documented endpoint were available.
Do not invent a Revid URL. Use VIMAI_AUDIO_V3_API_BASE for a custom HTTP provider.
"""
from __future__ import annotations

import json
import urllib.error
import urllib.request
from pathlib import Path

from .audio_postprocess import measure_wav, postprocess_wav
from .provider_base import GenerateResult, ProviderConfigError, TtsProvider, utc_now
from .provider_config import ProviderSettings, load_settings


def _speed_to_openai(speed: float) -> float:
    return max(0.25, min(4.0, float(speed)))


class UnconfiguredProvider(TtsProvider):
    def generate(self, text, language, voice_profile, output_path, *, voice_id):
        raise ProviderConfigError(
            "Premium TTS provider is not configured. "
            "Set VIMAI_AUDIO_V3_PROVIDER, VIMAI_AUDIO_V3_API_KEY, "
            "VIMAI_AUDIO_V3_VI_VOICE_ID, VIMAI_AUDIO_V3_JA_VOICE_ID. "
            "Revid MCP/API is not available in this environment. Voice IDs discovered: none."
        )


class OpenAiTtsProvider(TtsProvider):
    """https://platform.openai.com/docs/api-reference/audio/createSpeech"""

    def __init__(self, settings: ProviderSettings):
        self.settings = settings

    def generate(self, text, language, voice_profile, output_path, *, voice_id):
        base = self.settings.api_base or "https://api.openai.com/v1/audio/speech"
        body = {
            "model": self.settings.openai_model,
            "input": text,
            "voice": voice_id,
            "response_format": "wav",
            "speed": _speed_to_openai(voice_profile.get("speed", 1.0)),
        }
        req = urllib.request.Request(
            base,
            data=json.dumps(body).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {self.settings.api_key}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        raw = output_path.with_suffix(".raw.wav")
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                raw.parent.mkdir(parents=True, exist_ok=True)
                raw.write_bytes(resp.read())
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")[:400]
            raise ProviderConfigError(f"OpenAI TTS HTTP {exc.code}: {detail}") from exc
        postprocess_wav(raw, output_path, trailing_ms=int(voice_profile.get("trailingSilenceMs", 220)))
        raw.unlink(missing_ok=True)
        m = measure_wav(output_path)
        return GenerateResult(output_path, m["durationMs"], "openai", voice_id, language, utc_now())


class ElevenLabsTtsProvider(TtsProvider):
    """https://elevenlabs.io/docs/api-reference/text-to-speech/convert"""

    def __init__(self, settings: ProviderSettings):
        self.settings = settings

    def generate(self, text, language, voice_profile, output_path, *, voice_id):
        base = self.settings.api_base or f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
        if "{voice_id}" in base:
            base = base.replace("{voice_id}", voice_id)
        elif self.settings.api_base == "":
            base = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
        body = {
            "text": text,
            "model_id": "eleven_multilingual_v2",
        }
        req = urllib.request.Request(
            base,
            data=json.dumps(body).encode("utf-8"),
            headers={
                "xi-api-key": self.settings.api_key,
                "Content-Type": "application/json",
                "Accept": "audio/wav",
            },
            method="POST",
        )
        raw = output_path.with_suffix(".raw.wav")
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                raw.parent.mkdir(parents=True, exist_ok=True)
                raw.write_bytes(resp.read())
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")[:400]
            raise ProviderConfigError(f"ElevenLabs TTS HTTP {exc.code}: {detail}") from exc
        postprocess_wav(raw, output_path, trailing_ms=int(voice_profile.get("trailingSilenceMs", 220)))
        raw.unlink(missing_ok=True)
        m = measure_wav(output_path)
        return GenerateResult(output_path, m["durationMs"], "elevenlabs", voice_id, language, utc_now())


class HttpTtsProvider(TtsProvider):
    """Generic POST JSON {text, language, voice_id} → WAV bytes. URL must come from env."""

    def __init__(self, settings: ProviderSettings):
        self.settings = settings

    def generate(self, text, language, voice_profile, output_path, *, voice_id):
        if not self.settings.api_base:
            raise ProviderConfigError("http provider requires VIMAI_AUDIO_V3_API_BASE (real documented URL).")
        body = {
            "text": text,
            "language": language,
            "voice_id": voice_id,
            "style": voice_profile.get("style"),
            "speed": voice_profile.get("speed"),
        }
        req = urllib.request.Request(
            self.settings.api_base,
            data=json.dumps(body).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {self.settings.api_key}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        raw = output_path.with_suffix(".raw.wav")
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                raw.parent.mkdir(parents=True, exist_ok=True)
                raw.write_bytes(resp.read())
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")[:400]
            raise ProviderConfigError(f"HTTP TTS {exc.code}: {detail}") from exc
        postprocess_wav(raw, output_path, trailing_ms=int(voice_profile.get("trailingSilenceMs", 220)))
        raw.unlink(missing_ok=True)
        m = measure_wav(output_path)
        return GenerateResult(output_path, m["durationMs"], "http", voice_id, language, utc_now())


def build_provider(settings: ProviderSettings | None = None) -> TtsProvider:
    settings = settings or load_settings()
    if settings.is_google:
        from .google_tts_provider import GoogleCloudTtsProvider

        return GoogleCloudTtsProvider()
    if not settings.configured:
        return UnconfiguredProvider()
    if settings.provider == "openai":
        return OpenAiTtsProvider(settings)
    if settings.provider == "elevenlabs":
        return ElevenLabsTtsProvider(settings)
    if settings.provider == "http":
        return HttpTtsProvider(settings)
    raise ProviderConfigError(
        f"Unknown VIMAI_AUDIO_V3_PROVIDER={settings.provider!r}. "
        "Audio V3 preview uses google_cloud only. "
        "openai | elevenlabs | http are not used as a silent fallback."
    )
