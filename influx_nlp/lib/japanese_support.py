"""
Japanese language support for furigana alignment and annotation.

This module provides functions to align original Japanese text with readings
to determine which parts need furigana annotations.
"""

from typing import List, Tuple, Dict, Any
import wanakana


def align_furigana(original: str, reading: str) -> List[Tuple[str, str | None]]:
    """
    Align original text with reading to determine which parts need furigana.
    Handles mixed kanji/kana by finding multiple alignment points within the word.

    Args:
        original: Original token (may contain kanji and kana)
        reading: Complete hiragana reading for the token

    Returns:
        List of tuples (text, furigana) where furigana is None if no annotation needed

    Examples:
        align_furigana("難しい", "むずかしい") → [("難", "むずか"), ("し", None), ("い", None)]
        align_furigana("読み書き", "よみかき") → [("読", "よ"), ("み", None), ("書", "か"), ("き", None)]
        align_furigana("漢字", "かんじ") → [("漢字", "かんじ")]
    """
    if original == "" or reading == "":
        return [(original, None)]

    if original == reading:
        return [(original, None)]

    result = []
    orig_idx = 0
    read_idx = 0

    while orig_idx < len(original) and read_idx < len(reading):
        orig_char = original[orig_idx]

        if wanakana.is_kanji(orig_char):
            # Start of a kanji sequence - find where it ends
            kanji_start = orig_idx
            while orig_idx < len(original) and wanakana.is_kanji(original[orig_idx]):
                orig_idx += 1

            kanji_text = original[kanji_start:orig_idx]

            # Find corresponding reading - look ahead for next kana match
            read_start = read_idx

            # Look for the next matching kana in original text
            next_kana_in_orig = None
            next_kana_pos = orig_idx

            if orig_idx < len(original):
                next_kana_in_orig = original[orig_idx]
                # Convert to hiragana for comparison if it's katakana
                if wanakana.is_katakana(next_kana_in_orig):
                    next_kana_hiragana = wanakana.to_hiragana(next_kana_in_orig)
                elif wanakana.is_hiragana(next_kana_in_orig):
                    next_kana_hiragana = next_kana_in_orig
                else:
                    next_kana_hiragana = next_kana_in_orig

                # Find this kana in the remaining reading
                remaining_reading = reading[read_idx:]
                if next_kana_hiragana in remaining_reading:
                    kana_pos_in_reading = remaining_reading.index(next_kana_hiragana)
                    read_idx += kana_pos_in_reading
                else:
                    # No matching kana found, consume rest of reading
                    read_idx = len(reading)
            else:
                # No more characters in original, consume rest of reading
                read_idx = len(reading)

            reading_part = reading[read_start:read_idx]
            result.append((kanji_text, reading_part))

        elif wanakana.is_hiragana(orig_char):
            # Hiragana character - should match reading directly
            if read_idx < len(reading) and orig_char == reading[read_idx]:
                result.append((orig_char, None))
                orig_idx += 1
                read_idx += 1
            else:
                # Mismatch - skip or handle gracefully
                result.append((orig_char, None))
                orig_idx += 1
                # Don't advance read_idx to avoid misalignment

        elif wanakana.is_katakana(orig_char):
            # Katakana character - no furigana needed (already readable)
            # But we need to advance the reading index by the hiragana equivalent
            katakana_char = orig_char
            hiragana_equiv = wanakana.to_hiragana(katakana_char)

            if read_idx < len(reading) and reading[read_idx] == hiragana_equiv:
                read_idx += 1

            result.append((katakana_char, None))  # No furigana for katakana
            orig_idx += 1

        else:
            # Other characters (punctuation, etc.) - no furigana
            result.append((orig_char, None))
            orig_idx += 1

    # Handle any remaining characters
    if orig_idx < len(original):
        result.append((original[orig_idx:], None))

    return result


def format_furigana(alignment: List[Tuple[str, str | None]], format_type: str = "bracket") -> str:
    """
    Format the alignment result into various furigana notations.

    Args:
        alignment: Result from align_furigana functions
        format_type: "bracket", "ruby", or "parentheses"

    Returns:
        Formatted string with furigana annotations
    """
    if format_type == "bracket":
        result = ""
        for text, furigana in alignment:
            if furigana:
                result += f"{text}[{furigana}]"
            else:
                result += text
        return result

    elif format_type == "ruby":
        result = ""
        for text, furigana in alignment:
            if furigana:
                result += f"<ruby>{text}<rt>{furigana}</rt></ruby>"
            else:
                result += text
        return result

    elif format_type == "parentheses":
        result = ""
        for text, furigana in alignment:
            if furigana:
                result += f"{text}({furigana})"
            else:
                result += text
        return result

    return str(alignment)


def add_furigana_annotations(token_text: str, reading: str) -> Dict[str, Any]:
    """
    Generate furigana annotations for a token and add them to misc field.

    Args:
        token_text: Original token text
        reading: Katakana reading from spacy

    Returns:
        Dictionary with furigana annotations to add to misc field
    """
    # Convert katakana reading to hiragana
    hiragana_reading = wanakana.to_hiragana(reading)

    # Generate alignment
    alignment = align_furigana(token_text, hiragana_reading)

    # Format in different styles
    annotations = {
        "furigana_bracket": format_furigana(alignment, "bracket"),
        "furigana_ruby": format_furigana(alignment, "ruby"),
        "furigana_parentheses": format_furigana(alignment, "parentheses"),
        "hiragana_reading": hiragana_reading,
    }

    return annotations
