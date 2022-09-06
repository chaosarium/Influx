There are three layers

```
┌─────────────────────┐          ┌─────────────────────┐       ┌─────────────────────┐
│        DATA         │          │    MAIN PROCESS     │       │  RENDERER PROCESS   │
│                     │          │                     │       │                     │
│                     │◀────────▶│       Python        │◀─API─▶│        React        │
│       SQLite        │          │       Django        │       │        Next         │
│                     │          │       RESTful       │       │        Redux        │
└─────────────────────┘          └─────────────────────┘       └─────────────────────┘
```