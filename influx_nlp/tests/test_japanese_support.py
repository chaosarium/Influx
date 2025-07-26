from __future__ import annotations
from inline_snapshot import snapshot
from lib.annotation import ParserConfig
from lib.parsing import JapaneseParser
from lib.japanese_support import (
    align_furigana,
    format_furigana,
    add_furigana_annotations,
)
import wanakana


def test_align_furigana_basic():
    """Test basic furigana alignment cases."""
    # Simple kanji with okurigana
    result = align_furigana("難しい", "むずかしい")
    assert result == snapshot([("難", "むずか"), ("し", None), ("い", None)])

    # Mixed kanji and kana
    result = align_furigana("読み書き", "よみかき")
    assert result == snapshot([("読", "よ"), ("み", None), ("書", "か"), ("き", None)])

    # All kanji
    result = align_furigana("漢字", "かんじ")
    assert result == snapshot([("漢字", "かんじ")])

    # All hiragana (identical)
    result = align_furigana("ひらがな", "ひらがな")
    assert result == snapshot([("ひらがな", None)])

    # Simple verb
    result = align_furigana("食べる", "たべる")
    assert result == snapshot([("食", "た"), ("べ", None), ("る", None)])

    # Beautiful adjective
    result = align_furigana("美しい", "うつくしい")
    assert result == snapshot([("美", "うつく"), ("し", None), ("い", None)])

    # Repeated kanji compound - this was the problematic case
    result = align_furigana("所々", "ところどころ")
    assert result == snapshot([("所々", "ところどころ")])


def test_align_furigana_complex():
    """Test furigana alignment with complex cases."""
    # Mixed script cases
    result = align_furigana("お母さん", "おかあさん")
    assert result == snapshot([("お", None), ("母", "かあ"), ("さ", None), ("ん", None)])

    result = align_furigana("お父さん", "おとうさん")
    assert result == snapshot([("お", None), ("父", "とう"), ("さ", None), ("ん", None)])

    # All kanji compound words
    result = align_furigana("映画館", "えいがかん")
    assert result == snapshot([("映画館", "えいがかん")])

    result = align_furigana("図書館", "としょかん")
    assert result == snapshot([("図書館", "としょかん")])

    result = align_furigana("新幹線", "しんかんせん")
    assert result == snapshot([("新幹線", "しんかんせん")])


def test_align_furigana_katakana_cases():
    """Test alignment with katakana input."""
    # All katakana to hiragana
    result = align_furigana("コンピューター", "こんぴゅーたー")
    assert result == snapshot(
        [("コ", None), ("ン", None), ("ピ", None), ("ュ", None), ("ー", None), ("タ", None), ("ー", None)]
    )

    result = align_furigana("データベース", "でーたべーす")
    assert result == snapshot([("デ", None), ("ー", None), ("タ", None), ("ベ", None), ("ー", None), ("ス", None)])

    result = align_furigana("アプリ", "あぷり")
    assert result == snapshot([("ア", None), ("プ", None), ("リ", None)])


def test_align_furigana_mixed_script():
    """Test alignment with mixed scripts."""
    # Hiragana + kanji
    result = align_furigana("ひらがな漢字", "ひらがなかんじ")
    assert result == snapshot([("ひ", None), ("ら", None), ("が", None), ("な", None), ("漢字", "かんじ")])

    # Katakana + kanji (hypothetical)
    result = align_furigana("カタカナ漢字", "かたかなかんじ")
    assert result == snapshot([("カ", None), ("タ", None), ("カ", None), ("ナ", None), ("漢字", "かんじ")])


def test_format_furigana():
    """Test different furigana formatting options."""
    alignment = [("難", "むずか"), ("しい", None)]

    # Bracket format
    result = format_furigana(alignment, "bracket")
    assert result == snapshot("難[むずか]しい")

    # Ruby format
    result = format_furigana(alignment, "ruby")
    assert result == snapshot("<ruby>難<rt>むずか</rt></ruby>しい")

    # Parentheses format
    result = format_furigana(alignment, "parentheses")
    assert result == snapshot("難(むずか)しい")


def test_katakana_to_hiragana():
    """Test katakana to hiragana conversion."""
    # Basic katakana
    result = wanakana.to_hiragana("コレ")
    assert result == snapshot("これ")

    result = wanakana.to_hiragana("テスト")
    assert result == snapshot("てすと")

    result = wanakana.to_hiragana("デス")
    assert result == snapshot("です")

    # Mixed content
    result = wanakana.to_hiragana("コンピューター")
    assert result == snapshot("こんぴゅうたあ")

    # Already hiragana (should remain unchanged)
    result = wanakana.to_hiragana("ひらがな")
    assert result == snapshot("ひらがな")


