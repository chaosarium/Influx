from flask import Flask, request
import argparse
from typing import TypedDict, Optional
from lib.parsing import SpacyParser, JapaneseParser
from dataclasses import dataclass
from loguru import logger
from lib.annotation import AnnotatedDocV2, ParserConfig
import logging


class LoguruHandler(logging.Handler):
    """Custom logging handler that routes all log records to loguru."""

    def emit(self, record: logging.LogRecord) -> None:
        try:
            level = logger.level(record.levelname).name
        except ValueError:
            level = record.levelno

        logger.opt(depth=6, exception=record.exc_info).log(level, record.getMessage())


@dataclass
class TokeniserRequest:
    text: str
    parser_config: ParserConfig


@dataclass
class AppContext:
    port: int
    base_spacy: SpacyParser
    japanese_parser: JapaneseParser


app = Flask(__name__)
context: Optional[AppContext]


@app.route("/")
def root_handler() -> str:
    logger.debug("Health check endpoint accessed")
    return f"Influx NLP Service running on port {context.port}"


@app.route("/tokeniser", methods=["POST"])
def tokeniser_handler() -> dict:
    request_data = request.get_json()
    logger.debug("Received tokeniser request")

    data = TokeniserRequest(
        text=request_data["text"],
        parser_config=ParserConfig(
            which_parser=request_data["parser_config"]["which_parser"],
            parser_args=request_data["parser_config"]["parser_args"],
        ),
    )

    logger.info(
        "Processing tokenisation request",
        extra={
            "text_length": len(data.text),
            "text_preview": data.text[:20] + "..." if len(data.text) > 20 else data.text,
            "parser_config": data.parser_config,
        },
    )

    match data.parser_config.which_parser:
        case "enhanced_japanese":
            annotated_doc: AnnotatedDocV2 = context.japanese_parser.parse(data.text, data.parser_config)
        case "base_spacy":
            annotated_doc: AnnotatedDocV2 = context.base_spacy.parse(data.text, data.parser_config)
        case _:
            logger.error("Invalid parser specified", extra={"parser": data.parser_config.which_parser})
            return {"error": "Invalid which_parser"}, 500

    return annotated_doc.to_rust_dict()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Arguments for NLP server")
    parser.add_argument("--port", type=int, help="The port to run the NLP server", required=True)
    parser.add_argument(
        "--log-level",
        type=str,
        default="DEBUG",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        help="Set the logging level",
    )
    args = parser.parse_args()

    logger.remove()
    logger.add(
        lambda msg: print(msg, end=""),
        format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{file.name}:{line}</cyan> - <level>{message}</level> {extra}",
        level=args.log_level,
        colorize=True,
    )

    logger.info("Starting Influx NLP Service", extra={"port": args.port, "log_level": args.log_level})

    # Configure Flask logging to use loguru
    logging.basicConfig(handlers=[LoguruHandler()], level=0, force=True)
    # Also set werkzeug (Flask's WSGI server) to use loguru
    logging.getLogger("werkzeug").handlers = [LoguruHandler()]
    logging.getLogger("werkzeug").setLevel(logging.DEBUG)

    context = AppContext(port=args.port, base_spacy=SpacyParser(), japanese_parser=JapaneseParser())
    logger.success("Application context created")

    logger.info("Starting Flask server", extra={"host": "127.0.0.1", "port": context.port})
    app.run(host="127.0.0.1", port=context.port, debug=False)
