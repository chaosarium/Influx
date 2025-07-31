# FSRS Integration Design for Influx

## Overview

This document outlines the design for integrating the Free Spaced Repetition Scheduler (FSRS) algorithm into Influx, a content-based language learning application. The integration will provide scientifically-backed spaced repetition scheduling while maintaining orthogonality with the existing token status system.

## Goals

1. **Orthogonal Design**: FSRS states are separate from token maturity levels (L1-L5, KNOWN, etc.)
2. **Multi-Modal Cards**: Support multiple card types per term (e.g., cloze deletion, form→meaning, meaning→form)
3. **Language-Specific Configuration**: Per-language scheduler parameters and optimization
4. **Comprehensive Card Management**: Enable/disable/suspend/archive cards with proper state tracking
5. **User Experience**: Seamless integration with existing Influx workflow
6. **Performance**: Reasonably efficient scheduling and review querying

## Key Concepts

### Mental Model: Cards as Review State Trackers

The fundamental mental model for this system is that **cards represent different ways to review terms, with database records only created to track review state and history**. Think of the relationship this way:

- **Terms are the content source**: Tokens and phrases contain all the semantic content (definition, context, phonetics)
- **Cards are review interaction types**: Recognition, Production, and Cloze are different ways to test knowledge of the same term  
- **Card database records track review state**: Only created when a review occurs, storing FSRS memory state and scheduling info
- **Card content is always derived**: Front/back content comes from the associated term, never stored in the card record

This means a single term can have multiple associated card records (one per card type that has been reviewed), but each card record only contains scheduling metadata - the actual review content always comes from the term.

**Implementation Implications:**
- Card records are lightweight - just FSRS state, scheduling, and references
- Card content generation happens at review time by querying the associated term
- Enabling/disabling card types affects which records are queried, not which exist
- The system scales naturally without pre-creating records for unused card types

### FSRS Core Components

Based on the `fsrs-rs` crate, FSRS tracks:
- **Memory State**: Stability, difficulty, retrievability over time
- **Review History**: Timestamps, ratings, intervals
- **Next Review**: Scheduled review date based on desired retention

### Card Types

Multiple card types can be generated for each token/phrase:
- **Recognition**: Form → Meaning (seeing the word, recall definition)
- **Production**: Meaning → Form (seeing definition, check if you know the form)
- **Cloze**: Context with hidden word (sentence with blank to fill)

### Rating System

FSRS uses a 4-point rating system corresponding to:
- **Again (1)**: Complete failure, need to review immediately
- **Hard (2)**: Difficult recall, but eventually succeeded  
- **Good (3)**: Normal recall with expected effort
- **Easy (4)**: Effortless recall, too easy

These ratings map directly to the `FSRSReview.rating` field (u32: 1-4).

## Database Schema Design

### Core FSRS Tables

```sql
-- FSRS scheduler configuration per language
CREATE TABLE fsrs_language_config (
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
    enabled_card_types card_type[] NOT NULL DEFAULT ARRAY['RECOGNITION'],
    
    -- Metadata
    created_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp,
    updated_ts TIMESTAMPTZ NOT NULL DEFAULT current_timestamp,
    
    UNIQUE(lang_id)
);

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

-- Cards table - links tokens/phrases to FSRS scheduling
CREATE TABLE card (
    id BIGSERIAL PRIMARY KEY,
    
    -- Link to either token or phrase (but not both)
    token_id BIGINT REFERENCES token (id) ON DELETE CASCADE,
    phrase_id BIGINT REFERENCES phrase (id) ON DELETE CASCADE,
    
    -- Card configuration
    card_type card_type NOT NULL,
    card_state card_state NOT NULL DEFAULT 'ACTIVE',
    
    -- FSRS memory state (flattened from SerializableMemoryState)
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
    ),
    
    -- Unique card per (target, card_type)
    UNIQUE(token_id, card_type) WHERE token_id IS NOT NULL,
    UNIQUE(phrase_id, card_type) WHERE phrase_id IS NOT NULL
);

-- Review history for FSRS optimization 
CREATE TABLE review_log (
    id BIGSERIAL PRIMARY KEY,
    card_id BIGINT NOT NULL REFERENCES card (id) ON DELETE CASCADE,
    
    -- Review details
    rating INTEGER NOT NULL, -- 1=Again, 2=Hard, 3=Good, 4=Easy
    review_time_ms INTEGER, -- Time taken to review in milliseconds
    
    -- FSRS state before/after review (flattened from SerializableMemoryState)
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
CREATE TABLE fsrs_optimization_log (
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
```

