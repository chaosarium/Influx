#!/usr/bin/env python3
import sys
sys.path.append('/Users/chaosarium/Documents/Repos/Influx/influx_nlp')

from lib.parsing import JapaneseParser
from lib.annotation import ParserConfig
import json

def test_japanese_tokenization():
    parser = JapaneseParser()
    text = "行った。"
    parser_config = ParserConfig(
        which_parser="enhanced_japanese",
        parser_args={"enable_conjugation_analysis": "true"}
    )
    
    result = parser.parse(text, parser_config)
    
    # Convert to dict to see the JSON structure
    result_dict = result.to_dict()
    print("JSON output:")
    print(json.dumps(result_dict, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    test_japanese_tokenization()