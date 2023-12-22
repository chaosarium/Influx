# Influx

Prototype for an integrated content-based language learning environment.

## Development notes

### Architecture

- SurrealDB + Axum + Disk as backend service exposing an API
- Svelte frontend consumes the API 
- Tauri as a desktop client

### For future self

- Use `toml = "0.8.8"` for toml settings parsing and editing.
- Current implementation is for rapid development. Change all unwrap to proper error handling. 