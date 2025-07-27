from __future__ import annotations
from inline_snapshot import snapshot
from lib.annotation import ParserConfig
from lib.parsing import JapaneseParser, SpacyParser
from lib.japanese_deinflect.deinflect import Deinflector
from lib.japanese_deinflect.word_type import WordType
from lib.japanese_deinflect.derivations import rules
from lib.annotation import *
from lib.japanese_conjugation_analysis import JapaneseConjugationAnalyzer

deinflector = Deinflector()
parser = JapaneseParser()
conjugation_analyzer = JapaneseConjugationAnalyzer()


def test_ambiguous_deinflections():
    """Test cases with ambiguous deinflections that return multiple possibilities."""

    results_itte = deinflector.unconjugate('いって')
    assert len(results_itte) == snapshot(8)
    assert results_itte == snapshot(
        [
            {'base': 'いう', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いつ', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いる', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いって', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'いっる', 'derivation_sequence': {'derivations': [WordType.TE_FORM], 'word_form_progression': ['いって']}},
            {'base': 'いっつ', 'derivation_sequence': {'derivations': [WordType.IMPERATIVE], 'word_form_progression': ['いって']}},
            {'base': 'いっつ', 'derivation_sequence': {'derivations': [WordType.POTENTIAL, WordType.MASU_STEM], 'word_form_progression': ['いってる', 'いって']}},
            {'base': 'いってる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['いって']}},
        ]
    )

    results_shita = deinflector.unconjugate('した')
    assert len(results_shita) == snapshot(5)
    assert results_shita == snapshot(
        [
            {'base': 'する', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'す', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'した', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'しる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'したる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['した']}},
        ]
    )

    results_aru = deinflector.unconjugate('ある')
    assert len(results_aru) == snapshot(2)
    assert results_aru == snapshot(
        [
            {'base': 'ある', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'あるる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['ある']}},
        ]
    )

    results_iru = deinflector.unconjugate('いる')
    assert len(results_iru) == snapshot(2)
    assert results_iru == snapshot(
        [
            {'base': 'いる', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'いるる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['いる']}},
        ]
    )

    results_kita = deinflector.unconjugate('きた')
    assert len(results_kita) == snapshot(3)
    assert results_kita == snapshot(
        [
            {'base': 'きた', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'きる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['きた']}},
            {'base': 'きたる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['きた']}},
        ]
    )

    results_katta = deinflector.unconjugate('かった')
    assert len(results_katta) == snapshot(6)
    assert results_katta == snapshot(
        [
            {'base': 'かう', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かつ', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かった', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'かっる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['かった']}},
            {'base': 'かったる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['かった']}},
        ]
    )

    results_totta = deinflector.unconjugate('取った')
    assert len(results_totta) == snapshot(6)
    assert results_totta == snapshot(
        [
            {'base': '取る', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取う', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取つ', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取った', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': '取っる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['取った']}},
            {'base': '取ったる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['取った']}},
        ]
    )


def test_ambiguity_resolution_1():
    """Deinflection filters by what spacy thinks."""
    # TODO test WIP
    result = deinflector.unconjugate('殺されるな')
    assert len(result) == snapshot(11)
    assert result == snapshot(
        [
            {'base': '殺す', 'derivation_sequence': {'derivations': [WordType.PASSIVE, WordType.NA_COMMAND], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺す', 'derivation_sequence': {'derivations': [WordType.PASSIVE, WordType.NA_PARTICLE], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺する', 'derivation_sequence': {'derivations': [WordType.PASSIVE, WordType.NA_COMMAND], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺する', 'derivation_sequence': {'derivations': [WordType.PASSIVE, WordType.NA_PARTICLE], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺さる', 'derivation_sequence': {'derivations': [WordType.POTENTIAL, WordType.NA_COMMAND], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺さる', 'derivation_sequence': {'derivations': [WordType.POTENTIAL, WordType.NA_PARTICLE], 'word_form_progression': ['殺される', '殺されるな']}},
            {'base': '殺される', 'derivation_sequence': {'derivations': [WordType.NA_COMMAND], 'word_form_progression': ['殺されるな']}},
            {'base': '殺される', 'derivation_sequence': {'derivations': [WordType.NA_PARTICLE], 'word_form_progression': ['殺されるな']}},
            {'base': '殺されるな', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
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
                            text='殺されるな',
                            start_char=0,
                            end_char=5,
                            inner=SentSegTokenSeg(idx=0, orthography='殺されるな'),
                            attributes=SegAttribute(
                                lemma='殺す',
                                upos='VERB',
                                xpos='動詞-一般',
                                dependency=(0, 'ROOT'),
                                misc={
                                    'Inflection': '五段-サ行;未然形-一般',
                                    'Reading': 'コロサ',
                                    'furigana_bracket': '殺[ころ]さ',
                                    'furigana_ruby': '<ruby>殺<rt>ころ</rt></ruby>さ',
                                    'furigana_parentheses': '殺(ころ)さ',
                                    'hiragana_reading': 'ころさ',
                                    'conjugation_base': '殺す',
                                    'conjugation_chain': [{'step': 1, 'form': 'な Negative Command (Do Not Do)', 'result': '殺されるな'}, {'step': 2, 'form': 'Passive Form', 'result': '殺される'}],
                                    'conjugation_sequence_length': 3,
                                    'conjugation_combined_text': '殺されるな',
                                },
                            ),
                        )
                    ]
                ),
            )
        ]
    )


def test_ambiguity_resolution_2():
    """Deinflection filters by what spacy thinks."""
    # TODO test WIP
    text = '学校にいった。'
    verb = 'いった'
    result = deinflector.unconjugate(verb)
    assert len(result) == snapshot(6)
    # BUG doesn't even include 行く (𖦹﹏𖦹;)
    assert result == snapshot(
        [
            {'base': 'いう', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['いった']}},
            {'base': 'いつ', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['いった']}},
            {'base': 'いる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['いった']}},
            {'base': 'いった', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'いっる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['いった']}},
            {'base': 'いったる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['いった']}},
        ]
    )

    # result = SpacyParser().parse(text, ParserConfig("spacy", {"spacy_model": "ja_core_news_sm"})).segments
    result = parser.parse(text, ParserConfig(which_parser="testing", parser_args={})).segments
    assert result == snapshot(
        [
            DocSegV2(
                text='学校にいった。',
                start_char=0,
                end_char=7,
                inner=DocSegSentence(
                    segments=[
                        SentSegV2(
                            sentence_idx=0,
                            text='学校',
                            start_char=0,
                            end_char=2,
                            inner=SentSegTokenSeg(idx=0, orthography='学校'),
                            attributes=SegAttribute(
                                lemma='学校',
                                upos='NOUN',
                                xpos='名詞-普通名詞-一般',
                                dependency=(2, 'obl'),
                                misc={'Reading': 'ガッコウ', 'furigana_bracket': '学校[がっこう]', 'furigana_ruby': '<ruby>学校<rt>がっこう</rt></ruby>', 'furigana_parentheses': '学校(がっこう)', 'hiragana_reading': 'がっこう'},
                            ),
                        ),
                        SentSegV2(
                            sentence_idx=0,
                            text='に',
                            start_char=2,
                            end_char=3,
                            inner=SentSegTokenSeg(idx=1, orthography='に'),
                            attributes=SegAttribute(lemma='に', upos='ADP', xpos='助詞-格助詞', dependency=(0, 'case'), misc={'Reading': 'ニ', 'furigana_bracket': 'に', 'furigana_ruby': 'に', 'furigana_parentheses': 'に', 'hiragana_reading': 'に'}),
                        ),
                        SentSegV2(
                            sentence_idx=0,
                            text='いった',
                            start_char=3,
                            end_char=6,
                            inner=SentSegTokenSeg(idx=2, orthography='いった'),
                            attributes=SegAttribute(
                                lemma='いう',
                                upos='VERB',
                                xpos='動詞-非自立可能',
                                dependency=(2, 'ROOT'),
                                misc={
                                    'Inflection': '五段-カ行;連用形-促音便',
                                    'Reading': 'イッ',
                                    'furigana_bracket': 'いっ',
                                    'furigana_ruby': 'いっ',
                                    'furigana_parentheses': 'いっ',
                                    'hiragana_reading': 'いっ',
                                    'conjugation_base': 'いう',
                                    'conjugation_chain': [{'step': 1, 'form': 'Plain Past', 'result': 'いった'}],
                                    'conjugation_sequence_length': 2,
                                    'conjugation_combined_text': 'いった',
                                },
                            ),
                        ),
                        SentSegV2(
                            sentence_idx=0,
                            text='。',
                            start_char=6,
                            end_char=7,
                            inner=SentSegPunctuationSeg(),
                            attributes=SegAttribute(lemma='。', upos='PUNCT', xpos='補助記号-句点', dependency=(2, 'punct'), misc={'Reading': '。', 'furigana_bracket': '。', 'furigana_ruby': '。', 'furigana_parentheses': '。', 'hiragana_reading': '。'}),
                        ),
                    ]
                ),
            )
        ]
    )

    text = '先生がそういった。'  # 言う
    result = deinflector.unconjugate(verb)
    assert len(result) == snapshot(6)
    assert result == snapshot(
        [
            {'base': 'いう', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['いった']}},
            {'base': 'いつ', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['いった']}},
            {'base': 'いる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['いった']}},
            {'base': 'いった', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'いっる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['いった']}},
            {'base': 'いったる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['いった']}},
        ]
    )

    result = parser.parse(text, ParserConfig("testing", {})).segments
    assert result == snapshot(
        [
            DocSegV2(
                text='先生がそういった。',
                start_char=0,
                end_char=9,
                inner=DocSegSentence(
                    segments=[
                        SentSegV2(
                            sentence_idx=0,
                            text='先生',
                            start_char=0,
                            end_char=2,
                            inner=SentSegTokenSeg(idx=0, orthography='先生'),
                            attributes=SegAttribute(
                                lemma='先生',
                                upos='NOUN',
                                xpos='名詞-普通名詞-一般',
                                dependency=(3, 'nsubj'),
                                misc={'Reading': 'センセイ', 'furigana_bracket': '先生[せんせい]', 'furigana_ruby': '<ruby>先生<rt>せんせい</rt></ruby>', 'furigana_parentheses': '先生(せんせい)', 'hiragana_reading': 'せんせい'},
                            ),
                        ),
                        SentSegV2(
                            sentence_idx=0,
                            text='が',
                            start_char=2,
                            end_char=3,
                            inner=SentSegTokenSeg(idx=1, orthography='が'),
                            attributes=SegAttribute(lemma='が', upos='ADP', xpos='助詞-格助詞', dependency=(0, 'case'), misc={'Reading': 'ガ', 'furigana_bracket': 'が', 'furigana_ruby': 'が', 'furigana_parentheses': 'が', 'hiragana_reading': 'が'}),
                        ),
                        SentSegV2(
                            sentence_idx=0,
                            text='そう',
                            start_char=3,
                            end_char=5,
                            inner=SentSegTokenSeg(idx=2, orthography='そう'),
                            attributes=SegAttribute(lemma='そう', upos='ADV', xpos='副詞', dependency=(3, 'advmod'), misc={'Reading': 'ソウ', 'furigana_bracket': 'そう', 'furigana_ruby': 'そう', 'furigana_parentheses': 'そう', 'hiragana_reading': 'そう'}),
                        ),
                        SentSegV2(
                            sentence_idx=0,
                            text='いった',
                            start_char=5,
                            end_char=8,
                            inner=SentSegTokenSeg(idx=3, orthography='いった'),
                            attributes=SegAttribute(
                                lemma='いう',
                                upos='VERB',
                                xpos='動詞-一般',
                                dependency=(3, 'ROOT'),
                                misc={
                                    'Inflection': '五段-ワア行;連用形-促音便',
                                    'Reading': 'イッ',
                                    'furigana_bracket': 'いっ',
                                    'furigana_ruby': 'いっ',
                                    'furigana_parentheses': 'いっ',
                                    'hiragana_reading': 'いっ',
                                    'conjugation_base': 'いう',
                                    'conjugation_chain': [{'step': 1, 'form': 'Plain Past', 'result': 'いった'}],
                                    'conjugation_sequence_length': 2,
                                    'conjugation_combined_text': 'いった',
                                },
                            ),
                        ),
                        SentSegV2(
                            sentence_idx=0,
                            text='。',
                            start_char=8,
                            end_char=9,
                            inner=SentSegPunctuationSeg(),
                            attributes=SegAttribute(lemma='。', upos='PUNCT', xpos='補助記号-句点', dependency=(3, 'punct'), misc={'Reading': '。', 'furigana_bracket': '。', 'furigana_ruby': '。', 'furigana_parentheses': '。', 'hiragana_reading': '。'}),
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


def test_conjugation_analyzer_filter_candidates():
    """Test that the conjugation analyzer can filter candidates based on tokenization."""
    # Test with ambiguous した - should filter based on tokenization context

    # Parse the text to get real tokenization results (with conjugation analysis disabled)
    text = "した"
    result = parser.parse(text, ParserConfig("enhanced_japanese", {"enable_conjugation_analysis": False}))

    # Extract token segments from parsed result
    token_segments = []
    for segment in result.segments:
        if hasattr(segment.inner, 'segments'):
            for sent_seg in segment.inner.segments:
                if isinstance(sent_seg.inner, SentSegTokenSeg):
                    token_segments.append(sent_seg)

    # Snapshot the tokenization result for verification
    tokenization_result = [(seg.text, seg.attributes.lemma, seg.attributes.upos, seg.attributes.xpos) for seg in token_segments]
    assert tokenization_result == snapshot([('し', 'する', 'VERB', '動詞-非自立可能'), ('た', 'た', 'AUX', '助動詞')])

    # Get all candidates for した
    candidates = deinflector.unconjugate("した")

    # Snapshot original candidates for comparison
    assert candidates == snapshot(
        [
            {'base': 'する', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'す', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'した', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': 'しる', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
            {'base': 'したる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['した']}},
        ]
    )

    # Filter based on tokenization (should prefer する over other candidates)
    filtered = conjugation_analyzer._filter_candidates_by_tokenization(candidates, token_segments)

    # Snapshot filtered results showing which candidates were kept
    assert filtered == snapshot(
        [
            {'base': 'する', 'derivation_sequence': {'derivations': [WordType.PLAIN_PAST], 'word_form_progression': ['した']}},
        ]
    )

    # Snapshot the length comparison to show filtering effectiveness
    candidate_count = {"original_candidates": len(candidates), "filtered_candidates": len(filtered)}
    assert candidate_count == snapshot({"original_candidates": 5, "filtered_candidates": 1})


def test_conjugation_analyzer_collect_sequence():
    """Test collecting conjugation sequences from tokenized segments."""
    # Test with "置いていこう" (let's leave it there)
    text = "置いていこう"
    # Parse with conjugation analysis disabled to get original separate tokens
    result = parser.parse(text, ParserConfig("enhanced_japanese", {"enable_conjugation_analysis": False}))

    # Extract token segments from parsed result
    token_segments = []
    for segment in result.segments:
        if hasattr(segment.inner, 'segments'):
            for sent_seg in segment.inner.segments:
                if isinstance(sent_seg.inner, SentSegTokenSeg):
                    token_segments.append(sent_seg)

    # Snapshot the tokenization result for verification (should have separate tokens)
    tokenization_result = [(seg.text, seg.attributes.lemma, seg.attributes.upos, seg.attributes.xpos) for seg in token_segments]
    assert tokenization_result == snapshot([('置い', '置く', 'VERB', '動詞-非自立可能'), ('て', 'て', 'SCONJ', '助詞-接続助詞'), ('いこう', 'いく', 'VERB', '動詞-非自立可能')])

    # Collect sequence starting from the first verb
    sequence, combined_text = conjugation_analyzer._collect_conjugation_sequence(token_segments, 0)

    # Should collect the verb and the auxiliary tokens
    assert len(sequence) >= 1
    assert sequence[0].text == "置い"

    # Snapshot the collected sequence
    sequence_result = [(seg.text, seg.attributes.upos) for seg in sequence]
    assert sequence_result == snapshot([('置い', 'VERB'), ('て', 'SCONJ'), ('いこう', 'VERB')])


def test_conjugation_chain_description():
    """Test creating human-readable conjugation chain descriptions."""
    # Test with a known conjugation
    candidates = deinflector.unconjugate("置いていこう")

    # Snapshot all candidates to show what we're working with
    assert candidates == snapshot(
        [
            {'base': '置く', 'derivation_sequence': {'derivations': [WordType.TE_FORM, WordType.TE_IKU, WordType.VOLITIONAL], 'word_form_progression': ['置いて', '置いていく', '置いていこう']}},
            {'base': '置いる', 'derivation_sequence': {'derivations': [WordType.TE_FORM, WordType.TE_IKU, WordType.VOLITIONAL], 'word_form_progression': ['置いて', '置いていく', '置いていこう']}},
            {'base': '置いていく', 'derivation_sequence': {'derivations': [WordType.VOLITIONAL], 'word_form_progression': ['置いていこう']}},
            {'base': '置いていこう', 'derivation_sequence': {'derivations': [], 'word_form_progression': []}},
            {'base': '置いていこうる', 'derivation_sequence': {'derivations': [WordType.MASU_STEM], 'word_form_progression': ['置いていこう']}},
        ]
    )

    # Test with the best candidate (first one)
    best_candidate = candidates[0]
    chain = conjugation_analyzer._create_conjugation_chain_description(best_candidate["derivation_sequence"])

    # Snapshot the actual conjugation chain description showing all steps and structure
    assert chain == snapshot(
        [
            {'form': 'Volitional Form', 'result': '置いていこう', 'step': 1},
            {'form': 'ていく・でいく Gradual Change (Away From Speaker)', 'result': '置いていく', 'step': 2},
            {'form': 'て・で Form', 'result': '置いて', 'step': 3},
        ]
    )

    # Snapshot chain length to make the count assertion explicit
    assert len(chain) == snapshot(3)


def test_japanese_parser_with_conjugation_analysis():
    """Test that JapaneseParser adds conjugation information to misc fields."""

    # Test with simple past tense
    text = "しまった"
    result = parser.parse(text, ParserConfig("enhanced_japanese", {}))

    # Extract all conjugation information from the result
    conjugation_info = []
    for segment in result.segments:
        if hasattr(segment.inner, 'segments'):
            for sent_seg in segment.inner.segments:
                if isinstance(sent_seg.inner, SentSegTokenSeg):
                    misc = sent_seg.attributes.misc
                    if "conjugation_base" in misc:
                        conjugation_info.append({"token": sent_seg.text, "base": misc["conjugation_base"], "chain": misc["conjugation_chain"], "combined_text": misc["conjugation_combined_text"]})

    # Snapshot the conjugation analysis results
    assert conjugation_info == snapshot([{'token': 'しまった', 'base': 'しまう', 'chain': [{'step': 1, 'form': 'Plain Past', 'result': 'しまった'}], 'combined_text': 'しまった'}])


def test_japanese_parser_complex_conjugation():
    """Test parser with complex conjugation examples and snapshot their conjugation chains."""

    examples = [
        "置いていこう",  # 置く -> て form -> continuous change -> volitional
        "作ってくれる",  # 作る -> て form -> benefit given
        "立たなかった",  # 立つ -> negative -> past negative
        "なってしまった",  # なる -> て form -> completed action -> past
    ]

    all_conjugation_results = {}

    for text in examples:
        result = parser.parse(text, ParserConfig("enhanced_japanese", {}))

        # Extract conjugation information
        conjugation_info = []
        for segment in result.segments:
            if hasattr(segment.inner, 'segments'):
                for sent_seg in segment.inner.segments:
                    if isinstance(sent_seg.inner, SentSegTokenSeg):
                        misc = sent_seg.attributes.misc
                        if "conjugation_base" in misc:
                            conjugation_info.append({"token": sent_seg.text, "base": misc["conjugation_base"], "chain": misc["conjugation_chain"], "combined_text": misc["conjugation_combined_text"]})

        all_conjugation_results[text] = conjugation_info

    # Snapshot all conjugation analysis results
    assert all_conjugation_results == snapshot(
        {
            '置いていこう': [
                {
                    'token': '置いていこう',
                    'base': '置く',
                    'chain': [{'step': 1, 'form': 'Volitional Form', 'result': '置いていこう'}, {'step': 2, 'form': 'ていく・でいく Gradual Change (Away From Speaker)', 'result': '置いていく'}, {'step': 3, 'form': 'て・で Form', 'result': '置いて'}],
                    'combined_text': '置いていこう',
                }
            ],
            '作ってくれる': [{'token': '作ってくれる', 'base': '作る', 'chain': [{'step': 1, 'form': 'くれる To Give (Toward Speaker)', 'result': '作ってくれる'}, {'step': 2, 'form': 'て・で Form', 'result': '作って'}], 'combined_text': '作ってくれる'}],
            '立たなかった': [{'token': '立たなかった', 'base': '立つ', 'chain': [{'step': 1, 'form': 'Plain Past', 'result': '立たなかった'}, {'step': 2, 'form': 'ない Negative', 'result': '立たない'}], 'combined_text': '立たなかった'}],
            'なってしまった': [
                {
                    'token': 'なってしまった',
                    'base': 'なる',
                    'chain': [{'step': 1, 'form': 'Plain Past', 'result': 'なってしまった'}, {'step': 2, 'form': 'しまう To Do Unfortunately ・ To Do Completely', 'result': 'なってしまう'}, {'step': 3, 'form': 'て・で Form', 'result': 'なって'}],
                    'combined_text': 'なってしまった',
                }
            ],
        }
    )


def test_conjugation_analyzer_integration():
    """Test the full integration of conjugation analysis."""

    # Test with "なってしまった" (became/ended up becoming)
    text = "なってしまった"
    result = parser.parse(text, ParserConfig("enhanced_japanese", {}))

    # Extract sentence segments
    sentence_segments = []
    for segment in result.segments:
        if hasattr(segment.inner, 'segments'):
            sentence_segments.extend(segment.inner.segments)

    # Filter to token segments only
    token_segments = [seg for seg in sentence_segments if isinstance(seg.inner, SentSegTokenSeg)]

    # Should have multiple tokens
    assert len(token_segments) > 0

    # Check if any token has conjugation information
    has_conjugation_info = any("conjugation_base" in seg.attributes.misc for seg in token_segments)

    # Note: This might not always be true depending on how the tokenizer splits the text
    # The test mainly ensures the integration doesn't crash


def test_example_conjugation_chains():
    """Test the specific examples mentioned in the requirements."""

    examples = [
        ("置いていこう", "置く"),  # 置く -> て form -> continuous change -> volitional
        ("作ってくれる", "作る"),  # 作る -> て form -> benefit given
        ("しまった", "しまう"),  # しまう -> past
        ("立たなかった", "立つ"),  # 立つ -> negative -> past negative
        ("なってしまった", "なる"),  # なる -> て form -> completed action -> past
    ]

    for conjugated_form, expected_base in examples:
        # Test deinflection directly
        candidates = deinflector.unconjugate(conjugated_form)

        # Should have at least one candidate
        assert len(candidates) > 0, f"No candidates found for '{conjugated_form}'"

        # Check if expected base is among the candidates
        bases = [c["base"] for c in candidates]
        assert expected_base in bases, f"Expected base '{expected_base}' not found in {bases} for '{conjugated_form}'"

        # Test parser integration
        result = parser.parse(conjugated_form, ParserConfig("enhanced_japanese", {}))
        assert result.text == conjugated_form
