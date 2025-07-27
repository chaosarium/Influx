import stanza
import spacy
import re
from typing import List, Set
from loguru import logger
from .annotation import *
import spacy.cli


def ensure_spacy_model(model_name):

    try:
        return spacy.load(model_name)
    except OSError:
        print(f"Model '{model_name}' not found. Auto downloading...")
        spacy.cli.download(model_name)
        return spacy.load(model_name)


def recover_sentence_whitespace(text: str, segments: List[SentSegV2], sentence_start_char: int) -> List[SentSegV2]:
    result: List[SentSegV2] = []
    fill_line: int = sentence_start_char
    for seg in segments:
        if seg.start_char > fill_line:
            whitespace_text: str = text[fill_line : seg.start_char]
            result.append(
                SentSegV2(
                    sentence_idx=seg.sentence_idx,
                    text=whitespace_text,
                    start_char=fill_line,
                    end_char=seg.start_char,
                    inner=SentSegWhitespaceSeg(),
                    attributes=SegAttribute(),
                )
            )
        result.append(seg)
        fill_line = seg.end_char

    if len(segments) > 0:
        sentence_end_char: int = segments[-1].end_char
        if sentence_end_char > fill_line:
            whitespace_text = text[fill_line:sentence_end_char]
            result.append(
                SentSegV2(
                    sentence_idx=segments[-1].sentence_idx,
                    text=whitespace_text,
                    start_char=fill_line,
                    end_char=sentence_end_char,
                    inner=SentSegWhitespaceSeg(),
                    attributes=SegAttribute(),
                )
            )

    return result


def recover_document_whitespace(text: str, doc_segments: List[DocSegV2]) -> List[DocSegV2]:
    result: List[DocSegV2] = []
    last_char: int = 0
    for seg in doc_segments:
        if seg.start_char > last_char:
            result.append(
                DocSegV2(
                    text=text[last_char : seg.start_char],
                    start_char=last_char,
                    end_char=seg.start_char,
                    inner=DocSegDocumentWhitespace(),
                )
            )
        result.append(seg)
        last_char = seg.end_char

    if last_char < len(text):
        result.append(
            DocSegV2(
                text=text[last_char:],
                start_char=last_char,
                end_char=len(text),
                inner=DocSegDocumentWhitespace(),
            )
        )
    return result


class BaseParser:
    def __init__(self):
        self.cache: dict = {}

    @staticmethod
    def _dict_as_key(d: dict) -> str:
        return frozenset((k, v) for k, v in d.items())

    def _get_cache_opt(self, parser_args: dict) -> dict:
        k = self._dict_as_key(parser_args)
        if k in self.cache:
            return self.cache[k]
        return None

    def _set_cache(self, parser_args: dict, lang_pipeline) -> None:
        k = self._dict_as_key(parser_args)
        self.cache[k] = lang_pipeline

    def _init_for_args(self, parser_args: dict) -> any:
        raise NotImplementedError("This method should be implemented by subclasses.")

    def _parse_with_pipeline(self, text: str, parser_config: dict, lang_pipeline) -> any:
        raise NotImplementedError("This method should be implemented by subclasses.")

    def parse(self, text: str, parser_config: ParserConfig) -> dict:
        lang_pipeline = self._get_cache_opt(parser_config.parser_args)
        if lang_pipeline is None:
            lang_pipeline = self._init_for_args(parser_config.parser_args)
            self._set_cache(parser_config.parser_args, lang_pipeline)

        annotated_doc: AnnotatedDocV2 = self._parse_with_pipeline(text, parser_config, lang_pipeline)

        return annotated_doc


class SpacyParser(BaseParser):
    def __init__(self):
        super().__init__()

    def _init_for_args(self, parser_args: dict) -> spacy.Language:
        nlp: spacy.Language = ensure_spacy_model(parser_args["spacy_model"])
        logger.debug("spaCy model loaded successfully", extra=parser_args)
        return nlp

    def _parse_with_pipeline(self, text: str, parser_config: ParserConfig, nlp: spacy.Language) -> AnnotatedDocV2:
        doc: spacy.tokens.Doc = nlp(text)

        orthography_set: Set[str] = set()
        lemma_set: Set[str] = set()

        doc_sentence_segments: List[DocSegV2] = []
        for sent_idx, sent in enumerate(doc.sents):
            sent_segments: List[SentSegV2] = []
            for token in sent:
                if token.is_space:
                    continue

                orthography: str = token.text.lower()
                lemma: str = token.lemma_.lower()
                orthography_set.add(orthography)
                lemma_set.add(lemma)

                attributes: SegAttribute = SegAttribute(
                    lemma=lemma,
                    upos=token.pos_,
                    xpos=token.tag_,
                    dependency=(token.head.i, token.dep_),
                    misc=token.morph.to_dict(),
                    conjugation_chain=None,
                )

                if token.is_punct:
                    inner_seg = SentSegPunctuationSeg()
                else:
                    inner_seg = SentSegTokenSeg(idx=token.i, orthography=orthography)

                sent_segments.append(
                    SentSegV2(
                        sentence_idx=sent_idx,
                        text=token.text,
                        start_char=token.idx,
                        end_char=token.idx + len(token.text),
                        inner=inner_seg,
                        attributes=attributes,
                    )
                )

            if sent_segments != [] and not sent.text.isspace():
                sentence_start_char: int = min([s.start_char for s in sent_segments])
                sentence_end_char: int = max([s.end_char for s in sent_segments])
                recovered_sent_segments: List[SentSegV2] = recover_sentence_whitespace(text, sent_segments, sentence_start_char)
                doc_sentence_segments.append(
                    DocSegV2(
                        text=text[sentence_start_char:sentence_end_char],
                        start_char=sentence_start_char,
                        end_char=sentence_end_char,
                        inner=DocSegSentence(segments=recovered_sent_segments),
                    )
                )

        doc_segments: List[DocSegV2] = recover_document_whitespace(text, doc_sentence_segments)

        return AnnotatedDocV2(
            text=text,
            segments=doc_segments,
            orthography_set=list(orthography_set),
            lemma_set=list(lemma_set),
            parser_config=parser_config,
        )


