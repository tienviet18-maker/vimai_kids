from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


class ProviderConfigError(Exception):
    """Missing or invalid premium TTS configuration. Safe to surface; do not generate audio."""


@dataclass
class GenerateResult:
    output_path: Path
    duration_ms: int
    provider: str
    voice_id: str
    language: str
    generated_at: str

    def as_dict(self) -> dict:
        return {
            "output_path": str(self.output_path).replace("\\", "/"),
            "durationMs": self.duration_ms,
            "provider": self.provider,
            "voiceId": self.voice_id,
            "language": self.language,
            "generatedAt": self.generated_at,
        }


class TtsProvider(ABC):
    @abstractmethod
    def generate(
        self,
        text: str,
        language: str,
        voice_profile: dict,
        output_path: Path,
        *,
        voice_id: str,
    ) -> GenerateResult:
        raise NotImplementedError


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()