### Design Decision: Flattened Memory State Storage

The database schema uses flattened storage for FSRS memory state instead of JSON:

- **Card Table**: `fsrs_stability` and `fsrs_difficulty` as separate `REAL` columns instead of `fsrs_memory JSONB`
- **Review Log Table**: Separate before/after columns for each memory state field
- **Database Constraints**: Ensures both memory state fields are NULL or both are NOT NULL for consistency
- **Performance Benefits**: Better query performance and indexing compared to JSONB operations
- **Type Safety**: Native PostgreSQL numeric types with proper sqlx integration
- **Simplicity**: Eliminates sqlx macro limitations with complex JSON generic types

### Integration with Existing Schema

The design maintains orthogonality by:
- **Token Status System**: Remains unchanged (L1-L5, KNOWN, IGNORED)
- **FSRS Cards**: Independent scheduling system that references tokens/phrases
- **Maturity Integration**: Review success/failure affects both FSRS memory and token maturity

## Card System

### Implicit Card Creation

Card creation is implicit rather than explicit. Terms (tokens and phrases) in learning states (L1-L5) are considered to have available cards without requiring database records. Cards only receive database records when they are first reviewed:

- **Before First Review**: Terms exist as potential cards with no database footprint
- **After First Review**: Card record is created with initial FSRS state and review history
- **Subsequent Reviews**: FSRS state is updated in the existing card record

This approach eliminates the need for bulk card creation operations and reduces database overhead for terms that may never be reviewed.

### Card Type Filtering

Users can choose which card types to review for each language through the `enabled_card_types` configuration. When querying cards for review, the system filters based on these preferences rather than creating/destroying cards.

### Card Type Specifications

#### Recognition Cards (Form → Meaning)
- **Front**: Token/phrase orthography + phonetic
- **Back**: Definition + notes + original context
- **Cloze Context**: Show usage examples

#### Production Cards (Meaning → Form)
- **Front**: Definition + context clues  
- **Back**: Token/phrase orthography + phonetic
- **Self-Check**: User checks if they knew the form correctly

#### Cloze Cards (Context → Fill)
- **Front**: Original context with token/phrase blanked out
- **Back**: Full context + definition
- **Generation**: Use `original_context` field from token/phrase

### Card State Management

```rust
pub enum CardTransition {
    Suspend,          // Temporarily pause (illness, travel, etc.)
    Resume,           // Resume from suspension
    Archive,          // Permanent removal (but keep history)
}
```

## API Design

### Review Session APIs

```rust
// Get cards due for review (includes implicit cards for terms in learning states)
pub async fn get_due_cards(
    &self,
    lang_id: InfluxResourceId,
    limit: Option<usize>,
) -> Result<Vec<CardWithContext>>

// Submit review and update FSRS state (creates card record if first review)
pub async fn submit_review(
    &self,
    card_identifier: CardIdentifier, // Can be existing card_id or (term_id, card_type)
    rating: FSRSRating,
    review_time_ms: Option<u32>,
) -> Result<ReviewResult>
```

### Card Management APIs

```rust
// Suspend/resume cards (e.g., during break)
pub async fn set_card_state(
    &self,
    card_id: InfluxResourceId,
    new_state: CardState,
) -> Result<Card>
```

### Configuration APIs

```rust
// Update FSRS parameters for a language
pub async fn update_fsrs_config(
    &self,
    lang_id: InfluxResourceId,
    config: FSRSLanguageConfig,
) -> Result<FSRSLanguageConfig>

// Update enabled card types for a language
pub async fn update_enabled_card_types(
    &self,
    lang_id: InfluxResourceId,
    card_types: Vec<CardType>,
) -> Result<()>
```

## FSRS Integration with Token Maturity

### Orthogonal Design Principle

The token status system (L1-L5, KNOWN, IGNORED) and FSRS states operate independently:

- **Token Status**: Represents user's subjective assessment of word difficulty/familiarity
- **FSRS Memory**: Represents objective learning progress based on review performance

### Review Impact Algorithm