def test_add_furigana_annotations():
    """Test complete furigana annotation generation."""
    # Simple case
    result = add_furigana_annotations("これ", "コレ")
    assert result == snapshot(
        {
            "furigana_bracket": "これ",
            "furigana_ruby": "これ",
            "furigana_parentheses": "これ",
            "hiragana_reading": "これ",
        }
    )

    # Complex case with kanji
    result = add_furigana_annotations("難しい", "ムズカシイ")
    assert result == snapshot(
        {
            "furigana_bracket": "難[むずか]しい",
            "furigana_ruby": "<ruby>難<rt>むずか</rt></ruby>しい",
            "furigana_parentheses": "難(むずか)しい",
            "hiragana_reading": "むずかしい",
        }
    )

    # Mixed kanji case
    result = add_furigana_annotations("読み書き", "ヨミカキ")
    assert result == snapshot(
        {
            "furigana_bracket": "読[よ]み書[か]き",
            "furigana_ruby": "<ruby>読<rt>よ</rt></ruby>み<ruby>書<rt>か</rt></ruby>き",
            "furigana_parentheses": "読(よ)み書(か)き",
            "hiragana_reading": "よみかき",
        }
    )


def test_edge_cases():
    """Test edge cases and error conditions."""
    # Empty strings
    result = align_furigana("", "")
    assert result == snapshot([("", None)])

    result = align_furigana("test", "")
    assert result == snapshot([("test", None)])

    result = align_furigana("", "test")
    assert result == snapshot([("", None)])

    # Identical strings
    result = align_furigana("同じ", "同じ")
    assert result == snapshot([("同じ", None)])


