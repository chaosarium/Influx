"""
Japanese conjugation analysis module for identifying and analyzing conjugated verbs/adjectives
after tokenization using the deinflect module.
"""

from __future__ import annotations
from typing import List, Dict, Any, Optional, Tuple
from .annotation import SentSegV2, SentSegTokenSeg, SegAttribute
from .japanese_deinflect.deinflect import Deinflector
from .japanese_deinflect.word_type import WordType


class JapaneseConjugationAnalyzer:
    """Analyzes Japanese conjugated forms in tokenized text."""

    def __init__(self):
        self.deinflector = Deinflector()

    def _is_verb_or_adjective_token(self, segment: SentSegV2) -> bool:
        """Check if a token segment represents a verb or adjective."""
        if not isinstance(segment.inner, SentSegTokenSeg):
            return False

        upos = segment.attributes.upos
        xpos = segment.attributes.xpos or ""

        # Check for verbs and adjectives based on UPOS and XPOS
        if upos in ["VERB", "AUX", "ADJ"]:
            return True

        # Additional checks for Japanese-specific tags
        if "動詞" in xpos or "形容詞" in xpos or "助動詞" in xpos:
            return True

        return False

    def _is_auxiliary_token(self, segment: SentSegV2) -> bool:
        """Check if a token is likely an auxiliary that could be part of conjugation."""
        if not isinstance(segment.inner, SentSegTokenSeg):
            return False

        upos = segment.attributes.upos
        xpos = segment.attributes.xpos or ""

        # Use tokenization results to identify auxiliary tokens
        # AUX (auxiliary verbs) - た, だ, ない, etc.
        if upos == "AUX":
            return True

        # SCONJ (subordinating conjunctions) - て, で particles
        if upos == "SCONJ":
            return True

        # Japanese-specific auxiliary patterns from xpos
        if "助動詞" in xpos:  # auxiliary verbs
            return True

        if "助詞" in xpos:  # particles that can be part of conjugations
            return True

        # Non-independent verbs (often auxiliary)
        if "動詞-非自立" in xpos:
            return True

        return False

    def _collect_conjugation_sequence(self, segments: List[SentSegV2], start_idx: int) -> Tuple[List[SentSegV2], str]:
        """
        Collect a sequence of tokens that might form a conjugated verb/adjective.
        Returns the sequence of segments and the combined text.
        """
        sequence = [segments[start_idx]]
        combined_text = segments[start_idx].text

        # Look ahead for auxiliary tokens that could be part of the conjugation
        for i in range(start_idx + 1, len(segments)):
            if self._is_auxiliary_token(segments[i]):
                sequence.append(segments[i])
                combined_text += segments[i].text
            else:
                break

        return sequence, combined_text

    def _filter_candidates_by_tokenization(self, candidates: List[Dict[str, Any]], token_sequence: List[SentSegV2]) -> List[Dict[str, Any]]:
        """
        Filter deinflection candidates based on what the tokenizer identified.
        This helps resolve ambiguity by using tokenization information.
        """
        if not candidates:
            return candidates

        filtered_candidates = []

        # Collect all lemmas from the token sequence
        token_lemmas = set()
        for token in token_sequence:
            if isinstance(token.inner, SentSegTokenSeg):
                token_lemma = token.attributes.lemma
                if token_lemma:
                    token_lemmas.add(token_lemma)

        for candidate in candidates:
            base_lemma = candidate["base"]

            # Direct match with tokenizer lemmas
            if base_lemma in token_lemmas:
                filtered_candidates.append(candidate)

        # If filtering removed all candidates, return the original list
        # (tokenizer might not have perfect lemmatization)
        if not filtered_candidates:
            return candidates

        return filtered_candidates

    def _create_conjugation_chain_description(self, derivation_sequence: Dict[str, Any]) -> List[Dict[str, str]]:
        """
        Create a human-readable conjugation chain from the derivation sequence.
        """
        derivations = derivation_sequence.get("derivations", [])
        word_progression = derivation_sequence.get("word_form_progression", [])

        if not derivations:
            return []

        chain = []

        # The progression shows the forms in reverse order (from conjugated back to base)
        # We need to reverse it to show base -> conjugated
        reversed_derivations = list(reversed(derivations))
        reversed_progression = list(reversed(word_progression))

        for i, (derivation_type, word_form) in enumerate(zip(reversed_derivations, reversed_progression)):
            step = {"step": i + 1, "form": derivation_type.value if hasattr(derivation_type, 'value') else str(derivation_type), "result": word_form}
            chain.append(step)

        return chain

    def analyze_conjugations(self, sentence_segments: List[SentSegV2]) -> List[SentSegV2]:
        """
        Analyze conjugations in a sentence and merge conjugated tokens into single segments.
        Returns modified segments with conjugated forms merged and auxiliary tokens removed.
        """
        modified_segments = []
        i = 0

        while i < len(sentence_segments):
            segment = sentence_segments[i]

            # Skip non-token segments
            if not isinstance(segment.inner, SentSegTokenSeg):
                modified_segments.append(segment)
                i += 1
                continue

            # Check if this is a verb or adjective that might be conjugated
            if self._is_verb_or_adjective_token(segment):
                # Collect the conjugation sequence
                token_sequence, combined_text = self._collect_conjugation_sequence(sentence_segments, i)

                # Get deinflection candidates
                candidates = self.deinflector.unconjugate(combined_text)

                # Filter candidates based on tokenization
                filtered_candidates = self._filter_candidates_by_tokenization(candidates, token_sequence)

                # If we have good candidates and multiple tokens to combine, merge them
                if filtered_candidates and len(token_sequence) > 1:
                    best_candidate = filtered_candidates[0]  # Take the most likely one

                    # Create conjugation chain description
                    conjugation_chain = self._create_conjugation_chain_description(best_candidate["derivation_sequence"])

                    # Create a merged token that spans the entire conjugated sequence
                    start_char = token_sequence[0].start_char
                    end_char = token_sequence[-1].end_char

                    # Use the lemma from the best candidate as the base form
                    merged_segment = SentSegV2(
                        sentence_idx=segment.sentence_idx,
                        text=combined_text,
                        start_char=start_char,
                        end_char=end_char,
                        inner=SentSegTokenSeg(idx=segment.inner.idx, orthography=combined_text.lower()),
                        attributes=SegAttribute(
                            lemma=best_candidate["base"],
                            upos=segment.attributes.upos,  # Keep the original verb's POS
                            xpos=segment.attributes.xpos,
                            dependency=segment.attributes.dependency,
                            misc={**segment.attributes.misc, "conjugation_base": best_candidate["base"], "conjugation_chain": conjugation_chain, "conjugation_sequence_length": len(token_sequence), "conjugation_combined_text": combined_text},
                        ),
                    )
                    modified_segments.append(merged_segment)

                    # Skip ahead past the processed sequence (all tokens are now merged)
                    i += len(token_sequence)
                elif filtered_candidates and len(token_sequence) == 1:
                    # Single token with conjugation info but no merging needed
                    best_candidate = filtered_candidates[0]
                    conjugation_chain = self._create_conjugation_chain_description(best_candidate["derivation_sequence"])

                    if conjugation_chain:
                        modified_segment = SentSegV2(
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
                                misc={**segment.attributes.misc, "conjugation_base": best_candidate["base"], "conjugation_chain": conjugation_chain, "conjugation_sequence_length": len(token_sequence), "conjugation_combined_text": combined_text},
                            ),
                        )
                        modified_segments.append(modified_segment)
                    else:
                        modified_segments.append(segment)
                    i += 1
                else:
                    # No good candidates, keep original tokens
                    modified_segments.append(segment)
                    i += 1
            else:
                modified_segments.append(segment)
                i += 1

        return modified_segments
