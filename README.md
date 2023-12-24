# Influx

Prototype for an integrated content-based language learning environment.

[![wakatime](https://wakatime.com/badge/github/chaosarium/Influx.svg?style=for-the-badge)](https://wakatime.com/badge/github/chaosarium/Influx)

See devlog [here](a)

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
- [ ] read toml language configurations
- [ ] read toml application configurations
- [ ] language-specific file listing

**Phase II - Packaging**

- [ ] tauri wrapper
- [ ] figure out how to package python dependencies
- [ ] document set up process

**Phase III - Frontend Usability**

- [ ] feedback messages

**Phase IV - Frontend Language Learning Features**

- [ ] dictionary
- [ ] translation
- [ ] TTS
- [ ] sentence structure analysis?

**Phase V - Code Quality**

- [ ] error handling
- [ ] documentation
- [ ] security and accounts?

**Phase ? - Future**

- [ ] markdown rendering?
- [ ] video support
- [ ] audio support
- [ ] pdf + ocr support?

### For future self

- Use `toml = "0.8.8"` for toml settings parsing and editing.
- Current implementation is for rapid development. Change all unwrap to proper error handling. 
- File on disk could lead to race condition, but probabily won't encounter in single user situation
- Language settings could be on disk
- security? account? whatever for now as it's localhost

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