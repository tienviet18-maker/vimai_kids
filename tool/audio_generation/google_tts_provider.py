"""Google Cloud Text-to-Speech provider.

Uses the official `google.cloud.texttospeech` client and Application Default
Credentials. Voice names must exist in list_voices(). No silent substitute.
"""
from __future__ import annotations

import json

from .audio_postprocess import measure_wav, postprocess_wav
from .google_tts_status import CONFIG_PATH, diagnose, resolve_voice_name
from .provider_base import GenerateResult, ProviderConfigError, TtsProvider, utc_now


def _import_tts():
    try:
        from google.cloud import texttospeech
    except ImportError as exc:
        raise ProviderConfigError(
            "google-cloud-texttospeech is not installed. "
            "Install with: python -m pip install -r tool/requirements-audio-v3.txt"
        ) from exc
    return texttospeech


def _gender(texttospeech, value: str):
    raw = (value or "").strip().upper()
    mapping = {
        "FEMALE": texttospeech.SsmlVoiceGender.FEMALE,
        "MALE": texttospeech.SsmlVoiceGender.MALE,
        "NEUTRAL": texttospeech.SsmlVoiceGender.NEUTRAL,
    }
    return mapping.get(raw, texttospeech.SsmlVoiceGender.SSML_VOICE_GENDER_UNSPECIFIED)


class GoogleCloudTtsProvider(TtsProvider):
    def __init__(self):
        status = diagnose(probe_api=False)
        if not status.ready:
            raise ProviderConfigError(status.format_block())
        self._tts = _import_tts()
        self._config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
        try:
            self._client = self._tts.TextToSpeechClient()
        except Exception as exc:
            raise ProviderConfigError(
                f"Google Cloud TTS client failed to initialize: {type(exc).__name__}: {exc}"
            ) from exc
        self._verified: dict[str, str] = {}
        self._verify_voice("vi-VN", resolve_voice_name("vi"))
        self._verify_voice("ja-JP", resolve_voice_name("ja"))

    def _verify_voice(self, language_code: str, voice_name: str) -> None:
        if not voice_name:
            raise ProviderConfigError(f"Voice name missing for {language_code}")
        try:
            response = self._client.list_voices(language_code=language_code)
        except Exception as exc:
            raise ProviderConfigError(
                f"list_voices({language_code}) failed: {type(exc).__name__}: {exc}"
            ) from exc
        names = {v.name for v in response.voices}
        if voice_name not in names:
            try:
                all_voices = self._client.list_voices()
                names = {v.name for v in all_voices.voices}
            except Exception as exc:
                raise ProviderConfigError(
                    f"Voice {voice_name!r} not in list_voices({language_code}) "
                    f"and unfiltered list_voices failed: {type(exc).__name__}: {exc}"
                ) from exc
            if voice_name not in names:
                raise ProviderConfigError(
                    f"Configured voice {voice_name!r} does not exist in Google Cloud TTS "
                    f"for {language_code}. No substitute was chosen."
                )
        self._verified[language_code] = voice_name

    def generate(self, text, language, voice_profile, output_path, *, voice_id):
        lang = "vi-VN" if language.lower().startswith("vi") else "ja-JP"
        cfg_lang = self._config["vietnamese"] if lang == "vi-VN" else self._config["japanese"]
        voice_name = voice_id or self._verified[lang]
        if voice_name != self._verified[lang]:
            self._verify_voice(lang, voice_name)
        category = str(voice_profile.get("category") or "WORD").upper()
        rates = self._config.get("speaking_rate_by_category") or {}
        speaking_rate = float(rates.get(category, 0.94))
        pitch = float(self._config.get("pitch", 0.0))
        volume = float(self._config.get("volume_gain_db", 0.0))
        use_ssml = bool(voice_profile.get("useSsml"))
        if category == "PRAISE" and self._config.get("use_ssml_for_praise"):
            use_ssml = True
        if category in ("LETTER_NAME", "PHONICS") and not self._config.get("use_ssml_for_letters"):
            use_ssml = False
        texttospeech = self._tts
        if use_ssml:
            ssml = text if text.strip().startswith("<speak") else f"<speak>{text}</speak>"
            synthesis_input = texttospeech.SynthesisInput(ssml=ssml)
        else:
            synthesis_input = texttospeech.SynthesisInput(text=text)
        voice = texttospeech.VoiceSelectionParams(
            language_code=str(cfg_lang.get("language_code") or lang),
            name=voice_name,
            ssml_gender=_gender(texttospeech, str(cfg_lang.get("ssml_gender") or "")),
        )
        audio_kwargs = {
            "audio_encoding": texttospeech.AudioEncoding.LINEAR16,
            "speaking_rate": speaking_rate,
            "pitch": pitch,
            "volume_gain_db": volume,
        }
        sample_rate = self._config.get("sample_rate_hertz")
        if sample_rate:
            audio_kwargs["sample_rate_hertz"] = int(sample_rate)
        audio_config = texttospeech.AudioConfig(**audio_kwargs)
        try:
            response = self._client.synthesize_speech(
                input=synthesis_input,
                voice=voice,
                audio_config=audio_config,
            )
        except Exception as exc:
            raise ProviderConfigError(
                f"synthesize_speech failed for {output_path.name}: {type(exc).__name__}: {exc}"
            ) from exc
        raw = output_path.with_suffix(".raw.wav")
        raw.parent.mkdir(parents=True, exist_ok=True)
        raw.write_bytes(response.audio_content)
        trailing = int(voice_profile.get("trailingSilenceMs", 180))
        postprocess_wav(
            raw,
            output_path,
            trailing_ms=trailing,
            peak_target=28000,
            max_scale=1.25,
        )
        raw.unlink(missing_ok=True)
        m = measure_wav(output_path)
        return GenerateResult(
            output_path,
            m["durationMs"],
            "google_cloud_texttospeech",
            voice_name,
            language,
            utc_now(),
        )
