from __future__ import annotations
from inline_snapshot import snapshot
from lib.parsing import SpacyParser, JapaneseParser
from lib.annotation import ParserConfig


def test_spacy_parser_en():
    parser = SpacyParser()
    text = "This is a test."
    result = parser.parse(text, ParserConfig("spacy", {"spacy_model": "en_core_web_sm"})).to_dict()
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
                                    "inner": {"TokenSeg": {"idx": 0, "orthography": "this"}},
                                    "attributes": {"lemma": "this", "upos": "PRON", "xpos": "DT", "dependency": (1, "nsubj"), "misc": {"Number": "Sing", "PronType": "Dem"}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": " ",
                                    "start_char": 4,
                                    "end_char": 5,
                                    "inner": "WhitespaceSeg",
                                    "attributes": {'lemma': None, 'upos': None, 'xpos': None, 'dependency': None, "misc": {}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "is",
                                    "start_char": 5,
                                    "end_char": 7,
                                    "inner": {"TokenSeg": {"idx": 1, "orthography": "is"}},
                                    "attributes": {
                                        "lemma": "be",
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
                                        'conjugation_chain': None,
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": " ",
                                    "start_char": 7,
                                    "end_char": 8,
                                    "inner": "WhitespaceSeg",
                                    "attributes": {'lemma': None, 'upos': None, 'xpos': None, 'dependency': None, "misc": {}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "a",
                                    "start_char": 8,
                                    "end_char": 9,
                                    "inner": {"TokenSeg": {"idx": 2, "orthography": "a"}},
                                    "attributes": {"lemma": "a", "upos": "DET", "xpos": "DT", "dependency": (3, "det"), "misc": {"Definite": "Ind", "PronType": "Art"}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": " ",
                                    "start_char": 9,
                                    "end_char": 10,
                                    "inner": "WhitespaceSeg",
                                    "attributes": {'lemma': None, 'upos': None, 'xpos': None, 'dependency': None, "misc": {}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "test",
                                    "start_char": 10,
                                    "end_char": 14,
                                    "inner": {"TokenSeg": {"idx": 3, "orthography": "test"}},
                                    "attributes": {"lemma": "test", "upos": "NOUN", "xpos": "NN", "dependency": (1, "attr"), "misc": {"Number": "Sing"}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": ".",
                                    "start_char": 14,
                                    "end_char": 15,
                                    "inner": "PunctuationSeg",
                                    "attributes": {"lemma": ".", "upos": "PUNCT", "xpos": ".", "dependency": (1, "punct"), "misc": {"PunctType": "Peri"}, 'conjugation_chain': None},
                                },
                            ]
                        }
                    },
                }
            ],
            "orthography_set": [".", "a", "is", "test", "this"],
            "lemma_set": [".", "a", "be", "test", "this"],
            "parser_config": {"which_parser": "spacy", "parser_args": {"spacy_model": "en_core_web_sm"}},
        }
    )


