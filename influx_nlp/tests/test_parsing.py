from __future__ import annotations
from inline_snapshot import snapshot
from lib.parsing import SpacyParser


def test_spacy_parser_en():
    parser = SpacyParser()
    text = "This is a test."
    result = parser.parse(text, "en")
    result["orthography_set"].sort()
    result["lemma_set"].sort()
    assert result == snapshot(
        {
            "text": "This is a test.",
            "segments": [
                {
                    "text": "This is a test.",
                    "start_char": 0,
                    "end_char": 15,
                    "inner": {
                        "Sentence": {
                            "segments": [
                                {
                                    "sentence_idx": 0,
                                    "text": "This",
                                    "start_char": 0,
                                    "end_char": 4,
                                    "inner": {"TokenCst": {"idx": 0, "orthography": "this"}},
                                    "attributes": {
                                        "lemma": "this",
                                        "is_punctuation": False,
                                        "upos": "PRON",
                                        "xpos": "DT",
                                        "dependency": (1, "nsubj"),
                                        "misc": {"Number": "Sing", "PronType": "Dem"},
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": " ",
                                    "start_char": 4,
                                    "end_char": 5,
                                    "inner": "WhitespaceSeg",
                                    "attributes": {"misc": {}},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "is",
                                    "start_char": 5,
                                    "end_char": 7,
                                    "inner": {"TokenCst": {"idx": 1, "orthography": "is"}},
                                    "attributes": {
                                        "lemma": "be",
                                        "is_punctuation": False,
                                        "upos": "AUX",
                                        "xpos": "VBZ",
                                        "dependency": (1, "ROOT"),
                                        "misc": {
                                            "Mood": "Ind",
                                            "Number": "Sing",
                                            "Person": "3",
                                            "Tense": "Pres",
                                            "VerbForm": "Fin",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": " ",
                                    "start_char": 7,
                                    "end_char": 8,
                                    "inner": "WhitespaceSeg",
                                    "attributes": {"misc": {}},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "a",
                                    "start_char": 8,
                                    "end_char": 9,
                                    "inner": {"TokenCst": {"idx": 2, "orthography": "a"}},
                                    "attributes": {
                                        "lemma": "a",
                                        "is_punctuation": False,
                                        "upos": "DET",
                                        "xpos": "DT",
                                        "dependency": (3, "det"),
                                        "misc": {"Definite": "Ind", "PronType": "Art"},
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": " ",
                                    "start_char": 9,
                                    "end_char": 10,
                                    "inner": "WhitespaceSeg",
                                    "attributes": {"misc": {}},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "test",
                                    "start_char": 10,
                                    "end_char": 14,
                                    "inner": {"TokenCst": {"idx": 3, "orthography": "test"}},
                                    "attributes": {
                                        "lemma": "test",
                                        "is_punctuation": False,
                                        "upos": "NOUN",
                                        "xpos": "NN",
                                        "dependency": (1, "attr"),
                                        "misc": {"Number": "Sing"},
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": ".",
                                    "start_char": 14,
                                    "end_char": 15,
                                    "inner": {"TokenCst": {"idx": 4, "orthography": "."}},
                                    "attributes": {
                                        "lemma": ".",
                                        "is_punctuation": True,
                                        "upos": "PUNCT",
                                        "xpos": ".",
                                        "dependency": (1, "punct"),
                                        "misc": {"PunctType": "Peri"},
                                    },
                                },
                            ]
                        }
                    },
                }
            ],
            "orthography_set": [".", "a", "is", "test", "this"],
            "lemma_set": [".", "a", "be", "test", "this"],
        }
    )


def test_spacy_parser_ja():
    parser = SpacyParser()
    text = "これはテストです。"
    result = parser.parse(text, "ja")
    result["orthography_set"].sort()
    result["lemma_set"].sort()
    assert result == snapshot(
        {
            "text": "これはテストです。",
            "segments": [
                {
                    "text": "これはテストです。",
                    "start_char": 0,
                    "end_char": 9,
                    "inner": {
                        "Sentence": {
                            "segments": [
                                {
                                    "sentence_idx": 0,
                                    "text": "これ",
                                    "start_char": 0,
                                    "end_char": 2,
                                    "inner": {"TokenCst": {"idx": 0, "orthography": "これ"}},
                                    "attributes": {
                                        "lemma": "これ",
                                        "is_punctuation": False,
                                        "upos": "PRON",
                                        "xpos": "代名詞",
                                        "dependency": (2, "nsubj"),
                                        "misc": {"Reading": "コレ"},
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "は",
                                    "start_char": 2,
                                    "end_char": 3,
                                    "inner": {"TokenCst": {"idx": 1, "orthography": "は"}},
                                    "attributes": {
                                        "lemma": "は",
                                        "is_punctuation": False,
                                        "upos": "ADP",
                                        "xpos": "助詞-係助詞",
                                        "dependency": (0, "case"),
                                        "misc": {"Reading": "ハ"},
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "テスト",
                                    "start_char": 3,
                                    "end_char": 6,
                                    "inner": {"TokenCst": {"idx": 2, "orthography": "テスト"}},
                                    "attributes": {
                                        "lemma": "テスト",
                                        "is_punctuation": False,
                                        "upos": "NOUN",
                                        "xpos": "名詞-普通名詞-サ変可能",
                                        "dependency": (2, "ROOT"),
                                        "misc": {"Reading": "テスト"},
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "です",
                                    "start_char": 6,
                                    "end_char": 8,
                                    "inner": {"TokenCst": {"idx": 3, "orthography": "です"}},
                                    "attributes": {
                                        "lemma": "です",
                                        "is_punctuation": False,
                                        "upos": "AUX",
                                        "xpos": "助動詞",
                                        "dependency": (2, "cop"),
                                        "misc": {"Inflection": "助動詞-デス;終止形-一般", "Reading": "デス"},
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "。",
                                    "start_char": 8,
                                    "end_char": 9,
                                    "inner": {"TokenCst": {"idx": 4, "orthography": "。"}},
                                    "attributes": {
                                        "lemma": "。",
                                        "is_punctuation": True,
                                        "upos": "PUNCT",
                                        "xpos": "補助記号-句点",
                                        "dependency": (2, "punct"),
                                        "misc": {"Reading": "。"},
                                    },
                                },
                            ]
                        }
                    },
                }
            ],
            "orthography_set": ["。", "これ", "です", "は", "テスト"],
            "lemma_set": ["。", "これ", "です", "は", "テスト"],
        }
    )
