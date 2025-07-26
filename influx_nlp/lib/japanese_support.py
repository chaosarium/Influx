from typing import List, Tuple, Dict, Any
import wanakana

# align_furigana("難しい", "むずかしい") -> [("難", "むずか"), ("し", None), ("い", None)]
# align_furigana("読み書き", "よみかき") -> [("読", "よ"), ("み", None), ("書", "か"), ("き", None)]
def align_furigana(original: str, reading: str) -> List[Tuple[str, str | None]]:
    if original == "" or reading == "" or original == reading:
        return [(original, None)]
    
    def is_non_kana(char):
        return wanakana.is_kanji(char) or char == "々"

    if all(is_non_kana(char) for char in original):
        return [(original, reading)]

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

    if orig_idx < len(original):
        result.append((original[orig_idx:], None))

    return result


def format_furigana(alignment: List[Tuple[str, str | None]], format_type: str) -> str:
    def format_one(text: str, furigana: str | None) -> str:
        match format_type :
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
