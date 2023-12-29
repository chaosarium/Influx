# Influx

Prototype for an integrated content-based language learning environment.

[![wakatime](https://wakatime.com/badge/github/chaosarium/Influx.svg?style=for-the-badge)](https://wakatime.com/badge/github/chaosarium/Influx)

Links

- Devlog [here](https://chaosarium.xyz/influx-dev-log/)
- Proposal [here](https://chaosarium.xyz/2022-07-18-towards-an-integrated-content-based-language-learning-environment-an-exploratory-proposal/)

How it looks like right now, with working multilingual sentence segmentation and tokenization:

![preview img](https://share.cleanshot.com/s06w8VZ1ljSvtrRyTjCl+)

**Is this usable at its current state?**

No. Not yet. It technically has a functioning database and text reader, but there is not yet any dictionary integration nor translation integration. The UI needs a lot of work. There is also not yet a way to package the app into some binary due to complications with embedding python in rust.

## Development notes

### Architecture

- SurrealDB + Axum + Disk as backend service exposing an API
- Python + Stanza via PyO3 for NLP
- Svelte frontend that interacts with the API 
- Tauri as a desktop client
- fsrs-rs for SRS algorithm

### Plan

(only a partial plan)

**Phase I - Project Skeleton**

- [x] file system content access
- [x] working vocabulary database
- [x] allow python scripting for extendable language support
- [x] text processing: tokenization, lemmatization, and sentence segmentation
- [x] document query api
- [x] basic text reader
- [ ] token data write requests and confirmations
- [ ] svelte routing structure
- [x] read toml language configurations
- [ ] read toml application configurations
- [x] language-specific file listing
- [ ] ensure uniqueness of vocabulary database entries
- [ ] dictionary (pop up only for now) support

**Phase II - Backend & Packaging**

- [ ] tauri wrapper
- [ ] figure out how to package python dependencies (check https://pyo3.rs/v0.14.2/building_and_distribution.html)
- [ ] document set up process
- [ ] build CI
- [ ] API error reporting
- [ ] Documentation?
- [ ] Caching Stanza outputs

**Phase III - Frontend Usability**

= [ ] UI design
= [ ] UI implementation
- [ ] feedback messages
- [ ] typescript: export typescript for rust structs

**Phase IV - Frontend Language Learning Features**

- [ ] dictionary
- [ ] translation
- [ ] TTS
- [ ] sentence structure analysis?

**Phase V - Code Quality**

- [ ] better error handling
- [ ] documentation
- [ ] security and accounts?

**Phase ? - Future**

- [ ] markdown rendering?
- [ ] video support
- [ ] audio support
- [ ] pdf + ocr support?

### For future self

- Current implementation is for rapid development. Change all unwrap to proper error handling. 
- File on disk could lead to race condition, but probabily won't encounter in single user situation
- Language settings could be on disk
- security? account? whatever for now as it's localhost

## Running development server

### Setting up python

Try not using conda, it didn't work
Try not using mac's built-in python, it didn't work
Installing stanza in virtual environment doesn't work for some reason. have to install it on the system python

```sh 
brew install python@3.10
brew install pipenv
python3.10 -m pip install stanza
pipenv install
pipenv shell

rm /opt/homebrew/Cellar/python\@3*/**/EXTERNALLY-MANAGED
```

### Running influx server

```sh
cd influx_api
cargo run
```

### Running frontend

```sh
cd influx_ui
npm run dev
```

## API design

Method defaults to GET is unspecified

- `/` returns something random
- `/settings` returns app settings as json
    - `/langs` returns list of languages in settings
- `/vocab` to work with vocabs
    - `/vocab/token/{lang_identifier}/{orthography}` to query for a single token?
    - POST `/vocab/create_token` to create a token
    - POST `/vocab/update_token` to update a token
    - DELETE `/vocab/delete_token` to update a token
- `docs` to work with docs
    - `/docs/{lang_identifier}` returns list of content, with metadata, for the language specified by `lang_identifier`. Currently only supports markdown content.
        - `/docs/{lang_identifier}/{filename}` returns a specific piece of content, with metadata, text, tokenised text, and results from querying vocabulary database