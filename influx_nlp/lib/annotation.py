from __future__ import annotations
from dataclasses import dataclass, asdict, field
from typing import List, Dict, Optional, Tuple, Union


# Corresponds to Rust's `SegAttribute`
@dataclass
class SegAttribute:
    lemma: Optional[str] = None
    upos: Optional[str] = None
    xpos: Optional[str] = None
    dependency: Optional[Tuple[int, str]] = None
    misc: Dict[str, str] = field(default_factory=dict)

    def to_dict(self):
        data = {
            "lemma": self.lemma,
            "upos": self.upos,
            "xpos": self.xpos,
            "dependency": self.dependency,
            "misc": self.misc,
        }
        return {k: v for k, v in data.items() if v is not None}


# Corresponds to Rust's `SentSegVariants`
@dataclass
class SentSegTokenSeg:
    idx: int
    orthography: str

    def to_dict(self):
        return {"TokenSeg": {"idx": self.idx, "orthography": self.orthography}}


@dataclass
class SentSegPhraseSeg:
    normalised_orthography: str
    components: List[SentSegV2]

    def to_dict(self):
        return {
            "PhraseSeg": {
                "normalised_orthography": self.normalised_orthography,
                "components": [c.to_dict() for c in self.components],
            }
        }


@dataclass
class SentSegWhitespaceSeg:
    def to_dict(self):
        return "WhitespaceSeg"


@dataclass
class SentSegPunctuationSeg:
    def to_dict(self):
        return "PunctuationSeg"


SentSegVariants = Union[SentSegTokenSeg, SentSegPhraseSeg, SentSegWhitespaceSeg, SentSegPunctuationSeg]


# Corresponds to Rust's `SentSegV2`
@dataclass
class SentSegV2:
    sentence_idx: int
    text: str
    start_char: int
    end_char: int
    inner: SentSegVariants
    attributes: SegAttribute

    def to_dict(self):
        return {
            "sentence_idx": self.sentence_idx,
            "text": self.text,
            "start_char": self.start_char,
            "end_char": self.end_char,
            "inner": self.inner.to_dict(),
            "attributes": self.attributes.to_dict(),
        }


# Corresponds to Rust's `DocSegVariants`
@dataclass
class DocSegSentence:
    segments: List[SentSegV2]

    def to_dict(self):
        return {"Sentence": {"segments": [s.to_dict() for s in self.segments]}}


@dataclass
class DocSegDocumentWhitespace:
    def to_dict(self):
        return "DocumentWhitespace"


DocSegVariants = Union[DocSegSentence, DocSegDocumentWhitespace]


# Corresponds to Rust's `DocSegV2`
@dataclass
class DocSegV2:
    text: str
    start_char: int
    end_char: int
    inner: DocSegVariants

    def to_dict(self):
        return {
            "text": self.text,
            "start_char": self.start_char,
            "end_char": self.end_char,
            "inner": self.inner.to_dict(),
        }

# Corresponds to Rust's `ParserConfig`
@dataclass
class ParserConfig:
    which_parser: str
    parser_args: dict[str, str]
    
    def to_dict(self):
        return {
            "which_parser": self.which_parser,
            "parser_args": self.parser_args,
        }

# Corresponds to Rust's `AnnotatedDocV2`
@dataclass
class AnnotatedDocV2:
    text: str
    segments: List[DocSegV2]
    orthography_set: List[str]
    lemma_set: List[str]
    parser_config: ParserConfig

    def to_dict(self):
        data = {
            "text": self.text,
            "segments": [s.to_dict() for s in self.segments],
            "orthography_set": self.orthography_set,
            "lemma_set": self.lemma_set,
            "parser_config": self.parser_config.to_dict(),
        }
        return {k: v for k, v in data.items() if v is not None}

