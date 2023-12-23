def fun(text: str, language: str) -> list[list[list[dict[str, str|int]]]]:
    import stanza
    nlp = stanza.Pipeline(lang=language, processors='tokenize, lemma')
    doc = nlp(text)
    print('processed doc:', flush=True)
    print("======== doc ========\n", doc, flush=True)

    res = []
    for sentence in doc.sentences:
        res.append([token.to_dict() for token in sentence.tokens])
        
    print("======== res ========\n", res, flush=True)
    return res