When a review is submitted:

1. **Update FSRS State**: Use fsrs-rs to calculate new memory state
2. **Update Token Maturity**: Apply maturity adjustment based on review success

```rust
pub async fn process_review_impact(
    &self,
    card: &Card,
    rating: u32, // 1-4 rating
) -> Result<TokenStatusUpdate> {
    // Get current FSRS memory state from card
    let current_memory = card.fsrs_memory
        .as_ref()
        .map(|json| serde_json::from_value::<MemoryState>(json.clone()))
        .transpose()?;
    
    // Calculate days elapsed since last review
    let days_elapsed = card.last_review
        .map(|last| (Utc::now() - last).num_days().max(0) as u32)
        .unwrap_or(0);
    
    // Get next states from FSRS
    let next_states = self.fsrs_scheduler.next_states(current_memory, days_elapsed)?;
    
    // Select the appropriate next state based on rating
    let next_state = match rating {
        1 => next_states.again,
        2 => next_states.hard,
        3 => next_states.good,
        4 => next_states.easy,
        _ => return Err(anyhow::anyhow!("Invalid rating: {}", rating)),
    };
    
    // Update card with new FSRS state
    let updated_card = Card {
        fsrs_memory: Some(serde_json::to_value(next_state.memory)?),
        due_date: Some(Utc::now() + Duration::days(next_state.interval.round() as i64)),
        last_review: Some(Utc::now()),
        ..card.clone()
    };
    
    // Token maturity adjustment
    let maturity_change = match rating {
        1 => MaturityChange::Decrease(1), // Again
        2 => MaturityChange::None,        // Hard
        3 => MaturityChange::Increase(1), // Good
        4 => MaturityChange::Increase(1), // Easy
    };
    
    self.apply_maturity_change(&updated_card, maturity_change).await
}
```

### Maturity Adjustment Rules

- **Again (1)**: Decrease maturity by 1 level (L3 → L2, L1 → L1)
- **Hard (2)**: No maturity change (difficulty noted in FSRS)
- **Good (3)**: Increase maturity by 1 level (L2 → L3, L5 → KNOWN)
- **Easy (4)**: Increase maturity by 1 level (L2 → L3, L5 → KNOWN)

### Special Cases

- **IGNORED tokens**: No FSRS cards created
- **KNOWN tokens**: FSRS card auto archived
- **New tokens**: Start at L1 with fresh FSRS memory state

## User Experience Design

### Review Workflow

1. **Study Session Start**: User initiates review session for a language
2. **Card Queue**: System presents due cards in optimized order
3. **Review Interface**: Clean, focused UI with clear rating options
4. **Progress Feedback**: Show review count, number of remaining cards, progress bar
5. **Session End**: Summary statistics and next review predictions

### Card Management UI

- **Card Type Selection**: Language-level setting to choose which card types to review
- **Individual Card Archiving**: Archive specific cards that are no longer needed
- **Review History**: Timeline of reviews with performance trends

### Dashboard Integration

- **Daily Review Count**: Cards due today across all languages
- **Streak Tracking**: Consecutive days of reviews completed
- **Language Overview**: Per-language review activity

## Implementation Phases

### Phase 1: Foundation - Database Schema & Basic Types ✅ **COMPLETED**
**Deliverable:** Database schema with basic Rust types
- [x] Create database tables (`fsrs_language_config`, `card`, `review_log`, `fsrs_optimization_log`)
- [x] Add database migrations
- [x] Create Rust types for FSRS integration (`CardType`, `CardState`, `FSRSScheduler`)
- [x] Add fsrs-rs dependency and basic wrapper functions
- [x] Create Elm bindings for new types
- [x] Implement database CRUD operations for FSRS language config
- [x] Implement database CRUD operations for cards
- [x] Implement database CRUD operations for review logs  
- [x] Add comprehensive tests for all FSRS database operations
- [x] Fix PostgreSQL enum type mapping with proper sqlx::Type derives
- [x] Resolve sqlx JSON handling limitations with flattened memory state storage

**Status:** ✅ **COMPLETED** - Complete FSRS foundation with fully functional database operations.

