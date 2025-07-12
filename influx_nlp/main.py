from flask import Flask, request
import argparse
import stanza
from deep_translator import (
    GoogleTranslator,
    ChatGptTranslator,
    MicrosoftTranslator,
    PonsTranslator,
    LingueeTranslator,
    MyMemoryTranslator,
    YandexTranslator,
    PapagoTranslator,
    DeeplTranslator,
    QcriTranslator,
)

app = Flask(__name__)
context = {
    "loaded_pipelines": {},
}


def tokenise_text(text: str, language: str) -> tuple[str, int, int, list[list[list[dict[str, str | int]]]]]:
    if not language in context["loaded_pipelines"]:
        nlp = stanza.Pipeline(
            lang=language,
            processors="tokenize, lemma",
            model_dir=f"{context['influx_path']}/_stanza_resources/",
            logging_level="WARN",
        )
        context["loaded_pipelines"][language] = nlp
    else:
        nlp = context["loaded_pipelines"][language]

    doc = nlp(text)

    constituents = []
    for sentence in doc.sentences:
        constituents.append([token.to_dict() for token in sentence.tokens])

    # print(constituents)

    return {
        "text": doc.text,
        "num_tokens": doc.num_tokens,
        "num_sentences": len(doc.sentences),
        "constituents": constituents,
    }


@app.route("/")
def root_handler():
    port = context["port"]
    return f"Hello, World! Running on port {port}"


# post is a workaroudn for large incoming data
@app.route("/tokeniser/<lang_code>", methods=["POST"])
def tokeniser_handler(lang_code):
    data = request.get_json()
    text = data.get("text", "")
    print(f"Received text: {text}, lang_code: {lang_code}")
    return tokenise_text(text, lang_code)


@app.route("/extern_translate", methods=["POST"])
def google_translate_handler():
    data = request.get_json()
    text = data.get("text")
    from_lang_id = data.get("from_lang_id")
    to_lang_id = data.get("to_lang_id")
    provider = data.get("provider")
    try:
        match provider:
            case "google":
                translator = GoogleTranslator(source=from_lang_id, target=to_lang_id)
            case "chatgpt":
                translator = ChatGptTranslator(source=from_lang_id, target=to_lang_id)
            case "microsoft":
                translator = MicrosoftTranslator(source=from_lang_id, target=to_lang_id)
            case "pons":
                translator = PonsTranslator(source=from_lang_id, target=to_lang_id)
            case "linguee":
                translator = LingueeTranslator(source=from_lang_id, target=to_lang_id)
            case "mymemory":
                translator = MyMemoryTranslator(source=from_lang_id, target=to_lang_id)
            case "yandex":
                translator = YandexTranslator(source=from_lang_id, target=to_lang_id)
            case "papago":
                translator = PapagoTranslator(source=from_lang_id, target=to_lang_id)
            case "deepl":
                translator = DeeplTranslator(source=from_lang_id, target=to_lang_id)
            case "qcri":
                translator = QcriTranslator(source=from_lang_id, target=to_lang_id)
            case _:
                return "Invalid provider"
        translated_text = translator.translate(text)
    except Exception as e:
        translated_text = str(e)
    print(translated_text)
    return {"translated_text": translated_text}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Arguments for NLP server")
    parser.add_argument("--port", type=int, help="The port to run the NLP server", required=True)
    parser.add_argument("--influx_path", type=str, help="The path to the influx content directory", required=True)
    args = parser.parse_args()

    context["port"] = args.port
    context["influx_path"] = args.influx_path
    app.run(host="127.0.0.1", port=args.port)
