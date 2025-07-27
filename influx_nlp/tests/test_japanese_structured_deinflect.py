from __future__ import annotations
from inline_snapshot import snapshot
from lib.annotation import ParserConfig
from lib.parsing import JapaneseParser
from lib.japanese_deinflect.deinflect import Deinflector
from lib.japanese_deinflect.word_type import WordType
from lib.japanese_deinflect.derivations import rules
from lib.annotation import *

deinflector = Deinflector()
parser = JapaneseParser()


def test_ambiguous_deinflections():
    """Test cases with ambiguous deinflections that return multiple possibilities."""

    results_itte = deinflector.unconjugate('いって')
    assert len(results_itte) == snapshot(13)
    assert results_itte == snapshot(
        [
            {'base': 'いう', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いつ', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いる', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いう', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いつ', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いる', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いって', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'いっる', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いっつ', 'derivation_sequence': {'derivations': [WordType.IMPERATIVE], 'word_form_progression': ['いって']}},
            {'base': 'いっつ', 'derivation_sequence': {'derivations': [WordType.IMPERATIVE], 'word_form_progression': ['いって']}},
            {'base': 'いっる', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いっつ', 'derivation_sequence': {'derivations': [WordType.POTENTIAL, WordType.MASU_STEM], 'word_form_progression': ['いってる', 'いって']}},
            {'base': 'いってる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['いって']}},
        ]
    )

    results_shita = deinflector.unconjugate('した')
    assert len(results_shita) == snapshot(8)
    assert results_shita == snapshot(
        [
            {'base': 'する', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'する', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'す', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'す', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'した', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'しる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'しる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'したる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['した']}},
        ]
    )

    results_aru = deinflector.unconjugate('ある')
    assert len(results_aru) == snapshot(4)
    assert results_aru == snapshot(
        [
            {'base': 'ある', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'ある', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'ある', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'あるる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['ある']}},
        ]
    )

    results_iru = deinflector.unconjugate('いる')
    assert len(results_iru) == snapshot(4)
    assert results_iru == snapshot(
        [
            {'base': 'いる', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'いる', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'いる', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'いるる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['いる']}},
        ]
    )

    results_kita = deinflector.unconjugate('きた')
    assert len(results_kita) == snapshot(4)
    assert results_kita == snapshot(
        [
            {'base': 'きた', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'きる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['きた']}},
            {'base': 'きる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['きた']}},
            {'base': 'きたる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['きた']}},
        ]
    )

    results_katta = deinflector.unconjugate('かった')
    assert len(results_katta) == snapshot(10)
    assert results_katta == snapshot(
        [
            {'base': 'かう', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かつ', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かう', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かつ', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かった', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'かっる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かっる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かったる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['かった']}},
        ]
    )

    results_totta = deinflector.unconjugate('取った')
    assert len(results_totta) == snapshot(10)
    assert results_totta == snapshot(
        [
            {'base': '取る', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取る', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取う', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取つ', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取う', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取つ', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取った', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': '取っる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取っる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取ったる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['取った']}},
        ]
    )


def test_some_future_test():
    """Deinflection filters by what spacy thinks."""
    result = deinflector.unconjugate('殺されるな')
    assert len(result) == snapshot(22)
    assert result == snapshot(
        [
            {'base': '殺す', 'derivation_sequence': {'derivations': [WordType.PASSIVE, WordType.NA_COMMAND], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺す', 'derivation_sequence': {'derivations': [WordType.PASSIVE, WordType.NA_COMMAND], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺す', 'derivation_sequence': {'derivations': [WordType.PASSIVE, WordType.NA_PARTICLE], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺する', 'derivation_sequence': {'derivations': [WordType.PASSIVE, WordType.NA_COMMAND], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺する', 'derivation_sequence': {'derivations': [WordType.PASSIVE, WordType.NA_COMMAND], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺する', 'derivation_sequence': {'derivations': [WordType.PASSIVE, WordType.NA_PARTICLE], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺さる', 'derivation_sequence': {'derivations': [WordType.POTENTIAL, WordType.NA_COMMAND], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺さる', 'derivation_sequence': {'derivations': [WordType.POTENTIAL, WordType.NA_COMMAND], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺さる', 'derivation_sequence': {'derivations': [WordType.POTENTIAL, WordType.NA_COMMAND], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺さる', 'derivation_sequence': {'derivations': [WordType.POTENTIAL, WordType.NA_COMMAND], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺さる', 'derivation_sequence': {'derivations': [WordType.POTENTIAL, WordType.NA_PARTICLE], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺さる', 'derivation_sequence': {'derivations': [WordType.POTENTIAL, WordType.NA_PARTICLE], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺される', 'derivation_sequence': {'derivations': [WordType.NA_COMMAND], 'word_form_progression': ['殺されるな']}},
            {'base': '殺される', 'derivation_sequence': {'derivations': [WordType.NA_COMMAND], 'word_form_progression': ['殺されるな']}},
            {'base': '殺される', 'derivation_sequence': {'derivations': [WordType.NA_COMMAND], 'word_form_progression': ['殺されるな']}},
            {'base': '殺される', 'derivation_sequence': {'derivations': [WordType.NA_COMMAND], 'word_form_progression': ['殺されるな']}},
            {'base': '殺される', 'derivation_sequence': {'derivations': [WordType.NA_PARTICLE], 'word_form_progression': ['殺されるな']}},
            {'base': '殺される', 'derivation_sequence': {'derivations': [WordType.NA_PARTICLE], 'word_form_progression': ['殺されるな']}},
            {'base': '殺されるな', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': '殺されるる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM, WordType.NASAI], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺されるる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM, WordType.NASAI], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺されるなる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['殺されるな']}},
        ]
    )

    text = "殺されるな"
    result = parser.parse(text, ParserConfig("enhanced_japanese", {})).segments
    assert result == snapshot(
        [
            DocSegV2(
                text='殺されるな',
                start_char=0,
                end_char=5,
                inner=DocSegSentence(
                    segments=[
                        SentSegV2(
                            sentence_idx=0,
                            text='殺さ',
                            start_char=0,
                            end_char=2,
                            inner=SentSegTokenSeg(idx=0, orthography='殺さ'),
                            attributes=SegAttribute(
                                lemma='殺す',
                                upos='VERB',
                                xpos='動詞-一般',
                                dependency=(0, 'ROOT'),
                                misc={'Inflection': '五段-サ行;未然形-一般', 'Reading': 'コロサ', 'furigana_bracket': '殺[ころ]さ', 'furigana_ruby': '<ruby>殺<rt>ころ</rt></ruby>さ', 'furigana_parentheses': '殺(ころ)さ', 'hiragana_reading': 'ころさ'},
                            ),
                        ),
                        SentSegV2(
                            sentence_idx=0,
                            text='れる',
                            start_char=2,
                            end_char=4,
                            inner=SentSegTokenSeg(idx=1, orthography='れる'),
                            attributes=SegAttribute(lemma='れる', upos='AUX', xpos='助動詞', dependency=(0, 'aux'), misc={'Inflection': '助動詞-レル;終止形-一般', 'Reading': 'レル', 'furigana_bracket': 'れる', 'furigana_ruby': 'れる', 'furigana_parentheses': 'れる', 'hiragana_reading': 'れる'}),
                        ),
                        SentSegV2(
                            sentence_idx=0,
                            text='な',
                            start_char=4,
                            end_char=5,
                            inner=SentSegTokenSeg(idx=2, orthography='な'),
                            attributes=SegAttribute(lemma='な', upos='PART', xpos='助詞-終助詞', dependency=(0, 'mark'), misc={'Reading': 'ナ', 'furigana_bracket': 'な', 'furigana_ruby': 'な', 'furigana_parentheses': 'な', 'hiragana_reading': 'な'}),
                        ),
                    ]
                ),
            )
        ]
    )


def analyze_word(word: str) -> str:
    results = deinflector.unconjugate(word)

    if not results:
        return f"No results found for '{word}'"

    output = []
    output.append(f"Analysis of '{word}':")
    output.append(f"Dictionary form: {results[0]['base']}")
    output.append("")

    derivations = results[0]["derivation_sequence"]["derivations"]
    word_progression = results[0]["derivation_sequence"]["word_form_progression"]

    if not derivations:
        output.append("This is already in dictionary form.")
        return "\n".join(output)

    output.append("Derivation steps:")
    current_word = results[0]["base"]

    for i, (derivation_type, next_word) in enumerate(zip(derivations, word_progression)):

        output.append(f"{i+1}. {current_word} → {next_word}")
        output.append(f"   Form: {derivation_type.value}")

        current_word = next_word
        output.append("")

    return "\n".join(output)


def test_analysis():
    """Test that grammar explanations are generated correctly for example words."""
    example_words = [
        "行きます",
        "食べられない",
        "読んでいた",
        "書かれる",
        "飲みたい",
    ]

    output_parts = []
    for word in example_words:
        analysis = analyze_word(word)
        output_parts.append(analysis)
        output_parts.append("-" * 50)
        output_parts.append("")

    if output_parts:
        output_parts = output_parts[:-2]

    combined_output = "\n".join(output_parts)
    assert combined_output == snapshot(
        """\
Analysis of '行きます':
Dictionary form: 行く

Derivation steps:
1. 行く → 行き
   Form: ます Stem

2. 行き → 行きます
   Form: ます Polite

--------------------------------------------------

Analysis of '食べられない':
Dictionary form: 食べる

Derivation steps:
1. 食べる → 食べられる
   Form: Potential Or Passive Form

2. 食べられる → 食べられない
   Form: ない Negative

--------------------------------------------------

Analysis of '読んでいた':
Dictionary form: 読む

Derivation steps:
1. 読む → 読んで
   Form: て・で Form

2. 読んで → 読んでいる
   Form: ている・でいる Continuing State/Result

3. 読んでいる → 読んでいた
   Form: Plain Past

--------------------------------------------------

Analysis of '書かれる':
Dictionary form: 書く

Derivation steps:
1. 書く → 書かれる
   Form: Passive Form

--------------------------------------------------

Analysis of '飲みたい':
Dictionary form: 飲む

Derivation steps:
1. 飲む → 飲み
   Form: ます Stem

2. 飲み → 飲みたい
   Form: たい Want To Do
"""
    )