**Technical Implementation:**
- **Database Schema**: Complete with flattened memory state storage using separate `fsrs_stability` and `fsrs_difficulty` columns
- **Type Safety**: All PostgreSQL enum types properly mapped with `sqlx::Type` derives
- **CRUD Operations**: All database functions implemented and tested (create, read, update for cards; create for review logs)
- **Memory State Storage**: Flattened approach eliminates sqlx macro limitations while maintaining domain model integrity
- **Database Constraints**: Ensure memory state field consistency (both NULL or both NOT NULL)
- **Comprehensive Testing**: 7 FSRS-specific tests + 27 total tests all passing

**Key Design Decisions:**
- **Flattened Memory State**: Store `SerializableMemoryState` fields as separate database columns instead of JSON
- **Automatic Conversion**: `From` traits handle conversion between flattened database representation and domain models
- **Database Constraints**: Ensure data integrity at the database level with consistency checks
- **Performance Optimization**: Native PostgreSQL numeric types provide better performance than JSONB operations

### Phase 2: Core Logic - FSRS Integration
**Deliverable:** Working FSRS scheduling without UI
- [ ] Implement `FSRSScheduler` with memory state management
- [ ] Create functions to get implicit cards for terms in learning states
- [ ] Implement review submission with on-demand card record creation
- [ ] Add FSRS state update logic after reviews
- [ ] Write unit tests for FSRS operations

### Phase 3: API Layer - Review Endpoints
**Deliverable:** HTTP APIs for review operations  
- [ ] Implement `get_due_cards` API endpoint
- [ ] Implement `submit_review` API endpoint  
- [ ] Add language configuration endpoints (`update_fsrs_config`, `update_enabled_card_types`)
- [ ] Add card state management endpoint (`set_card_state`)
- [ ] Create API integration tests

### Phase 4: Recognition Cards - Basic Review UI
**Deliverable:** Working review interface for Recognition cards
- [ ] Create review session UI components in Elm
- [ ] Implement Recognition card display (form → meaning)
- [ ] Add rating buttons (Again, Hard, Good, Easy) with API integration
- [ ] Create basic review session flow (start session, review cards, end session)
- [ ] Integration with existing Influx UI patterns

### Phase 5: Token Status Integration
**Deliverable:** FSRS reviews affect token maturity
- [ ] Implement maturity adjustment logic based on review ratings
- [ ] Update token status after reviews (L1-L5 progression)
- [ ] Add special handling for KNOWN/IGNORED tokens
- [ ] Test integration between FSRS state and token maturity system

### Phase 6: Production Cards
**Deliverable:** Self-check Production card support
- [ ] Implement Production card display (meaning → form)
- [ ] Add self-check UI (show answer, rate performance)
- [ ] Update card content generation for Production type
- [ ] Add Production card support to review session flow

### Phase 7: Cloze Cards  
**Deliverable:** Context-based Cloze card support
- [ ] Implement Cloze card display (context with blanks)
- [ ] Add cloze content generation from `original_context` field
- [ ] Update review UI to handle cloze interactions
- [ ] Add Cloze card support to review session flow

### Phase 8: Card Management
**Deliverable:** User controls for card preferences and archiving
- [ ] Create language settings UI for enabled card types
- [ ] Implement individual card archiving functionality
- [ ] Add card state management (suspend/resume/archive)
- [ ] Create review history display for individual cards

### Phase 9: Dashboard Integration
**Deliverable:** Review information in main Influx interface
- [ ] Add due card counts to dashboard
- [ ] Implement streak tracking
- [ ] Create per-language review activity overview
- [ ] Integrate review session entry points into existing UI

## Technical Considerations

### FSRS-rs v5.0.0 Integration

```rust
// Add to Cargo.toml
[dependencies]
fsrs = "5.0"
```

### Key Types and APIs

Based on fsrs-rs v5.0.0, the main types and APIs are:

