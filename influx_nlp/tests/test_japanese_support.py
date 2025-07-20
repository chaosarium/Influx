from __future__ import annotations
from inline_snapshot import snapshot
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
            "furigana_alignment": [("これ", None)],
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
            "furigana_alignment": [("難", "むずか"), ("し", None), ("い", None)],
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
            "furigana_alignment": [("読", "よ"), ("み", None), ("書", "か"), ("き", None)],
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
