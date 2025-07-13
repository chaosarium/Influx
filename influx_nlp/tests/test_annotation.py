from __future__ import annotations
from inline_snapshot import snapshot
from lib.annotation import (
    AnnotatedDocV2,
    DocSegV2,
    DocSegSentence,
    SentSegV2,
    SentSegTokenSeg,
    SentSegWhitespaceSeg,
    SentSegPunctuationSeg,
    SegAttribute,
)


def test_serialization_small():
    # Create a sample AnnotatedDocV2 object
    doc = AnnotatedDocV2(
        text="Hello world!",
        segments=[
            DocSegV2(
                text="Hello world!",
                start_char=0,
                end_char=12,
                inner=DocSegSentence(
                    segments=[
                        SentSegV2(
                            sentence_idx=0,
                            text="Hello",
                            start_char=0,
                            end_char=5,
                            inner=SentSegTokenSeg(idx=0, orthography="hello"),
                            attributes=SegAttribute(lemma="hello", upos="INTJ"),
                        ),
                        SentSegV2(
                            sentence_idx=0,
                            text=" ",
                            start_char=5,
                            end_char=6,
                            inner=SentSegWhitespaceSeg(),
                            attributes=SegAttribute(),
                        ),
                        SentSegV2(
                            sentence_idx=0,
                            text="world",
                            start_char=6,
                            end_char=11,
                            inner=SentSegTokenSeg(idx=1, orthography="world"),
                            attributes=SegAttribute(lemma="world", upos="NOUN"),
                        ),
                        SentSegV2(
                            sentence_idx=0,
                            text="!",
                            start_char=11,
                            end_char=12,
                            inner=SentSegPunctuationSeg(),
                            attributes=SegAttribute(lemma="!", upos="PUNCT"),
                        ),
                    ]
                ),
            )
        ],
        orthography_set=["hello", "world", "!"],
        lemma_set=["hello", "world", "!"],
    )

    # Serialize to dictionary
    doc_dict = doc.to_dict()

    # Snapshot test
    assert doc_dict == snapshot(
        {
            "text": "Hello world!",
            "segments": [
                {
                    "text": "Hello world!",
                    "start_char": 0,
                    "end_char": 12,
                    "inner": {
                        "Sentence": {
                            "segments": [
                                {
                                    "sentence_idx": 0,
                                    "text": "Hello",
                                    "start_char": 0,
                                    "end_char": 5,
                                    "inner": {"TokenSeg": {"idx": 0, "orthography": "hello"}},
                                    "attributes": {"lemma": "hello", "upos": "INTJ", "misc": {}},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": " ",
                                    "start_char": 5,
                                    "end_char": 6,
                                    "inner": "WhitespaceSeg",
                                    "attributes": {"misc": {}},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "world",
                                    "start_char": 6,
                                    "end_char": 11,
                                    "inner": {"TokenSeg": {"idx": 1, "orthography": "world"}},
                                    "attributes": {"lemma": "world", "upos": "NOUN", "misc": {}},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "!",
                                    "start_char": 11,
                                    "end_char": 12,
                                    "inner": "PunctuationSeg",
                                    "attributes": {"lemma": "!", "upos": "PUNCT", "misc": {}},
                                },
                            ]
                        }
                    },
                }
            ],
            "orthography_set": ["hello", "world", "!"],
            "lemma_set": ["hello", "world", "!"],
        }
    )
