from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol, runtime_checkable


@dataclass
class ClassificationResult:
    is_illegal: bool
    type: str
    confidence: float
    reason: str


@runtime_checkable
class VarcoInterface(Protocol):
    def translate(self, text: str) -> str: ...

    def classify(self, text: str) -> ClassificationResult: ...
