# Influx

Prototype for an integrated content-based language learning environment.

## Development notes

### Architecture

- SurrealDB + Axum + Disk as backend service exposing an API
- Python via PyO3 for NLP
- Svelte frontend consumes the API 
- Tauri as a desktop client

### For future self

- Use `toml = "0.8.8"` for toml settings parsing and editing.
- Current implementation is for rapid development. Change all unwrap to proper error handling. 
- File on disk could lead to race condition, but probabily won't encounter in single user situation