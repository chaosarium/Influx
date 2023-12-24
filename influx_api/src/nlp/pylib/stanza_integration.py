def fun(text: str, language: str) -> list[list[list[dict[str, str|int]]]]:
    import stanza
    nlp = stanza.Pipeline(lang=language, processors='tokenize, lemma', download_method=None)
    doc = nlp(text)

    constituents = []
    for sentence in doc.sentences:
        constituents.append([token.to_dict() for token in sentence.tokens])
        
    return (doc.text, doc.num_tokens, len(doc.sentences), constituents)