```rust
use fsrs::{FSRS, MemoryState, NextStates, ItemState, FSRSItem, FSRSReview, ComputeParametersInput};

// Core memory state representation
#[derive(Debug, PartialEq, Clone, Copy)]
pub struct MemoryState {
    pub stability: f32,
    pub difficulty: f32,
}

// Serializable version for Elm bindings and database storage
#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Elm, ElmEncode, ElmDecode)]
pub struct SerializableMemoryState {
    pub stability: f32,
    pub difficulty: f32,
}

// States for each rating button (Again, Hard, Good, Easy)
#[derive(Debug, Clone, PartialEq)]
pub struct NextStates {
    pub again: ItemState,
    pub hard: ItemState, 
    pub good: ItemState,
    pub easy: ItemState,
}

#[derive(Debug, PartialEq, Clone)]
pub struct ItemState {
    pub memory: MemoryState,
    pub interval: f32,
}

// Review data structures
#[derive(Debug, Clone, Copy, Deserialize, Serialize, PartialEq, Eq)]
pub struct FSRSReview {
    pub rating: u32,  // 1-4 (Again, Hard, Good, Easy)
    pub delta_t: u32, // Days since last review
}

#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, Eq, Default)]
pub struct FSRSItem {
    pub reviews: Vec<FSRSReview>,
}

// FSRS scheduler wrapper for Influx
pub struct FSRSScheduler {
    fsrs: FSRS,
    lang_id: InfluxResourceId,
    desired_retention: f32,
}

impl FSRSScheduler {
    pub fn new(parameters: Option<&[f32]>, lang_id: InfluxResourceId, desired_retention: f32) -> Result<Self> {
        let fsrs = FSRS::new(parameters)?;
        Ok(Self { fsrs, lang_id, desired_retention })
    }
    
    pub fn next_states(&self, current_memory_state: Option<MemoryState>, days_elapsed: u32) -> Result<NextStates> {
        self.fsrs.next_states(current_memory_state, self.desired_retention, days_elapsed)
    }
    
    pub fn memory_state(&self, reviews: Vec<FSRSReview>) -> Result<MemoryState> {
        let item = FSRSItem { reviews };
        self.fsrs.memory_state(item, None)
    }
    
    pub fn current_retrievability(&self, state: MemoryState, days_elapsed: u32, decay: f32) -> f32 {
        self.fsrs.current_retrievability(state, days_elapsed, decay)
    }
    
    pub fn optimize_parameters(&self, items: Vec<FSRSItem>) -> Result<Vec<f32>> {
        let input = ComputeParametersInput {
            train_set: items,
            ..Default::default()
        };
        self.fsrs.compute_parameters(input)
    }
}
```

### Database Storage Strategy

The implementation uses a **flattened storage approach** for FSRS memory state:

```rust
// Database representation
#[derive(sqlx::FromRow)]
pub struct CardInDB {
    // ... other fields
    pub fsrs_stability: Option<f32>,     // Flattened from SerializableMemoryState
    pub fsrs_difficulty: Option<f32>,   // Flattened from SerializableMemoryState
}

// Domain model representation  
#[derive(Debug, Serialize, Deserialize)]
pub struct Card {
    // ... other fields
    pub fsrs_memory: Option<SerializableMemoryState>, // Reconstructed from individual fields
}

// Automatic conversion between representations
impl From<CardInDB> for Card {
    fn from(db_entry: CardInDB) -> Self {
        let fsrs_memory = match (db_entry.fsrs_stability, db_entry.fsrs_difficulty) {
            (Some(stability), Some(difficulty)) => Some(SerializableMemoryState {
                stability,
                difficulty,
            }),
            _ => None,
        };
        
        Card {
            fsrs_memory,
            // ... other field mappings
        }
    }
}
```

**Benefits of Flattened Storage:**
- **Performance**: Native PostgreSQL numeric types with proper indexing
- **Type Safety**: No JSON serialization issues with sqlx macros  
- **Query Efficiency**: Direct numeric comparisons vs JSONB operations
- **Simplicity**: Eliminates complex generic type handling in sqlx
- **Data Integrity**: Database-level constraints ensure field consistency

### Error Handling

- **FSRS Errors**: Proper error propagation from fsrs-rs
- **Database Consistency**: Transaction management for review submissions
- **Validation**: Input validation for ratings and configurations

### Testing Strategy

- **Unit Tests**: Individual FSRS operations and card generation
- **Integration Tests**: End-to-end review workflows

## Conclusion

This design provides a comprehensive foundation for integrating FSRS into Influx while maintaining the existing token-based learning system. The orthogonal approach ensures flexibility and allows users to benefit from both the intuitive maturity levels and the scientific accuracy of spaced repetition scheduling.

The phased implementation approach allows for iterative development and user feedback incorporation, ensuring the final system meets the needs of language learners while maintaining technical excellence.