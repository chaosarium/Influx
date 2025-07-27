import json
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple

from .word_type import WordType
from .derivation_attribute import DerivationAttribute
from .derivations import rules


class Deinflector:
    def __init__(self):
        self.frequency_for_word = self._load_frequency_dict()
        self.derivation_rules_for_conjugated_word_type = self._build_derivation_rules()

    def _load_frequency_dict(self) -> Dict[str, int]:
        freq_path = Path(__file__).parent / "frequency_for_word.json"
        with open(freq_path, "r", encoding="utf-8") as f:
            return json.load(f)

    def _build_derivation_rules(self) -> Dict[WordType, List[Dict[str, Any]]]:
        rules_map = {}
        for rule in rules:
            conjugated_word_type = rule["conjugated_word_type"]
            if conjugated_word_type not in rules_map:
                rules_map[conjugated_word_type] = []
            rules_map[conjugated_word_type].append(rule)
        return rules_map

    def _get_frequency_for_suru_verb(self, word: str) -> Optional[int]:
        if word.endswith("する"):
            suru_base = word[:-2]
            return self.frequency_for_word.get(suru_base)
        return None

    def _compare_frequency(self, freq_a: Optional[int], freq_b: Optional[int]) -> int:
        if freq_a is not None and freq_b is not None:
            return freq_a - freq_b
        elif freq_a is not None:
            return -1
        elif freq_b is not None:
            return 1
        return 0

    def _sort_by_likelihood(self, results: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        def sort_key(result):
            base = result["base"]
            freq = self.frequency_for_word.get(base)
            suru_freq = self._get_frequency_for_suru_verb(base)

            return (
                freq is None,
                freq if freq is not None else float("inf"),
                suru_freq is None,
                suru_freq if suru_freq is not None else float("inf"),
                len(base),
            )

        return sorted(results, key=sort_key)

    def _get_candidate_derivations(self, word_type: WordType, word: str) -> List[Dict[str, Any]]:
        if word_type == WordType.SENTENCE:
            candidate_derivations = rules
        else:
            candidate_derivations = self.derivation_rules_for_conjugated_word_type.get(word_type, [])

        matching_derivations = [d for d in candidate_derivations if word.endswith(d["conjugated_ending"])]
        # Sort by conjugated ending length (descending) to prioritize longer, more specific matches
        return sorted(matching_derivations, key=lambda d: len(d["conjugated_ending"]), reverse=True)

    def _derivation_is_silent(self, derivation: Dict[str, Any]) -> bool:
        return DerivationAttribute.SILENT in derivation.get("attributes", [])

    def _copy_derivation_sequence(self, derivation_sequence: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "non_silent_derivations_taken": derivation_sequence["non_silent_derivations_taken"][:],
            "non_silent_word_form_progression": derivation_sequence["non_silent_word_form_progression"][:],
            "all_derivations_taken": derivation_sequence["all_derivations_taken"][:],
        }

    def _unconjugate_word(self, word: str, derivation: Dict[str, Any]) -> str:
        conjugated_ending_length = len(derivation["conjugated_ending"])
        if conjugated_ending_length == 0:
            return word + derivation["unconjugated_ending"]
        else:
            return word[:-conjugated_ending_length] + derivation["unconjugated_ending"]

    def _took_invalid_derivation_path(self, derivation_sequence: Dict[str, Any]) -> bool:
        all_derivations_taken = derivation_sequence["all_derivations_taken"]
        for i, derivation in enumerate(all_derivations_taken):
            if "cannot_follow" not in derivation:
                continue
            for forbidden_predecessor_sequence in derivation["cannot_follow"]:
                next_derivation_offset = 1
                for g in range(len(forbidden_predecessor_sequence) - 1, -1, -1):
                    if i + next_derivation_offset >= len(all_derivations_taken):
                        break
                    next_derivation = all_derivations_taken[i + next_derivation_offset]
                    if not next_derivation or next_derivation["conjugated_word_type"] != forbidden_predecessor_sequence[g]:
                        break
                    if g == 0:
                        return True
                    next_derivation_offset += 1
        return False

    def _create_derivation_sequence_output_form(self, derivation_sequence: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "derivations": [d["conjugated_word_type"] for d in reversed(derivation_sequence["non_silent_derivations_taken"])],
            "word_form_progression": list(reversed(derivation_sequence["non_silent_word_form_progression"])),
        }

    def _unconjugate_recursive(self, word: str, word_type: WordType, derivation_sequence: Dict[str, Any], level: int, level_limit: int) -> List[Dict[str, Any]]:
        if self._took_invalid_derivation_path(derivation_sequence):
            return []

        if level > level_limit:
            return []

        results = []
        is_dictionary_form = word_type in [WordType.GODAN_VERB, WordType.ICHIDAN_VERB, WordType.SENTENCE]

        if is_dictionary_form:
            results.append({"base": word, "derivation_sequence": self._create_derivation_sequence_output_form(derivation_sequence)})

        candidate_derivations = self._get_candidate_derivations(word_type, word)

        for candidate_derivation in candidate_derivations:
            next_derivation_sequence = self._copy_derivation_sequence(derivation_sequence)
            next_derivation_sequence["all_derivations_taken"].append(candidate_derivation)

            if not self._derivation_is_silent(candidate_derivation):
                next_derivation_sequence["non_silent_derivations_taken"].append(candidate_derivation)
                next_derivation_sequence["non_silent_word_form_progression"].append(word)

            unconjugated_word = self._unconjugate_word(word, candidate_derivation)

            results.extend(
                self._unconjugate_recursive(
                    unconjugated_word,
                    candidate_derivation["unconjugated_word_type"],
                    next_derivation_sequence,
                    level + 1,
                    level_limit,
                )
            )
        
        # Deduplicate results based on base and derivation_sequence
        seen = set()
        deduplicated_results = []
        for result in results:
            # Create a hashable key from base and derivation_sequence
            key = (result["base"], str(result["derivation_sequence"]))
            if key not in seen:
                seen.add(key)
                deduplicated_results.append(result)
        
        return deduplicated_results

    def unconjugate(self, word: str, fuzzy: bool = False, recursion_depth_limit: int = 42) -> List[Dict[str, Any]]:
        results = self._unconjugate_recursive(
            word,
            WordType.SENTENCE,
            {"non_silent_derivations_taken": [], "non_silent_word_form_progression": [], "all_derivations_taken": []},
            0,
            recursion_depth_limit,
        )

        if fuzzy and not results:
            truncated_word = word[:-1]
            while truncated_word and not results:
                results.extend(
                    self._unconjugate_recursive(
                        truncated_word,
                        WordType.SENTENCE,
                        {
                            "non_silent_derivations_taken": [],
                            "non_silent_word_form_progression": [],
                            "all_derivations_taken": [],
                        },
                        0,
                        recursion_depth_limit,
                    )
                )
                truncated_word = truncated_word[:-1]

        return self._sort_by_likelihood(results)
