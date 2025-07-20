import stanza
import spacy
import re
from typing import List, Set
from .annotation import (
    AnnotatedDocV2,
    DocSegV2,
    DocSegSentence,
    DocSegDocumentWhitespace,
    SentSegV2,
    SentSegTokenSeg,
    SentSegWhitespaceSeg,
    SentSegPunctuationSeg,
    SegAttribute,
)


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

    def _get_cache_opt(self, lang_code: str) -> dict:
        if lang_code in self.cache:
            return self.cache[lang_code]
        return None

    def _set_cache(self, lang_code: str, lang_pipeline) -> None:
        self.cache[lang_code] = lang_pipeline

    def _init_for_lang(self, lang_code: str) -> any:
        raise NotImplementedError("This method should be implemented by subclasses.")

    def _parse_with_pipeline(self, text: str, lang_pipeline) -> any:
        raise NotImplementedError("This method should be implemented by subclasses.")

    def parse(self, text: str, lang_code: str, parser_config: dict = None) -> dict:
        lang_pipeline = self._get_cache_opt(lang_code)
        if lang_pipeline is None:
            lang_pipeline = self._init_for_lang(lang_code)
            self._set_cache(lang_code, lang_pipeline)

        annotated_doc: AnnotatedDocV2 = self._parse_with_pipeline(text, lang_pipeline)

        # Add parser_config to the response
        result = annotated_doc.to_dict()
        if parser_config is not None:
            result["parser_config"] = parser_config
        else:
            # Default parser config
            result["parser_config"] = {"parser_type": "base_spacy", "spacy_model": None}

        return result


class SpacyParser(BaseParser):
    def __init__(self):
        super().__init__()

    def _init_for_lang(self, lang_code: str) -> spacy.Language:
        spacy_model: str
        match lang_code:
            case "ja":
                spacy_model = "ja_ginza"
            case "en":
                spacy_model = "en_core_web_sm"
            case "fr":
                spacy_model = "fr_core_news_sm"
            case _:
                raise ValueError("haven't figured out what model to use yet...")
        nlp: spacy.Language = spacy.load(spacy_model)
        return nlp

    def _parse_with_pipeline(self, text: str, nlp: spacy.Language) -> AnnotatedDocV2:
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
                recovered_sent_segments: List[SentSegV2] = recover_sentence_whitespace(
                    text, sent_segments, sentence_start_char
                )
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
        )


class JapaneseParser(SpacyParser):
    """Japanese-specific parser that adds furigana annotations of various format to the "misc" field."""

    def _parse_with_pipeline(self, text: str, nlp: spacy.Language) -> AnnotatedDocV2:
        from .japanese_support import add_furigana_annotations

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

                # Start with base misc attributes from spacy
                misc_attrs = token.morph.to_dict()

                # Add furigana annotations if reading is available
                if "Reading" in misc_attrs:
                    reading = misc_attrs["Reading"]
                    furigana_annotations = add_furigana_annotations(token.text, reading)
                    misc_attrs.update(furigana_annotations)

                attributes: SegAttribute = SegAttribute(
                    lemma=lemma,
                    upos=token.pos_,
                    xpos=token.tag_,
                    dependency=(token.head.i, token.dep_),
                    misc=misc_attrs,
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
                recovered_sent_segments: List[SentSegV2] = recover_sentence_whitespace(
                    text, sent_segments, sentence_start_char
                )
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
        )
