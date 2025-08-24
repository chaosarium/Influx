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
- Do not make git commits for changes

## Directory Structure

```
.
├── influx_client  frontend written in Elm (with the elm-land framework)
├── influx_core    backend written in Rust
├── influx_nlp     language server currently used for tokenization
└── research       misc experiments
```

## Commands

- **Elm Frontend (in `influx_client`):** To see if influx_client type checks, compile it by running `elm-land build`.
  - No need to build `influx_client/assets/scss/main.scss`. There is already a background process that will build it automatically.
- **Python NLP Service (in `influx_nlp`):** `uv run pytest .`, `uv run pytest . --inline-snapshot=fix`, `uv run black .`
- **Rust (in `influx_core`):** `cargo test` (it's better to run specific test cases), `cargo fmt`, `cargo test generate_elm_bindings` (generates Elm types)
- **SQLX (in `influx_core`):** this is used for database migration. Run `cargo sqlx` to manage the development database.

More common commands are scattered around `**/justfile`s.

When updating the database schema, you should just do `cargo sqlx database reset` to recreate the database, as we are still doing rapid development. 

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

## Elm and CSS Guidelines

- `influx_client/assets/scss/main.scss` should use color variables defined in `influx_client/assets/scss/theme.scss` 
- Prefer minimal CSS. Use the least code to achive the desired effect.
- We use `rtfeldman/elm-css` for styling elm components inline, and the preferred practice is to drop and replace the default Html modules with the styled modules via, e.g. `import Html.Styled as Html exposing ...`, `import Html.Styled.Attributes as Attributes exposing ...`, `import Html.Styled.Events as Events exposing ...`, etc. There might still be legacy code that uses unstyled html, but we should adopt the new practice going forward (when possible, refactor to always use styled html).
- `Components.CssExtra` defines extra css functions like `gap` that's missing from elm-css.

## Testing

- Prefer snapshot tests in Python and Rust, and prefer tests that show a sequence of operations followed by a snapshot on the state after each notable operation.
- Test should clearly show what the expected output is. The snapshot should focus on important parts of the output.
- No testing in Elm

## Security/Authentication/Validation

Disregard these for now as the app is intended to run locally and we want to move quickly.

## Miscellaneous

Don't do `TestDb::new().await.unwrap()` in a helper function when testing. It doesn't work for mystery reason. Instead, do it in the test function itself.