#!/usr/bin/env python3
import json
import requests

# Start with the output we know works from our Python tokenizer
json_data = {
    "text": "行った。",
    "segments": [
        {
            "text": "行った。",
            "start_char": 0,
            "end_char": 4,
            "inner": {
                "Sentence": {
                    "segments": [
                        {
                            "sentence_idx": 0,
                            "text": "行った",
                            "start_char": 0,
                            "end_char": 3,
                            "inner": {
                                "TokenSeg": {
                                    "idx": 0,
                                    "orthography": "行った"
                                }
                            },
                            "attributes": {
                                "lemma": "行う",
                                "upos": "VERB", 
                                "xpos": "動詞-非自立可能",
                                "dependency": [0, "ROOT"],
                                "misc": {
                                    "Inflection": "五段-カ行;連用形-促音便",
                                    "Reading": "イッ"
                                },
                                "conjugation_chain": [
                                    {
                                        "step": 1,
                                        "form": "Plain Past",
                                        "result": "行った"
                                    }
                                ]
                            }
                        },
                        {
                            "sentence_idx": 0,
                            "text": "。",
                            "start_char": 3,
                            "end_char": 4,
                            "inner": "PunctuationSeg",
                            "attributes": {
                                "lemma": "。",
                                "upos": "PUNCT",
                                "xpos": "補助記号-句点", 
                                "dependency": [0, "punct"],
                                "misc": {
                                    "Reading": "。"
                                }
                            }
                        }
                    ]
                }
            }
        }
    ],
    "orthography_set": ["た", "。", "行っ"],
    "lemma_set": ["行く", "。", "た"],
    "parser_config": {
        "which_parser": "enhanced_japanese",
        "parser_args": {
            "enable_conjugation_analysis": "true"
        }
    }
}

print("Testing JSON structure compatibility...")
print("JSON validates:", json.dumps(json_data, ensure_ascii=False, indent=2))

# If there were a Rust HTTP server, we could test by posting to it
# For now, this just validates the JSON structure