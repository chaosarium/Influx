from flask import Flask, request
import argparse
from typing import TypedDict, Optional
from lib.parsing import SpacyParser, JapaneseParser
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


class TokeniserRequest(TypedDict):
    text: str


class TranslateRequest(TypedDict):
    text: str
    from_lang_id: str
    to_lang_id: str
    provider: str


class TranslateResponse(TypedDict):
    translated_text: str


class AppContext(TypedDict):
    port: Optional[int]
    parser: Optional[SpacyParser]


app = Flask(__name__)
context: AppContext = {"port": None, "parser": None}


@app.route("/")
def root_handler() -> str:
    port: Optional[int] = context["port"]
    return f"Hello, World! Running on port {port}"


# post is a workaroudn for large incoming data
@app.route("/tokeniser/<lang_code>", methods=["POST"])
def tokeniser_handler(lang_code: str) -> dict:
    data: TokeniserRequest = request.get_json()
    text: str = data.get("text", "")
    print(f"Received text: {text}, lang_code: {lang_code}")
    # for now, we route the parsers here. TODO someday, have the handler take parser selection as arg
    if lang_code == "ja":
        return context["ja_parser"].parse(text, lang_code)
    else:
        return context["parser"].parse(text, lang_code)


@app.route("/extern_translate", methods=["POST"])
def google_translate_handler() -> TranslateResponse:
    data: TranslateRequest = request.get_json()
    text: str = data.get("text")
    from_lang_id: str = data.get("from_lang_id")
    to_lang_id: str = data.get("to_lang_id")
    provider: str = data.get("provider")
    translated_text: str
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
                translated_text = "Invalid provider"
                # In a real application, you might want to return a proper error response with a status code
                return TranslateResponse(translated_text=translated_text)
        translated_text = translator.translate(text)
    except Exception as e:
        translated_text = str(e)
    print(translated_text)
    return TranslateResponse(translated_text=translated_text)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Arguments for NLP server")
    parser.add_argument("--port", type=int, help="The port to run the NLP server", required=True)
    args = parser.parse_args()

    context["port"] = args.port
    context["parser"] = SpacyParser()
    context["ja_parser"] = JapaneseParser()
    app.run(host="127.0.0.1", port=args.port)
