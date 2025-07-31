-- note this is not versioned yet. it's subject to change before a proper release

CREATE TABLE IF NOT EXISTS language (
    id BIGSERIAL PRIMARY KEY,

    dicts TEXT[] NOT NULL,
    name TEXT NOT NULL,
    tts_rate DOUBLE PRECISION,
    tts_pitch DOUBLE PRECISION,
    tts_voice TEXT,
    deepl_source_lang TEXT,
    deepl_target_lang TEXT,
    parser_config JSONB NOT NULL DEFAULT '{"which_parser": "base_spacy", "parser_args": {"spacy_model": "en_core_web_sm"}}'::jsonb,
    
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

-- FSRS Integration Tables

-- Card types enumeration
CREATE TYPE card_type AS ENUM (
    'RECOGNITION',    -- Form → Meaning
    'PRODUCTION',     -- Meaning → Form  
    'CLOZE'           -- Context → Fill blank
);

-- Card state for lifecycle management
CREATE TYPE card_state AS ENUM (
    'ACTIVE',         -- Normal card in rotation
    'SUSPENDED',      -- Temporarily paused
    'ARCHIVED',       -- Permanently disabled but kept for history
    'DISABLED'        -- User-disabled, can be re-enabled
);

-- FSRS scheduler configuration per language
CREATE TABLE IF NOT EXISTS fsrs_language_config (
    id BIGSERIAL PRIMARY KEY,
    lang_id BIGINT NOT NULL REFERENCES language (id) ON DELETE CASCADE,
    
    -- FSRS Parameters (21 weights as JSON array)
    fsrs_weights JSONB NOT NULL DEFAULT '[0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001, 1.8722, 0.1666, 0.796, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014, 1.8729, 0.5425, 0.0912, 0.0658, 0.1542]',
    
    -- Desired retention rate (0.0-1.0)
    desired_retention DOUBLE PRECISION NOT NULL DEFAULT 0.9,
    
    -- Maximum interval in days
    maximum_interval INTEGER NOT NULL DEFAULT 36500, -- ~100 years
    
    -- Request retention for optimization
    request_retention DOUBLE PRECISION DEFAULT NULL,
    
    -- Which card types are enabled for this language (acts as filter)
    enabled_card_types card_type[] NOT NULL DEFAULT ARRAY['RECOGNITION'::card_type],
    
    -- Metadata
    created_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp,
    updated_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp,
    
    UNIQUE(lang_id)
);

-- Cards table - links tokens/phrases to FSRS scheduling
CREATE TABLE IF NOT EXISTS card (
    id BIGSERIAL PRIMARY KEY,
    
    -- Link to either token or phrase (but not both)
    token_id BIGINT REFERENCES token (id) ON DELETE CASCADE,
    phrase_id BIGINT REFERENCES phrase (id) ON DELETE CASCADE,
    
    -- Card configuration
    card_type card_type NOT NULL,
    card_state card_state NOT NULL DEFAULT 'ACTIVE',
    
    -- FSRS memory state (flattened fields from SerializableMemoryState)
    fsrs_stability REAL,
    fsrs_difficulty REAL,
    
    -- Scheduling info
    due_date TIMESTAMPTZ,
    last_review TIMESTAMPTZ,
    
    -- Metadata
    created_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp,
    updated_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp,
    
    -- Constraints
    CONSTRAINT card_has_target CHECK (
        (token_id IS NOT NULL AND phrase_id IS NULL) OR 
        (token_id IS NULL AND phrase_id IS NOT NULL)
    ),
    CONSTRAINT card_fsrs_memory_consistency CHECK (
        (fsrs_stability IS NULL AND fsrs_difficulty IS NULL) OR
        (fsrs_stability IS NOT NULL AND fsrs_difficulty IS NOT NULL)
    )
);

-- Unique indexes for card per (target, card_type)
CREATE UNIQUE INDEX idx_card_token_type ON card (token_id, card_type) WHERE token_id IS NOT NULL;
CREATE UNIQUE INDEX idx_card_phrase_type ON card (phrase_id, card_type) WHERE phrase_id IS NOT NULL;

-- Review history for FSRS optimization 
CREATE TABLE IF NOT EXISTS review_log (
    id BIGSERIAL PRIMARY KEY,
    card_id BIGINT NOT NULL REFERENCES card (id) ON DELETE CASCADE,
    
    -- Review details
    rating INTEGER NOT NULL, -- 1=Again, 2=Hard, 3=Good, 4=Easy
    review_time_ms INTEGER, -- Time taken to review in milliseconds
    
    -- FSRS state before this review (flattened fields from SerializableMemoryState)
    fsrs_stability_before REAL,
    fsrs_difficulty_before REAL,
    fsrs_stability_after REAL, 
    fsrs_difficulty_after REAL,
    
    -- Review context
    review_date TIMESTAMPTZ NOT NULL DEFAULT current_timestamp,
    
    CONSTRAINT valid_rating CHECK (rating >= 1 AND rating <= 4),
    CONSTRAINT review_fsrs_memory_before_consistency CHECK (
        (fsrs_stability_before IS NULL AND fsrs_difficulty_before IS NULL) OR
        (fsrs_stability_before IS NOT NULL AND fsrs_difficulty_before IS NOT NULL)
    ),
    CONSTRAINT review_fsrs_memory_after_consistency CHECK (
        (fsrs_stability_after IS NULL AND fsrs_difficulty_after IS NULL) OR
        (fsrs_stability_after IS NOT NULL AND fsrs_difficulty_after IS NOT NULL)
    )
);

-- Optimization history for tracking FSRS parameter updates
CREATE TABLE IF NOT EXISTS fsrs_optimization_log (
    id BIGSERIAL PRIMARY KEY,
    lang_id BIGINT NOT NULL REFERENCES language (id) ON DELETE CASCADE,
    
    -- Parameters before and after optimization
    weights_before JSONB NOT NULL,
    weights_after JSONB NOT NULL,
    
    -- Optimization metrics
    log_loss_before DOUBLE PRECISION,
    log_loss_after DOUBLE PRECISION,
    review_count INTEGER,
    
    -- Optimization details
    optimization_date TIMESTAMPTZ NOT NULL DEFAULT current_timestamp,
    notes TEXT DEFAULT ''
);

-- Triggers for updating timestamps
CREATE TRIGGER set_updated_ts_fsrs_language_config
BEFORE UPDATE ON fsrs_language_config
FOR EACH ROW
EXECUTE FUNCTION set_updated_ts();

CREATE TRIGGER set_updated_ts_card
BEFORE UPDATE ON card
FOR EACH ROW
EXECUTE FUNCTION set_updated_ts();