# TODO
def test_japanese_deinflection_1():
    parser = JapaneseParser()
    text = "置いていこう。"
    result = parser.parse(text, ParserConfig(which_parser="japanese_parser", parser_args={})).to_dict()
    result["orthography_set"].sort()
    result["lemma_set"].sort()
    assert result == snapshot(
        {
            "text": "置いていこう。",
            "segments": [
                {
                    "text": "置いていこう。",
                    "start_char": 0,
                    "end_char": 7,
                    "inner": {
                        "Sentence": {
                            "segments": [
                                {
                                    "sentence_idx": 0,
                                    "text": "置い",
                                    "start_char": 0,
                                    "end_char": 2,
                                    "inner": {"TokenSeg": {"idx": 0, "orthography": "置い"}},
                                    "attributes": {
                                        "lemma": "置く",
                                        "upos": "VERB",
                                        "xpos": "動詞-非自立可能",
                                        "dependency": (2, "advcl"),
                                        "misc": {
                                            "Inflection": "五段-カ行;連用形-イ音便",
                                            "Reading": "オイ",
                                            "furigana_bracket": "置[お]い",
                                            "furigana_ruby": "<ruby>置<rt>お</rt></ruby>い",
                                            "furigana_parentheses": "置(お)い",
                                            "hiragana_reading": "おい",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "て",
                                    "start_char": 2,
                                    "end_char": 3,
                                    "inner": {"TokenSeg": {"idx": 1, "orthography": "て"}},
                                    "attributes": {
                                        "lemma": "て",
                                        "upos": "SCONJ",
                                        "xpos": "助詞-接続助詞",
                                        "dependency": (0, "mark"),
                                        "misc": {
                                            "Reading": "テ",
                                            "furigana_bracket": "て",
                                            "furigana_ruby": "て",
                                            "furigana_parentheses": "て",
                                            "hiragana_reading": "て",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "いこう",
                                    "start_char": 3,
                                    "end_char": 6,
                                    "inner": {"TokenSeg": {"idx": 2, "orthography": "いこう"}},
                                    "attributes": {
                                        "lemma": "いく",
                                        "upos": "VERB",
                                        "xpos": "動詞-非自立可能",
                                        "dependency": (2, "ROOT"),
                                        "misc": {
                                            "Inflection": "五段-カ行;意志推量形",
                                            "Reading": "イコウ",
                                            "furigana_bracket": "いこう",
                                            "furigana_ruby": "いこう",
                                            "furigana_parentheses": "いこう",
                                            "hiragana_reading": "いこう",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "。",
                                    "start_char": 6,
                                    "end_char": 7,
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
                                    },
                                },
                            ]
                        }
                    },
                }
            ],
            "orthography_set": ["。", "いこう", "て", "置い"],
            "lemma_set": ["。", "いく", "て", "置く"],
            "parser_config": {"which_parser": "japanese_parser", "parser_args": {}},
        }
    )


def test_japanese_deinflection_2():
    parser = JapaneseParser()
    text = "作ってくれる。"
    result = parser.parse(text, ParserConfig(which_parser="japanese_parser", parser_args={})).to_dict()
    result["orthography_set"].sort()
    result["lemma_set"].sort()
    assert result == snapshot(
        {
            "text": "作ってくれる。",
            "segments": [
                {
                    "text": "作ってくれる。",
                    "start_char": 0,
                    "end_char": 7,
                    "inner": {
                        "Sentence": {
                            "segments": [
                                {
                                    "sentence_idx": 0,
                                    "text": "作っ",
                                    "start_char": 0,
                                    "end_char": 2,
                                    "inner": {"TokenSeg": {"idx": 0, "orthography": "作っ"}},
                                    "attributes": {
                                        "lemma": "作る",
                                        "upos": "VERB",
                                        "xpos": "動詞-一般",
                                        "dependency": (0, "ROOT"),
                                        "misc": {
                                            "Inflection": "五段-ラ行;連用形-促音便",
                                            "Reading": "ツクッ",
                                            "furigana_bracket": "作[つく]っ",
                                            "furigana_ruby": "<ruby>作<rt>つく</rt></ruby>っ",
                                            "furigana_parentheses": "作(つく)っ",
                                            "hiragana_reading": "つくっ",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "て",
                                    "start_char": 2,
                                    "end_char": 3,
                                    "inner": {"TokenSeg": {"idx": 1, "orthography": "て"}},
                                    "attributes": {
                                        "lemma": "て",
                                        "upos": "SCONJ",
                                        "xpos": "助詞-接続助詞",
                                        "dependency": (0, "mark"),
                                        "misc": {
                                            "Reading": "テ",
                                            "furigana_bracket": "て",
                                            "furigana_ruby": "て",
                                            "furigana_parentheses": "て",
                                            "hiragana_reading": "て",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "くれる",
                                    "start_char": 3,
                                    "end_char": 6,
                                    "inner": {"TokenSeg": {"idx": 2, "orthography": "くれる"}},
                                    "attributes": {
                                        "lemma": "くれる",
                                        "upos": "VERB",
                                        "xpos": "動詞-非自立可能",
                                        "dependency": (1, "fixed"),
                                        "misc": {
                                            "Inflection": "下一段-ラ行;終止形-一般",
                                            "Reading": "クレル",
                                            "furigana_bracket": "くれる",
                                            "furigana_ruby": "くれる",
                                            "furigana_parentheses": "くれる",
                                            "hiragana_reading": "くれる",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "。",
                                    "start_char": 6,
                                    "end_char": 7,
                                    "inner": "PunctuationSeg",
                                    "attributes": {
                                        "lemma": "。",
                                        "upos": "PUNCT",
                                        "xpos": "補助記号-句点",
                                        "dependency": (0, "punct"),
                                        "misc": {
                                            "Reading": "。",
                                            "furigana_bracket": "。",
                                            "furigana_ruby": "。",
                                            "furigana_parentheses": "。",
                                            "hiragana_reading": "。",
                                        },
                                    },
                                },
                            ]
                        }
                    },
                }
            ],
            "orthography_set": ["。", "くれる", "て", "作っ"],
            "lemma_set": ["。", "くれる", "て", "作る"],
            "parser_config": {"which_parser": "japanese_parser", "parser_args": {}},
        }
    )


def test_japanese_deinflection_3():
    parser = JapaneseParser()
    text = "しまった。"
    result = parser.parse(text, ParserConfig(which_parser="japanese_parser", parser_args={})).to_dict()
    result["orthography_set"].sort()
    result["lemma_set"].sort()
    assert result == snapshot(
        {
            "text": "しまった。",
            "segments": [
                {
                    "text": "しまった。",
                    "start_char": 0,
                    "end_char": 5,
                    "inner": {
                        "Sentence": {
                            "segments": [
                                {
                                    "sentence_idx": 0,
                                    "text": "しまっ",
                                    "start_char": 0,
                                    "end_char": 3,
                                    "inner": {"TokenSeg": {"idx": 0, "orthography": "しまっ"}},
                                    "attributes": {
                                        "lemma": "しまう",
                                        "upos": "VERB",
                                        "xpos": "動詞-非自立可能",
                                        "dependency": (0, "ROOT"),
                                        "misc": {
                                            "Inflection": "五段-ワア行;連用形-促音便",
                                            "Reading": "シマッ",
                                            "furigana_bracket": "しまっ",
                                            "furigana_ruby": "しまっ",
                                            "furigana_parentheses": "しまっ",
                                            "hiragana_reading": "しまっ",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "た",
                                    "start_char": 3,
                                    "end_char": 4,
                                    "inner": {"TokenSeg": {"idx": 1, "orthography": "た"}},
                                    "attributes": {
                                        "lemma": "た",
                                        "upos": "AUX",
                                        "xpos": "助動詞",
                                        "dependency": (0, "aux"),
                                        "misc": {
                                            "Inflection": "助動詞-タ;終止形-一般",
                                            "Reading": "タ",
                                            "furigana_bracket": "た",
                                            "furigana_ruby": "た",
                                            "furigana_parentheses": "た",
                                            "hiragana_reading": "た",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "。",
                                    "start_char": 4,
                                    "end_char": 5,
                                    "inner": "PunctuationSeg",
                                    "attributes": {
                                        "lemma": "。",
                                        "upos": "PUNCT",
                                        "xpos": "補助記号-句点",
                                        "dependency": (0, "punct"),
                                        "misc": {
                                            "Reading": "。",
                                            "furigana_bracket": "。",
                                            "furigana_ruby": "。",
                                            "furigana_parentheses": "。",
                                            "hiragana_reading": "。",
                                        },
                                    },
                                },
                            ]
                        }
                    },
                }
            ],
            "orthography_set": ["。", "しまっ", "た"],
            "lemma_set": ["。", "しまう", "た"],
            "parser_config": {"which_parser": "japanese_parser", "parser_args": {}},
        }
    )


def test_japanese_deinflection_4():
    parser = JapaneseParser()
    text = "立たなかった。"
    result = parser.parse(text, ParserConfig(which_parser="japanese_parser", parser_args={})).to_dict()
    result["orthography_set"].sort()
    result["lemma_set"].sort()
    assert result == snapshot(
        {
            "text": "立たなかった。",
            "segments": [
                {
                    "text": "立たなかった。",
                    "start_char": 0,
                    "end_char": 7,
                    "inner": {
                        "Sentence": {
                            "segments": [
                                {
                                    "sentence_idx": 0,
                                    "text": "立た",
                                    "start_char": 0,
                                    "end_char": 2,
                                    "inner": {"TokenSeg": {"idx": 0, "orthography": "立た"}},
                                    "attributes": {
                                        "lemma": "立つ",
                                        "upos": "VERB",
                                        "xpos": "動詞-一般",
                                        "dependency": (0, "ROOT"),
                                        "misc": {
                                            "Inflection": "五段-タ行;未然形-一般",
                                            "Reading": "タタ",
                                            "furigana_bracket": "立た",
                                            "furigana_ruby": "立た",
                                            "furigana_parentheses": "立た",
                                            "hiragana_reading": "たた",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "なかっ",
                                    "start_char": 2,
                                    "end_char": 5,
                                    "inner": {"TokenSeg": {"idx": 1, "orthography": "なかっ"}},
                                    "attributes": {
                                        "lemma": "ない",
                                        "upos": "AUX",
                                        "xpos": "助動詞",
                                        "dependency": (0, "aux"),
                                        "misc": {
                                            "Inflection": "助動詞-ナイ;連用形-促音便",
                                            "Reading": "ナカッ",
                                            "furigana_bracket": "なかっ",
                                            "furigana_ruby": "なかっ",
                                            "furigana_parentheses": "なかっ",
                                            "hiragana_reading": "なかっ",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "た",
                                    "start_char": 5,
                                    "end_char": 6,
                                    "inner": {"TokenSeg": {"idx": 2, "orthography": "た"}},
                                    "attributes": {
                                        "lemma": "た",
                                        "upos": "AUX",
                                        "xpos": "助動詞",
                                        "dependency": (0, "aux"),
                                        "misc": {
                                            "Inflection": "助動詞-タ;終止形-一般",
                                            "Reading": "タ",
                                            "furigana_bracket": "た",
                                            "furigana_ruby": "た",
                                            "furigana_parentheses": "た",
                                            "hiragana_reading": "た",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "。",
                                    "start_char": 6,
                                    "end_char": 7,
                                    "inner": "PunctuationSeg",
                                    "attributes": {
                                        "lemma": "。",
                                        "upos": "PUNCT",
                                        "xpos": "補助記号-句点",
                                        "dependency": (0, "punct"),
                                        "misc": {
                                            "Reading": "。",
                                            "furigana_bracket": "。",
                                            "furigana_ruby": "。",
                                            "furigana_parentheses": "。",
                                            "hiragana_reading": "。",
                                        },
                                    },
                                },
                            ]
                        }
                    },
                }
            ],
            "orthography_set": ["。", "た", "なかっ", "立た"],
            "lemma_set": ["。", "た", "ない", "立つ"],
            "parser_config": {"which_parser": "japanese_parser", "parser_args": {}},
        }
    )


def test_japanese_deinflection_5():
    parser = JapaneseParser()
    text = "なってしまった。"
    result = parser.parse(text, ParserConfig(which_parser="japanese_parser", parser_args={})).to_dict()
    result["orthography_set"].sort()
    result["lemma_set"].sort()
    assert result == snapshot(
        {
            "text": "なってしまった。",
            "segments": [
                {
                    "text": "なってしまった。",
                    "start_char": 0,
                    "end_char": 8,
                    "inner": {
                        "Sentence": {
                            "segments": [
                                {
                                    "sentence_idx": 0,
                                    "text": "なっ",
                                    "start_char": 0,
                                    "end_char": 2,
                                    "inner": {"TokenSeg": {"idx": 0, "orthography": "なっ"}},
                                    "attributes": {
                                        "lemma": "なる",
                                        "upos": "VERB",
                                        "xpos": "動詞-非自立可能",
                                        "dependency": (0, "ROOT"),
                                        "misc": {
                                            "Inflection": "五段-ラ行;連用形-促音便",
                                            "Reading": "ナッ",
                                            "furigana_bracket": "なっ",
                                            "furigana_ruby": "なっ",
                                            "furigana_parentheses": "なっ",
                                            "hiragana_reading": "なっ",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "て",
                                    "start_char": 2,
                                    "end_char": 3,
                                    "inner": {"TokenSeg": {"idx": 1, "orthography": "て"}},
                                    "attributes": {
                                        "lemma": "て",
                                        "upos": "SCONJ",
                                        "xpos": "助詞-接続助詞",
                                        "dependency": (0, "mark"),
                                        "misc": {
                                            "Reading": "テ",
                                            "furigana_bracket": "て",
                                            "furigana_ruby": "て",
                                            "furigana_parentheses": "て",
                                            "hiragana_reading": "て",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "しまっ",
                                    "start_char": 3,
                                    "end_char": 6,
                                    "inner": {"TokenSeg": {"idx": 2, "orthography": "しまっ"}},
                                    "attributes": {
                                        "lemma": "しまう",
                                        "upos": "VERB",
                                        "xpos": "動詞-非自立可能",
                                        "dependency": (1, "fixed"),
                                        "misc": {
                                            "Inflection": "五段-ワア行;連用形-促音便",
                                            "Reading": "シマッ",
                                            "furigana_bracket": "しまっ",
                                            "furigana_ruby": "しまっ",
                                            "furigana_parentheses": "しまっ",
                                            "hiragana_reading": "しまっ",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "た",
                                    "start_char": 6,
                                    "end_char": 7,
                                    "inner": {"TokenSeg": {"idx": 3, "orthography": "た"}},
                                    "attributes": {
                                        "lemma": "た",
                                        "upos": "AUX",
                                        "xpos": "助動詞",
                                        "dependency": (0, "aux"),
                                        "misc": {
                                            "Inflection": "助動詞-タ;終止形-一般",
                                            "Reading": "タ",
                                            "furigana_bracket": "た",
                                            "furigana_ruby": "た",
                                            "furigana_parentheses": "た",
                                            "hiragana_reading": "た",
                                        },
                                    },
                                },
                                {
                                    "sentence_idx": 0,
                                    "text": "。",
                                    "start_char": 7,
                                    "end_char": 8,
                                    "inner": "PunctuationSeg",
                                    "attributes": {
                                        "lemma": "。",
                                        "upos": "PUNCT",
                                        "xpos": "補助記号-句点",
                                        "dependency": (0, "punct"),
                                        "misc": {
                                            "Reading": "。",
                                            "furigana_bracket": "。",
                                            "furigana_ruby": "。",
                                            "furigana_parentheses": "。",
                                            "hiragana_reading": "。",
                                        },
                                    },
                                },
                            ]
                        }
                    },
                }
            ],
            "orthography_set": ["。", "しまっ", "た", "て", "なっ"],
            "lemma_set": ["。", "しまう", "た", "て", "なる"],
            "parser_config": {"which_parser": "japanese_parser", "parser_args": {}},
        }
    )
