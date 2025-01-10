-- note this is not versioned yet. it's subject to change before a proper release

CREATE TABLE IF NOT EXISTS language (
    id BIGSERIAL PRIMARY KEY,
    identifier TEXT NOT NULL UNIQUE,

    code TEXT NOT NULL,
    dicts TEXT[] NOT NULL,
    name TEXT NOT NULL
);

CREATE TYPE token_status AS ENUM (
    'UNMARKED',
    'L1',
    'L2',
    'L3',
    'L4',
    'L5',
    'KNOWN',
    'IGNORED'
);

CREATE TABLE IF NOT EXISTS vocabulary (
    id BIGSERIAL PRIMARY KEY,
    lang_id BIGINT NOT NULL REFERENCES language (id) ON DELETE CASCADE,
    
    orthography TEXT NOT NULL,
    phonetic TEXT NOT NULL DEFAULT '',
    definition TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    original_context TEXT NOT NULL DEFAULT '',
    
    status token_status NOT NULL DEFAULT 'UNMARKED',
    
    UNIQUE(lang_id, orthography)
);

CREATE TABLE IF NOT EXISTS phrase (
    id BIGSERIAL PRIMARY KEY,
    lang_id BIGINT NOT NULL REFERENCES language (id) ON DELETE CASCADE,

    orthography_seq TEXT[] NOT NULL,
    definition TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    original_context TEXT NOT NULL DEFAULT '',
    
    status token_status NOT NULL DEFAULT 'UNMARKED',
    
    UNIQUE(lang_id, orthography_seq)
);

-- this is a dummy db for testing
CREATE TABLE IF NOT EXISTS todos
(
    id          BIGSERIAL PRIMARY KEY,
    text        TEXT    NOT NULL,
    completed   BOOLEAN NOT NULL DEFAULT FALSE
);