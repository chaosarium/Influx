from typing import List, Tuple, Dict, Any
import wanakana
from wanakana import is_kanji, is_hiragana, is_katakana, to_hiragana


# align_furigana("難しい", "むずかしい") -> [("難", "むずか"), ("し", None), ("い", None)]
# align_furigana("読み書き", "よみかき") -> [("読", "よ"), ("み", None), ("書", "か"), ("き", None)]
def align_furigana(original: str, reading: str) -> List[Tuple[str, str | None]]:
    if original == "" or reading == "" or original == reading:
        return [(original, None)]

    def is_non_kana(char):
        return is_kanji(char) or char == "々"

    if all(is_non_kana(char) for char in original):
        return [(original, reading)]

    result = []
    orig_idx = 0
    read_idx = 0

    while orig_idx < len(original) and read_idx < len(reading):
        orig_char = original[orig_idx]

        if is_non_kana(orig_char):

            kanji_start = orig_idx
            while orig_idx < len(original) and is_non_kana(original[orig_idx]):
                orig_idx += 1
            kanji_text = original[kanji_start:orig_idx]

            read_start = read_idx
            if orig_idx < len(original):
                next_kana_hiragana = to_hiragana(original[orig_idx])

                remaining_reading = reading[read_idx:]
                if next_kana_hiragana in remaining_reading:
                    kana_pos_in_reading = remaining_reading.index(next_kana_hiragana)
                    read_idx += kana_pos_in_reading
                else:
                    # weird... just consume the rest?
                    read_idx = len(reading)
            else:
                # done walking original, consume the rest of reading
                read_idx = len(reading)

            reading_part = reading[read_start:read_idx]
            result.append((kanji_text, reading_part))

        elif is_hiragana(orig_char):
            result.append((orig_char, None))
            if read_idx < len(reading) and orig_char == reading[read_idx]:
                read_idx += 1
            orig_idx += 1

        elif is_katakana(orig_char):
            result.append((orig_char, None))  # No furigana for katakana
            katakana_char = orig_char
            hiragana_equiv = to_hiragana(katakana_char)
            if read_idx < len(reading) and reading[read_idx] == hiragana_equiv:
                read_idx += 1
            orig_idx += 1

        else:
            # some weird character...
            result.append((orig_char, None))
            orig_idx += 1

    if orig_idx < len(original):
        result.append((original[orig_idx:], None))

    return result


def format_furigana(alignment: List[Tuple[str, str | None]], format_type: str) -> str:
    def format_one(text: str, furigana: str | None) -> str:
        match format_type:
            case "bracket":
                return f"{text}[{furigana}]"
            case "parentheses":
                return f"{text}({furigana})"
            case "ruby":
                return f"<ruby>{text}<rt>{furigana}</rt></ruby>"
            case _:
                raise ValueError(f"Unknown format type: {format_type}")

    result: List[str] = []
    for text, furigana in alignment:
        if furigana:
            result.append(format_one(text, furigana))
        else:
            result.append(text)

    return "".join(result)


def add_furigana_annotations(token_text: str, reading: str) -> Dict[str, Any]:
    hiragana_reading = wanakana.to_hiragana(reading)
    alignment = align_furigana(token_text, hiragana_reading)
    return {
        "furigana_bracket": format_furigana(alignment, "bracket"),
        "furigana_ruby": format_furigana(alignment, "ruby"),
        "furigana_parentheses": format_furigana(alignment, "parentheses"),
        "hiragana_reading": hiragana_reading,
    }