class JapaneseParser(SpacyParser):
    """Japanese-specific parser that adds furigana annotations and conjugation analysis to the "misc" field."""

    def _init_for_args(self, parser_args: dict) -> spacy.Language:
        nlp: spacy.Language = spacy.load("ja_ginza")
        logger.debug("spaCy model loaded successfully", extra=parser_args)
        return nlp

    def _parse_with_pipeline(self, text: str, parser_config: ParserConfig, nlp: spacy.Language) -> AnnotatedDocV2:
        from .japanese_support import add_furigana_annotations
        from .japanese_conjugation_analysis import JapaneseConjugationAnalyzer

        doc: spacy.tokens.Doc = nlp(text)
        conjugation_analyzer = JapaneseConjugationAnalyzer()

        orthography_set: Set[str] = set()
        lemma_set: Set[str] = set()

        doc_sentence_segments: List[DocSegV2] = []
        for sent_idx, sent in enumerate(doc.sents):
            sent_segments: List[SentSegV2] = []
            for token in sent:
                if token.is_space:
                    continue

                orthography: str = token.text.lower()
                lemma: str = token.lemma_.lower()
                orthography_set.add(orthography)
                lemma_set.add(lemma)

                # Start with base misc attributes from spacy (including Reading field)
                misc_attrs = token.morph.to_dict()

                attributes: SegAttribute = SegAttribute(
                    lemma=lemma,
                    upos=token.pos_,
                    xpos=token.tag_,
                    dependency=(token.head.i, token.dep_),
                    misc=misc_attrs,
                    conjugation_chain=None,
                )

                if token.is_punct:
                    inner_seg = SentSegPunctuationSeg()
                else:
                    inner_seg = SentSegTokenSeg(idx=token.i, orthography=orthography)

                sent_segments.append(
                    SentSegV2(
                        sentence_idx=sent_idx,
                        text=token.text,
                        start_char=token.idx,
                        end_char=token.idx + len(token.text),
                        inner=inner_seg,
                        attributes=attributes,
                    )
                )

            if sent_segments != [] and not sent.text.isspace():
                # First: Analyze conjugations in the sentence segments if enabled
                enable_conjugation_analysis = parser_config.parser_args.get("enable_conjugation_analysis", True)
                if enable_conjugation_analysis:
                    analyzed_segments, intermediate_orthographies = conjugation_analyzer.analyze_conjugations(sent_segments)
                    # Add intermediate orthographies discovered during conjugation analysis
                    orthography_set.update(intermediate_orthographies)
                else:
                    analyzed_segments = sent_segments

                # Second: Add furigana annotations to segments (including merged conjugated tokens)
                furigana_segments = []
                for segment in analyzed_segments:
                    if hasattr(segment, 'attributes') and segment.attributes and segment.attributes.misc and "Reading" in segment.attributes.misc:
                        reading = segment.attributes.misc["Reading"]
                        furigana_annotations = add_furigana_annotations(segment.text, reading)
                        # Update misc with furigana annotations
                        updated_misc = {**segment.attributes.misc}
                        updated_misc.update(furigana_annotations)

                        # Create new segment with updated misc
                        furigana_segment = SentSegV2(
                            sentence_idx=segment.sentence_idx,
                            text=segment.text,
                            start_char=segment.start_char,
                            end_char=segment.end_char,
                            inner=segment.inner,
                            attributes=SegAttribute(
                                lemma=segment.attributes.lemma,
                                upos=segment.attributes.upos,
                                xpos=segment.attributes.xpos,
                                dependency=segment.attributes.dependency,
                                misc=updated_misc,
                                conjugation_chain=segment.attributes.conjugation_chain,
                            ),
                        )
                        furigana_segments.append(furigana_segment)
                    else:
                        furigana_segments.append(segment)

                sentence_start_char: int = min([s.start_char for s in furigana_segments])
                sentence_end_char: int = max([s.end_char for s in furigana_segments])
                recovered_sent_segments: List[SentSegV2] = recover_sentence_whitespace(text, furigana_segments, sentence_start_char)
                doc_sentence_segments.append(
                    DocSegV2(
                        text=text[sentence_start_char:sentence_end_char],
                        start_char=sentence_start_char,
                        end_char=sentence_end_char,
                        inner=DocSegSentence(segments=recovered_sent_segments),
                    )
                )

        doc_segments: List[DocSegV2] = recover_document_whitespace(text, doc_sentence_segments)

        return AnnotatedDocV2(
            text=text,
            segments=doc_segments,
            orthography_set=list(orthography_set),
            lemma_set=list(lemma_set),
            parser_config=parser_config,
        )
