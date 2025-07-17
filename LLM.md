# Influx Development Notes

This is a new content-based language learning app called Influx. It's inspired by LWT but implemented using modern technology and using modern NLP techniques to assist language learning.

The code base is quite small. It may be helpful to query `influx_client/**/*.elm` and `influx_core/**/*.elm` files when needed. Note that `Bindings.elm` is generated from Rust (via `cargo test generate_elm_bindings`) and should not be updated manually. To generate an elm binding from Rust, add the type to `influx_core/src/lib.rs`

You can find a brief Elm syntax reference in `elm-syntax.txt`.

## Development Practices

- You should never revert git commits
- You should never unstage changes that are staged
- In general, do not touch existing comments. If a TODO comment is implemented, change it to DONE and leave the comment in place.
- `influx_core/migrations/000001_initial.sql` is currently the only `sql` version of interest. It's not the final version, so we can keep updating it without making new versions.
- Always run `just fmt` at project directory after finishing a task.

## Directory Structure

```
.
├── influx_client  frontend written in Elm (with the elm-land framework)
├── influx_core    backend written in Rust
├── influx_nlp     language server currently used for tokenization
├── research       misc experiments
└── toy_content    language contents for testing (deprecated)
```

## Commands

- **Elm Frontend (in `influx_client`):** To see if influx_client type checks, compile it by running `elm-land build`.
  - To build sass: `sass -w assets/scss/main.scss static/dist/main.css`
- **Python NLP Service (in `influx_nlp`):** `uv run pytest .`, `uv run pytest . --inline-snapshot=fix`, `uv run black .`
- **Rust (in `influx_core`):** `cargo test` (it's better to run specific test cases), `cargo fmt`, `cargo test generate_elm_bindings` (generates Elm types)
- **SQLX (in `influx_core`):** this is used for database migration. Run `cargo sqlx` to manage the development database.

More common commands are scattered around `**/justfile`s.

## Architecture

- Axum + Postgres (SurrealDB is deprecated, but we keep the code around) backend service exposing an API
- Python + NLP libraries via another HTTP server for NLP
  - The current focus is to get Spacy working while ignoring other things
- Elm frontend that interacts with the API
- fsrs-rs for SRS algorithm (planned)

## Code Style Guidelines

- Do not remove comments
- **In General:**
  - Prefer descriptive names, use domain terminology (Token, Phrase, DocSeg, etc.)
- **Python:**
  - Do not be sloppy about types. Do not do things like `if foo` when `foo` is a list. Do things like `if foo != []` instead.
  - Test cases use `inline-snapshot` and shold be snapshot tests.
  - Always include type annotation.
- **Elm:**
  - Component functions end in uppercase `C`, e.g. `textboxC` for some textbox component used in HTML forms.

## Security/Authentication/Validation

Disregard these for now as the app is intended to run locally and we want to move quickly.
