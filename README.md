# Influx

Prototype for an integrated content-based language learning environment.

## Development notes

### Architecture

- SurrealDB + Axum + Disk as backend service exposing an API
- Python + Stanza via PyO3 for NLP
- Svelte frontend that interacts with the API 
- Tauri as a desktop client
- fsrs-rs for SRS algorithm

### For future self

- Use `toml = "0.8.8"` for toml settings parsing and editing.
- Current implementation is for rapid development. Change all unwrap to proper error handling. 
- File on disk could lead to race condition, but probabily won't encounter in single user situation
- Language settings could be on disk
- security? account? whatever for now as it's localhost

### Future features

- [ ] markdown rendering?
- [ ] video support
- [ ] audio support
- [ ] pdf + ocr support?