def test_spacy_parser_weird_whitespaces():
    parser = SpacyParser()
    text = "  \n Je connais un vampire  végétarien…   \n il suce des betteraves ! "
    result = parser.parse(text, ParserConfig("spacy", {"spacy_model": "fr_core_news_sm"})).to_dict()
    result["orthography_set"].sort()
    result["lemma_set"].sort()
    assert result == snapshot(
        {
            "text": """\
  \n\
 Je connais un vampire  végétarien…   \n\
 il suce des betteraves ! \
""",
            "segments": [
                {
                    "text": """\
  \n\
 \
""",
                    "start_char": 0,
                    "end_char": 4,
                    "inner": "DocumentWhitespace",
                },
                {
                    "text": "Je connais un vampire",
                    "start_char": 4,
                    "end_char": 25,
                    "inner": {
                        "Sentence": {
                            "segments": [
                                {
                                    "sentence_idx": 1,
                                    "text": "Je",
                                    "start_char": 4,
                                    "end_char": 6,
                                    "inner": {"TokenSeg": {"idx": 1, "orthography": "je"}},
                                    "attributes": {"lemma": "je", "upos": "PRON", "xpos": "PRON", "dependency": (2, "nsubj"), "misc": {"Number": "Sing", "Person": "1"}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 1,
                                    "text": " ",
                                    "start_char": 6,
                                    "end_char": 7,
                                    "inner": "WhitespaceSeg",
                                    "attributes": {'lemma': None, 'upos': None, 'xpos': None, 'dependency': None, "misc": {}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 1,
                                    "text": "connais",
                                    "start_char": 7,
                                    "end_char": 14,
                                    "inner": {"TokenSeg": {"idx": 2, "orthography": "connais"}},
                                    "attributes": {
                                        "lemma": "connaître",
                                        "upos": "VERB",
                                        "xpos": "VERB",
                                        "dependency": (2, "ROOT"),
                                        "misc": {
                                            "Mood": "Ind",
                                            "Number": "Sing",
                                            "Person": "1",
                                            "Tense": "Pres",
                                            "VerbForm": "Fin",
                                        },
                                        'conjugation_chain': None,
                                    },
                                },
                                {
                                    "sentence_idx": 1,
                                    "text": " ",
                                    "start_char": 14,
                                    "end_char": 15,
                                    "inner": "WhitespaceSeg",
                                    "attributes": {'lemma': None, 'upos': None, 'xpos': None, 'dependency': None, "misc": {}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 1,
                                    "text": "un",
                                    "start_char": 15,
                                    "end_char": 17,
                                    "inner": {"TokenSeg": {"idx": 3, "orthography": "un"}},
                                    "attributes": {
                                        "lemma": "un",
                                        "upos": "DET",
                                        "xpos": "DET",
                                        "dependency": (4, "det"),
                                        "misc": {
                                            "Definite": "Ind",
                                            "Gender": "Masc",
                                            "Number": "Sing",
                                            "PronType": "Art",
                                        },
                                        'conjugation_chain': None,
                                    },
                                },
                                {
                                    "sentence_idx": 1,
                                    "text": " ",
                                    "start_char": 17,
                                    "end_char": 18,
                                    "inner": "WhitespaceSeg",
                                    "attributes": {'lemma': None, 'upos': None, 'xpos': None, 'dependency': None, "misc": {}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 1,
                                    "text": "vampire",
                                    "start_char": 18,
                                    "end_char": 25,
                                    "inner": {"TokenSeg": {"idx": 4, "orthography": "vampire"}},
                                    "attributes": {"lemma": "vampire", "upos": "NOUN", "xpos": "NOUN", "dependency": (2, "obj"), "misc": {"Gender": "Fem", "Number": "Sing"}, 'conjugation_chain': None},
                                },
                            ]
                        }
                    },
                },
                {"text": "  ", "start_char": 25, "end_char": 27, "inner": "DocumentWhitespace"},
                {
                    "text": """\
végétarien…   \n\
 il suce des betteraves !\
""",
                    "start_char": 27,
                    "end_char": 67,
                    "inner": {
                        "Sentence": {
                            "segments": [
                                {
                                    "sentence_idx": 2,
                                    "text": "végétarien",
                                    "start_char": 27,
                                    "end_char": 37,
                                    "inner": {"TokenSeg": {"idx": 6, "orthography": "végétarien"}},
                                    "attributes": {"lemma": "végétarien", "upos": "ADV", "xpos": "ADV", "dependency": (7, "punct"), "misc": {"PronType": "Int"}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 2,
                                    "text": "…",
                                    "start_char": 37,
                                    "end_char": 38,
                                    "inner": "PunctuationSeg",
                                    "attributes": {"lemma": "…", "upos": "PUNCT", "xpos": "PUNCT", "dependency": (7, "ROOT"), "misc": {}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 2,
                                    "text": """\
   \n\
 \
""",
                                    "start_char": 38,
                                    "end_char": 43,
                                    "inner": "WhitespaceSeg",
                                    "attributes": {'lemma': None, 'upos': None, 'xpos': None, 'dependency': None, "misc": {}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 2,
                                    "text": "il",
                                    "start_char": 43,
                                    "end_char": 45,
                                    "inner": {"TokenSeg": {"idx": 9, "orthography": "il"}},
                                    "attributes": {"lemma": "il", "upos": "PRON", "xpos": "PRON", "dependency": (10, "nsubj"), "misc": {"Gender": "Masc", "Number": "Sing", "Person": "3"}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 2,
                                    "text": " ",
                                    "start_char": 45,
                                    "end_char": 46,
                                    "inner": "WhitespaceSeg",
                                    "attributes": {'lemma': None, 'upos': None, 'xpos': None, 'dependency': None, "misc": {}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 2,
                                    "text": "suce",
                                    "start_char": 46,
                                    "end_char": 50,
                                    "inner": {"TokenSeg": {"idx": 10, "orthography": "suce"}},
                                    "attributes": {
                                        "lemma": "sucer",
                                        "upos": "VERB",
                                        "xpos": "VERB",
                                        "dependency": (7, "advcl"),
                                        "misc": {
                                            "Mood": "Ind",
                                            "Number": "Sing",
                                            "Person": "3",
                                            "Tense": "Pres",
                                            "VerbForm": "Fin",
                                        },
                                        'conjugation_chain': None,
                                    },
                                },
                                {
                                    "sentence_idx": 2,
                                    "text": " ",
                                    "start_char": 50,
                                    "end_char": 51,
                                    "inner": "WhitespaceSeg",
                                    "attributes": {'lemma': None, 'upos': None, 'xpos': None, 'dependency': None, "misc": {}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 2,
                                    "text": "des",
                                    "start_char": 51,
                                    "end_char": 54,
                                    "inner": {"TokenSeg": {"idx": 11, "orthography": "des"}},
                                    "attributes": {"lemma": "un", "upos": "DET", "xpos": "DET", "dependency": (12, "det"), "misc": {"Definite": "Ind", "Number": "Plur", "PronType": "Art"}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 2,
                                    "text": " ",
                                    "start_char": 54,
                                    "end_char": 55,
                                    "inner": "WhitespaceSeg",
                                    "attributes": {'lemma': None, 'upos': None, 'xpos': None, 'dependency': None, "misc": {}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 2,
                                    "text": "betteraves",
                                    "start_char": 55,
                                    "end_char": 65,
                                    "inner": {"TokenSeg": {"idx": 12, "orthography": "betteraves"}},
                                    "attributes": {"lemma": "betterave", "upos": "NOUN", "xpos": "NOUN", "dependency": (10, "obj"), "misc": {"Gender": "Fem", "Number": "Plur"}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 2,
                                    "text": " ",
                                    "start_char": 65,
                                    "end_char": 66,
                                    "inner": "WhitespaceSeg",
                                    "attributes": {'lemma': None, 'upos': None, 'xpos': None, 'dependency': None, "misc": {}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 2,
                                    "text": "!",
                                    "start_char": 66,
                                    "end_char": 67,
                                    "inner": "PunctuationSeg",
                                    "attributes": {"lemma": "!", "upos": "PUNCT", "xpos": "PUNCT", "dependency": (7, "punct"), "misc": {}, 'conjugation_chain': None},
                                },
                            ]
                        }
                    },
                },
                {"text": " ", "start_char": 67, "end_char": 68, "inner": "DocumentWhitespace"},
            ],
            "orthography_set": [
                "!",
                "betteraves",
                "connais",
                "des",
                "il",
                "je",
                "suce",
                "un",
                "vampire",
                "végétarien",
                "…",
            ],
            "lemma_set": [
                "!",
                "betterave",
                "connaître",
                "il",
                "je",
                "sucer",
                "un",
                "vampire",
                "végétarien",
                "…",
            ],
            "parser_config": {"which_parser": "spacy", "parser_args": {"spacy_model": "fr_core_news_sm"}},
        }
    )


def test_spacy_parser_ja():
    parser = SpacyParser()
    text = "これはテストです。"
    result = parser.parse(text, ParserConfig("spacy", {"spacy_model": "ja_core_news_sm"})).to_dict()
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
                                    "inner": {"TokenSeg": {"idx": 0, "orthography": "これ"}},
                                    "attributes": {"lemma": "これ", "upos": "PRON", "xpos": "代名詞", "dependency": (2, "nsubj"), "misc": {"Reading": "コレ"}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "は",
                                    "start_char": 2,
                                    "end_char": 3,
                                    "inner": {"TokenSeg": {"idx": 1, "orthography": "は"}},
                                    "attributes": {"lemma": "は", "upos": "ADP", "xpos": "助詞-係助詞", "dependency": (0, "case"), "misc": {"Reading": "ハ"}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "テスト",
                                    "start_char": 3,
                                    "end_char": 6,
                                    "inner": {"TokenSeg": {"idx": 2, "orthography": "テスト"}},
                                    "attributes": {"lemma": "テスト", "upos": "NOUN", "xpos": "名詞-普通名詞-サ変可能", "dependency": (2, "ROOT"), "misc": {"Reading": "テスト"}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "です",
                                    "start_char": 6,
                                    "end_char": 8,
                                    "inner": {"TokenSeg": {"idx": 3, "orthography": "です"}},
                                    "attributes": {"lemma": "です", "upos": "AUX", "xpos": "助動詞", "dependency": (2, "cop"), "misc": {"Inflection": "助動詞-デス;終止形-一般", "Reading": "デス"}, 'conjugation_chain': None},
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "。",
                                    "start_char": 8,
                                    "end_char": 9,
                                    "inner": "PunctuationSeg",
                                    "attributes": {"lemma": "。", "upos": "PUNCT", "xpos": "補助記号-句点", "dependency": (2, "punct"), "misc": {"Reading": "。"}, 'conjugation_chain': None},
                                },
                            ]
                        }
                    },
                }
            ],
            "orthography_set": ["。", "これ", "です", "は", "テスト"],
            "lemma_set": ["。", "これ", "です", "は", "テスト"],
            "parser_config": {"which_parser": "spacy", "parser_args": {"spacy_model": "ja_core_news_sm"}},
        }
    )


def _print_segmentation_boundaries(segments):
    output = []
    for segment in segments:
        if "Sentence" in segment["inner"]:
            sentence_tokens = []
            for token_segment in segment["inner"]["Sentence"]["segments"]:
                if token_segment["inner"] == "WhitespaceSeg":
                    pass  # Skip whitespace for simplified output
                elif "TokenSeg" in token_segment["inner"]:
                    sentence_tokens.append(token_segment["text"])
            output.append(" / ".join(sentence_tokens))
    return "\n".join(output)


def test_spacy_parser_segmentation_simple_en():
    parser = SpacyParser()
    text = "Hello world. This is a test."
    result = parser.parse(text, ParserConfig("spacy", {"spacy_model": "en_core_web_sm"})).to_dict()
    assert _print_segmentation_boundaries(result["segments"]) == snapshot(
        """\
Hello / world
This / is / a / test\
"""
    )


def test_spacy_parser_segmentation_multiple_sentences_with_whitespace_en():
    parser = SpacyParser()
    text = "First sentence.  Second sentence.   Third sentence."
    result = parser.parse(text, ParserConfig("spacy", {"spacy_model": "en_core_web_sm"})).to_dict()
    assert _print_segmentation_boundaries(result["segments"]) == snapshot(
        """\
First / sentence
Second / sentence
Third / sentence\
"""
    )


def test_japanese_parser_with_furigana():
    """Test JapaneseParser adds furigana annotations to misc field."""
    parser = JapaneseParser()
    text = "これはテストです。"
    result = parser.parse(text, ParserConfig("enhanced_japanese", {})).to_dict()
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
                                    "inner": {"TokenSeg": {"idx": 0, "orthography": "これ"}},
                                    "attributes": {
                                        "lemma": "これ",
                                        "upos": "PRON",
                                        "xpos": "代名詞",
                                        "dependency": (2, "nsubj"),
                                        "misc": {
                                            "Reading": "コレ",
                                            "furigana_bracket": "これ",
                                            "furigana_ruby": "これ",
                                            "furigana_parentheses": "これ",
                                            "hiragana_reading": "これ",
                                        },
                                        'conjugation_chain': None,
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "は",
                                    "start_char": 2,
                                    "end_char": 3,
                                    "inner": {"TokenSeg": {"idx": 1, "orthography": "は"}},
                                    "attributes": {
                                        "lemma": "は",
                                        "upos": "ADP",
                                        "xpos": "助詞-係助詞",
                                        "dependency": (0, "case"),
                                        "misc": {
                                            "Reading": "ハ",
                                            "furigana_bracket": "は",
                                            "furigana_ruby": "は",
                                            "furigana_parentheses": "は",
                                            "hiragana_reading": "は",
                                        },
                                        'conjugation_chain': None,
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "テスト",
                                    "start_char": 3,
                                    "end_char": 6,
                                    "inner": {"TokenSeg": {"idx": 2, "orthography": "テスト"}},
                                    "attributes": {
                                        "lemma": "テスト",
                                        "upos": "NOUN",
                                        "xpos": "名詞-普通名詞-サ変可能",
                                        "dependency": (2, "ROOT"),
                                        "misc": {
                                            "Reading": "テスト",
                                            "furigana_bracket": "テスト",
                                            "furigana_ruby": "テスト",
                                            "furigana_parentheses": "テスト",
                                            "hiragana_reading": "てすと",
                                        },
                                        'conjugation_chain': None,
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "です",
                                    "start_char": 6,
                                    "end_char": 8,
                                    "inner": {"TokenSeg": {"idx": 3, "orthography": "です"}},
                                    "attributes": {
                                        "lemma": "です",
                                        "upos": "AUX",
                                        "xpos": "助動詞",
                                        "dependency": (2, "cop"),
                                        "misc": {
                                            "Inflection": "助動詞-デス;終止形-一般",
                                            "Reading": "デス",
                                            "furigana_bracket": "です",
                                            "furigana_ruby": "です",
                                            "furigana_parentheses": "です",
                                            "hiragana_reading": "です",
                                            'conjugation_base': 'です',
                                            'conjugation_sequence_length': 1,
                                            'conjugation_combined_text': 'です',
                                        },
                                        'conjugation_chain': [{'step': 0, 'form': 'base', 'result': 'です'}],
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "。",
                                    "start_char": 8,
                                    "end_char": 9,
                                    "inner": "PunctuationSeg",
                                    "attributes": {
                                        "lemma": "。",
                                        "upos": "PUNCT",
                                        "xpos": "補助記号-句点",
                                        "dependency": (2, "punct"),
                                        "misc": {
                                            "Reading": "。",
                                            "furigana_bracket": "。",
                                            "furigana_ruby": "。",
                                            "furigana_parentheses": "。",
                                            "hiragana_reading": "。",
                                        },
                                        'conjugation_chain': None,
                                    },
                                },
                            ]
                        }
                    },
                }
            ],
            "orthography_set": ["。", "これ", "です", "は", "テスト"],
            "lemma_set": ["。", "これ", "です", "は", "テスト"],
            "parser_config": {"which_parser": 'enhanced_japanese', "parser_args": {}},
        }
    )
