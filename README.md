# Influx

Prototype for an integrated content-based language learning environment.

[![wakatime](https://wakatime.com/badge/github/chaosarium/Influx.svg?style=for-the-badge)](https://wakatime.com/badge/github/chaosarium/Influx)

**Is this usable at its current state?**

No. Not yet. It technically has a functioning database and text reader, but there is not yet any dictionary integration nor translation integration. The UI needs a lot of work. I have yet to figure out a way to package a binary built from rust with an embedding python interpreter.

**Its current state**

Some basic UI and working multilingual sentence segmentation and tokenization:

![preview img](https://share.cleanshot.com/jJ7ZTvndt73CCSVy9SDP+)
![preview img](https://share.cleanshot.com/WBHdH0n27571g1YjRwSD+)

Also now with phrase support!

![gif](https://share.cleanshot.com/t9BcLVrJxhTWV81TXp5b+)

**Links**

- Phase I dev log [here](https://chaosarium.xyz/influx-dev-log-phase-i/)
- Continuous dev log [here](https://chaosarium.xyz/influx-dev-log/)
- Proposal [here](https://chaosarium.xyz/2022-07-18-towards-an-integrated-content-based-language-learning-environment-an-exploratory-proposal/)


## Development notes

### Architecture

- SurrealDB + Axum + Disk as backend service exposing an API
- Python + Stanza via PyO3 for NLP
- Svelte + Tailwind frontend that interacts with the API 
- Tauri as a desktop client
- fsrs-rs for SRS algorithm

### Key issues to decide / address

- language table in database + tokens relate to language vs. single database file for each language
- how to handle lemmatization? should Stanza's lemma be used as default? how does user manually assign lemma? should lemma and reflexes be separate entries? how to relate them in the database?
- how to integrate user-provided dictionaries?
- how to allow extensions? should there be support for custom nlp scripts?

### Plan

(only a partial plan)

**Phase I - Project Skeleton**

- [x] file system content access
- [x] working vocabulary database
- [x] allow python scripting for extendable language support
- [x] text processing: tokenization, lemmatization, and sentence segmentation
- [x] document query api
- [x] basic text reader
- [x] token data write requests and confirmations
- [x] svelte routing structure
- [x] read toml language configurations
- [ ] read toml application configurations
- [x] language-specific file listing
- [x] ensure uniqueness of vocabulary database entries
- [ ] dictionary (pop up only for now) support
- [x] update added token id if saving unmarked
- [ ] Phrase parsing documentation
	- [x] some algorithm
	- [x] algorithm on Document
	- [ ] efficient algorithm
	- [x] frontend
- [x] database
	- [x] language database
	- [x] relate language and tokens
	- [x] lemma handling
	- [x] always lowercase tokens

**Phase II - Backend & Packaging**

- [ ] tauri wrapper
- [ ] figure out how to package python dependencies (check https://pyo3.rs/v0.14.2/building_and_distribution.html)
- [ ] document set up process
- [ ] build CI
- [ ] API error reporting
- [ ] Documentation?
- [ ] Caching Stanza outputs

**Phase III - Frontend Usability**

- [ ] UI design
- [ ] UI implementation
- [ ] loading indicators
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
- influx_api should be renamed influx_server

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

## Terminology (used in code base)

- A Document is the entire text, consisting of sentences
- A sentence is a series of sentence constituents
- A lexeme is either a token or a phrase
- Constituent refers to the part as it shows up in the document or sentence, whereas a lexeme refers to the instance currently in or would be in the database
- A phrase is a list of token orthographies
- A token is a single unit word or sub-word
- Orthography refers to the lowercase written form of a token
- Normalised orthography of a phrase is the orthograpies of the tokens it consists of joint by space; this is a workaround since javascript only likes string keys
- Text refers to the token's orthography in the original text so it could be partially uppercased
- A witespace token goes between lexemes within a sentence
- A whitespace document constituent goes between sentences in a document
- A composit token are things like `Let's` which contains subword tokens `Let` and `us`
- A single token are single words like `let` which can't be broken down further
- A phrase token is a phras pretending to be a token, for exampl `hello word` is a phrase but can also be treated like a grand composit token
- A token is shadowed if it's part of a bigger token or phrase, e.g. `let` and `us` are shadowed by `Let's`; `hello` and `world` are shadowed by `hello world`
- Lemma always refers to the orthography of the lemma

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
        - `/docs/{lang_identifier}/{filename}` returns a specific piece of content, with metadata, text, lemmatised and tokenised text, and results from querying vocabulary database


