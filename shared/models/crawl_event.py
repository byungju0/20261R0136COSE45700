from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field


@dataclass
class CrawlEvent:
    post_id: str
    source_id: str
    site_name: str
    raw_text: str
    language: str
    detected_at: str
    correlation_id: str
    image_urls: list[str] = field(default_factory=list)

    def to_json(self) -> str:
        return json.dumps(asdict(self))

    @classmethod
    def from_json(cls, data: str) -> CrawlEvent:
        return cls(**json.loads(data))
