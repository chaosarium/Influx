-- note this is not versioned yet. it's subject to change before a proper release

CREATE TABLE IF NOT EXISTS language (
    id BIGSERIAL PRIMARY KEY,

    code TEXT NOT NULL,
    dicts TEXT[] NOT NULL,
    name TEXT NOT NULL,
    tts_rate DOUBLE PRECISION,
    tts_pitch DOUBLE PRECISION,
    tts_voice TEXT,
    deepl_source_lang TEXT,
    deepl_target_lang TEXT,
    
    created_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp,
    updated_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp
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

CREATE TABLE IF NOT EXISTS token (
    id BIGSERIAL PRIMARY KEY,
    lang_id BIGINT NOT NULL REFERENCES language (id) ON DELETE CASCADE,
    
    orthography TEXT NOT NULL,
    phonetic TEXT NOT NULL DEFAULT '',
    definition TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    original_context TEXT NOT NULL DEFAULT '',
    
    status token_status NOT NULL DEFAULT 'L1',
    CONSTRAINT token_status_not_unmarked CHECK (status <> 'UNMARKED'),
    
    UNIQUE(lang_id, orthography),
    created_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp,
    updated_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp
);

CREATE TABLE IF NOT EXISTS phrase (
    id BIGSERIAL PRIMARY KEY,
    lang_id BIGINT NOT NULL REFERENCES language (id) ON DELETE CASCADE,

    orthography_seq TEXT[] NOT NULL,
    definition TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    original_context TEXT NOT NULL DEFAULT '',
    
    status token_status NOT NULL DEFAULT 'UNMARKED',
    
    UNIQUE(lang_id, orthography_seq),
    created_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp,
    updated_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp
);

-- Trigger function for updating updated_ts
CREATE OR REPLACE FUNCTION set_updated_ts()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_ts = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for each table
CREATE TRIGGER set_updated_ts_language
BEFORE UPDATE ON language
FOR EACH ROW
EXECUTE FUNCTION set_updated_ts();

CREATE TRIGGER set_updated_ts_token
BEFORE UPDATE ON token
FOR EACH ROW
EXECUTE FUNCTION set_updated_ts();

CREATE TRIGGER set_updated_ts_phrase
BEFORE UPDATE ON phrase
FOR EACH ROW
EXECUTE FUNCTION set_updated_ts();

CREATE TABLE IF NOT EXISTS document (
    id BIGSERIAL PRIMARY KEY,
    lang_id BIGINT NOT NULL REFERENCES language (id) ON DELETE CASCADE,
    
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    doc_type TEXT NOT NULL DEFAULT 'Text',
    tags TEXT[] NOT NULL DEFAULT '{}',
    
    created_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp,
    updated_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp
);

CREATE TRIGGER set_updated_ts_document
BEFORE UPDATE ON document
FOR EACH ROW
EXECUTE FUNCTION set_updated_ts();

CREATE TABLE IF NOT EXISTS annotated_document_cache (
    id BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL REFERENCES document (id) ON DELETE CASCADE,
    
    text_checksum TEXT NOT NULL,
    cached_data JSONB NOT NULL,
    
    created_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp,
    updated_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp,
    
    UNIQUE(document_id, text_checksum)
);

CREATE TRIGGER set_updated_ts_annotated_document_cache
BEFORE UPDATE ON annotated_document_cache
FOR EACH ROW
EXECUTE FUNCTION set_updated_ts();

