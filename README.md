# Influx

Prototype for an integrated content-based language learning environment. This doc may be out of date.

**Warning** 

This is only intended for local use. There are zero security measures. The database schema may change at any time and break previous versions.

**Is this usable at its current state?**

No. Not yet. It technically has a functioning database and text reader, but the dictionary and translation integrations are quite primitive. The UI needs a lot of work. No clue how to package and distribute this thing.

**Links**

- Phase I dev log [here](https://chaosarium.xyz/influx-dev-log-phase-i/)
- Continuous dev log [here](https://chaosarium.xyz/influx-dev-log/)
- The concept [here](https://chaosarium.xyz/2022-07-18-towards-an-integrated-content-based-language-learning-environment-an-exploratory-proposal/)

**Disclaimer**

LLM wrote some of the non-critical code and they might be bad

## Features

- [x] language-agnostic nlp 
    - [x] text segmentation & tokenization
    - [x] lemmatization
    - [x] pos tagging
    - [x] dependency parsing
    - [x] arbitrary additional morphological features
- [x] tracking known/learning terms
- [x] phrase tracking and detection
- [x] translation integration
- [x] annotated text reader
- [x] language-specific nlp
    - [x] japanese — auto furigana
    - [x] japanese — inflection derivation chain
- [ ] reasonable ui
    - [ ] everything other than the text reader _(80% there)_
    - [ ] the text reader _(50% there)_
    - [ ] full ui consistency
- [ ] dictionary integration _(post-first-release)_
    - [x] stardict kind of works
- [ ] srs _(post-first-release)_
- [ ] import data from lwt _(planned sibling project)_
- [ ] docker container _(gotta be able to run it somehow ╮(╯▽╰)╭)_
- [ ] make ux fun _(post-first-release)_
    - [ ] token status stats for documents
    - [ ] better filtering of doc/lang listings
    - [ ] term browser + editor outside doc

## Development notes

### Architecture

- Backend in Rust (Axum + Postgres)
- NLP Service in Python
- Frontend in Elm

### Key issues to decide / address

- how to handle lemmatization? should lemma be used as default? how does user manually assign lemma? should lemma and reflexes be separate entries? how to relate them in the database?
    - some ideas [here](https://chaosarium.xyz/influx-dev-log-phase-i/#lemma-vs-inflection-learners-perspective)
- how to integrate user-provided dictionaries?
- how to allow extensions? should there be support for custom nlp scripts?

## Running development server

See the `justfile`s.
