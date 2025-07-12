import stanza
import spacy

class BaseParser:
    def __init__(self):
        self.name = "BaseParser"
        self.cache = {}
    
    def _get_cache_opt(self, lang_code: str) -> dict:
        if (self.name, lang_code) in self.cache:
            return self.cache[(self.name, lang_code)]
        return None
    
    def _set_cache(self, lang_code: str, lang_pipeline) -> None:
        self.cache[(self.name, lang_code)] = lang_pipeline
        
    def _init_for_lang(self, lang_code: str) -> any:
        raise NotImplementedError("This method should be implemented by subclasses.")
        
    def _parse_with_pipeline(self, text: str, lang_pipeline) -> any:
        raise NotImplementedError("This method should be implemented by subclasses.")
    
    def parse(self, text: str, lang_code: str) -> dict:
        lang_pipeline = self._get_cache_opt(lang_code)
        if lang_pipeline is None:
            lang_pipeline = self._init_for_lang(lang_code)
            self._set_cache(lang_code, lang_pipeline)

        return self._parse_with_pipeline(text, lang_pipeline)

class StanzaParser(BaseParser): 
    def __init__(self, model_dir: str):
        super().__init__()
        self.model_dir = model_dir
    
    def _init_for_lang(self, lang_code: str) -> dict:
        nlp = stanza.Pipeline(lang=lang_code, processors='tokenize, lemma, mwt, pos', model_dir=self.model_dir, logging_level='WARN')
        return nlp
    
    def _parse_with_pipeline(self, text: str, nlp) -> dict:
        doc = nlp(text)
        sentences = []
        for sentence in doc.sentences:
            sentences.append([token.to_dict() for token in sentence.tokens])
        return sentences

class SpacyParser(BaseParser):
    def __init__(self):
        super().__init__()
    
    def _init_for_lang(self, lang_code: str) -> dict:
        match lang_code:
            case 'ja':
                spacy_model = 'ja_ginza'
                
            case 'en':
                spacy_model = 'en_core_web_sm'
            case _:
                raise ValueError("haven't figured out what model to use yet...")
        nlp = spacy.load(spacy_model)
        return nlp
    
    def _parse_with_pipeline(self, text: str, nlp) -> dict:
        doc = nlp(text)
        sentences = []
        for sent in doc.sents:
            # available token attributes https://spacy.io/api/token#attributes
            tokens = []
            for token in sent:
                tokens.append({
                    'idx': token.i, # index within doc
                    'text': token.text, # verbatim text
                    'start_char': token.idx,
                    'end_char': token.idx + len(token.text),
                    
                    'lemma': token.lemma_, # lemma
                    
                    'is_punctuation': token.is_punct, # is punctuation
                    
                    'upos': token.pos_, # universal part-of-speech tag
                    'xpos': token.tag_, # fine-grained part-of-speech tag

                    'dep_head_idx': token.head.i, # index of head token
                    'dep_relation': token.dep_, # dep relation str
                    
                    'morphological_analysis': token.morph.to_dict(), # morphological features
                })
            sentences.append({
                'tokens': tokens, 
                'start_char': sent.start_char,
                'end_char': sent.end_char,
                'start_tkn': sent.start,
                'end_tkn': sent.end,
            })
        return {
            'sentences': sentences,
        }