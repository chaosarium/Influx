def align_furigana(original, reading):
    """
    Align original text with reading to determine which parts need furigana.
    
    Args:
        original (str): Original token (may contain kanji and kana)
        reading (str): Complete hiragana reading for the token
    
    Returns:
        list: List of tuples (text, furigana) where furigana is None if no annotation needed
    
    Examples:
        align_furigana("難しい", "むずかしい") → [("難", "むずか"), ("しい", None)]
        align_furigana("読み書き", "よみかき") → [("読", "よ"), ("み", None), ("書", "か"), ("き", None)]
        align_furigana("漢字", "かんじ") → [("漢字", "かんじ")]
    """
    if not original or not reading:
        return [(original, None)]
    
    # If original and reading are identical, no furigana needed
    if original == reading:
        return [(original, None)]
    
    # Find the longest common suffix
    suffix_len = 0
    min_len = min(len(original), len(reading))
    
    for i in range(1, min_len + 1):
        if original[-i] == reading[-i]:
            suffix_len = i
        else:
            break
    
    # Split based on common suffix
    if suffix_len > 0:
        # There's a matching suffix (okurigana)
        kanji_part = original[:-suffix_len]
        kana_part = original[-suffix_len:]
        reading_part = reading[:-suffix_len]
        
        result = []
        
        # Handle the kanji part
        if kanji_part:
            if reading_part:
                result.append((kanji_part, reading_part))
            else:
                result.append((kanji_part, None))
        
        # Handle the kana part (no furigana needed)
        if kana_part:
            result.append((kana_part, None))
        
        return result
    else:
        # No common suffix - entire word needs furigana
        return [(original, reading)]


def align_furigana_advanced(original, reading):
    """
    Advanced alignment that handles mixed kanji/kana better by finding
    multiple alignment points within the word.
    
    Args:
        original (str): Original token
        reading (str): Complete hiragana reading
    
    Returns:
        list: List of tuples (text, furigana)
    """
    try:
        import wanakana
    except ImportError:
        # Fallback to basic Unicode checks if wanakana not available
        import unicodedata
        def is_kanji(char):
            return 'CJK UNIFIED IDEOGRAPH' in unicodedata.name(char, '')
        def is_hiragana(char):
            return '\u3040' <= char <= '\u309f'
        def is_katakana(char):
            return '\u30a0' <= char <= '\u30ff'
        def to_hiragana(text):
            # Simple katakana to hiragana conversion
            result = ""
            for char in text:
                if '\u30a1' <= char <= '\u30f6':  # katakana range
                    result += chr(ord(char) - 0x60)  # convert to hiragana
                else:
                    result += char
            return result
    else:
        def is_kanji(char):
            return wanakana.is_kanji(char)
        def is_hiragana(char):
            return wanakana.is_hiragana(char)
        def is_katakana(char):
            return wanakana.is_katakana(char)
        def to_hiragana(text):
            return wanakana.to_hiragana(text)
    
    if not original or not reading:
        return [(original, None)]
    
    if original == reading:
        return [(original, None)]
    
    result = []
    orig_idx = 0
    read_idx = 0
    
    while orig_idx < len(original) and read_idx < len(reading):
        orig_char = original[orig_idx]
        
        if is_kanji(orig_char):
            # Start of a kanji sequence - find where it ends
            kanji_start = orig_idx
            while orig_idx < len(original) and is_kanji(original[orig_idx]):
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
                if is_katakana(next_kana_in_orig):
                    next_kana_hiragana = to_hiragana(next_kana_in_orig)
                elif is_hiragana(next_kana_in_orig):
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
            
        elif is_hiragana(orig_char):
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
                
        elif is_katakana(orig_char):
            # Katakana character - no furigana needed (already readable)
            # But we need to advance the reading index by the hiragana equivalent
            katakana_char = orig_char
            hiragana_equiv = to_hiragana(katakana_char)
            
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


def format_furigana(alignment, format_type="bracket"):
    """
    Format the alignment result into various furigana notations.
    
    Args:
        alignment: Result from align_furigana functions
        format_type: "bracket", "ruby", or "parentheses"
    
    Returns:
        str: Formatted string with furigana annotations
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


# Test the functions
if __name__ == "__main__":
    # Check if wanakana is available
    try:
        import wanakana
        print("Using wanakana library for character detection and conversion")
    except ImportError:
        print("wanakana not available, using fallback Unicode methods")
        print("To install: pip install wanakana")
    
    test_cases = [
        ("難しい", "むずかしい"),
        ("読み書き", "よみかき"),
        ("漢字", "かんじ"),
        ("食べる", "たべる"),
        ("ひらがな", "ひらがな"),
        ("東京", "とうきょう"),
        ("行く", "いく"),
        ("美しい", "うつくしい"),
        # Mixed hiragana/katakana cases
        ("コンピューター", "こんぴゅーたー"),  # katakana → hiragana
        ("データベース", "でーたべーす"),      # katakana → hiragana
        ("アプリ", "あぷり"),               # katakana → hiragana
        ("マンガ", "まんが"),               # katakana → hiragana
        ("テレビ", "てれび"),               # katakana → hiragana
        ("カメラ", "かめら"),               # katakana → hiragana
        ("サッカー", "さっかー"),           # katakana → hiragana
        # Mixed script with kanji
        ("映画館", "えいがかん"),           # all kanji
        ("図書館", "としょかん"),           # all kanji
        ("新幹線", "しんかんせん"),         # all kanji
        ("お母さん", "おかあさん"),         # hiragana + kanji + hiragana
        ("お父さん", "おとうさん"),         # hiragana + kanji + hiragana
        ("彼女", "かのじょ"),              # kanji only
        # Katakana with kanji
        ("日本人", "にほんじん"),          # kanji only
        ("外国人", "がいこくじん"),        # kanji only
        # Edge cases with mixed scripts
        ("ひらがな漢字", "ひらがなかんじ"),  # hiragana + kanji
        ("カタカナ漢字", "かたかなかんじ"),  # katakana + kanji (hypothetical)
        ("漢字カタカナ", "かんじかたかな"),  # kanji + katakana
        ("漢字ひらがな", "かんじひらがな"),  # kanji + hiragana
        ("あいうえお", "あいうえお"),       # all hiragana (identical)
        ("アイウエオ", "あいうえお"),       # katakana → hiragana
        # Realistic mixed cases
        ("お寿司", "おすし"),              # hiragana + kanji
        ("コーヒー店", "こーひーてん"),     # katakana + kanji
        ("アニメ好き", "あにめずき"),       # katakana + kanji
    ]
    
    print("=== Basic Alignment ===")
    for original, reading in test_cases:
        alignment = align_furigana(original, reading)
        formatted = format_furigana(alignment, "bracket")
        print(f"{original} ({reading}) → {formatted}")
        print(f"  Alignment: {alignment}")
    
    print("\n=== Advanced Alignment ===")
    for original, reading in test_cases:
        alignment = align_furigana_advanced(original, reading)
        formatted = format_furigana(alignment, "bracket")
        print(f"{original} ({reading}) → {formatted}")
        print(f"  Alignment: {alignment}")
    
    print("\n=== Different Formats ===")
    alignment = align_furigana("難しい", "むずかしい")
    print("Bracket:", format_furigana(alignment, "bracket"))
    print("Ruby:", format_furigana(alignment, "ruby"))
    print("Parentheses:", format_furigana(alignment, "parentheses"))