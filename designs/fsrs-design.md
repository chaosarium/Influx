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

**Cards represent different ways to review terms, with database records only created to track review state and history**:

- **Terms are the content source**: Tokens and phrases contain all semantic content
- **Cards are review interaction types**: Recognition, Production, and Cloze test knowledge differently
- **Card database records track review state**: Only created when reviewed, storing FSRS memory state
- **Card content is always derived**: Front/back content comes from the associated term

### Card Types & Rating System

- **Recognition**: Form → Meaning
- **Production**: Meaning → Form (self-check)
- **Cloze**: Context with hidden word

FSRS 4-point rating: **Again (1)**, **Hard (2)**, **Good (3)**, **Easy (4)**

## Database Schema Design

### Core FSRS Tables

Implemented in `influx_core/migrations/000001_initial.sql`.

**Design Decision: Flattened Memory State Storage**
- Store `fsrs_stability` and `fsrs_difficulty` as separate `REAL` columns instead of JSON
- Better query performance and indexing vs JSONB operations
- Eliminates sqlx macro limitations with complex JSON types

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

## FSRS Integration with Token Maturity

FSRS states and token status (L1-L5, KNOWN, IGNORED) operate independently:

### Review Impact Algorithm
1. **Update FSRS State**: Use fsrs-rs to calculate new memory state
2. **Update Token Maturity**: Apply maturity adjustment based on review success

### Maturity Adjustment Rules
- **Again (1)**: Decrease maturity by 1 level (L3 → L2, L1 → L1)
- **Hard (2)**: No maturity change 
- **Good (3)**: Increase maturity by 1 level (L2 → L3, L5 → KNOWN)
- **Easy (4)**: Increase maturity by 1 level

## Implementation Phases

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

## Technical Implementation

### Key Types (fsrs-rs v5.0.0)

```rust
use fsrs::{FSRS, MemoryState, NextStates, ItemState, FSRSItem, FSRSReview};

pub struct FSRSScheduler {
    fsrs: FSRS,
    lang_id: InfluxResourceId,
    desired_retention: f32,
}

impl FSRSScheduler {
    pub fn next_states(&self, current_memory_state: Option<MemoryState>, days_elapsed: u32) -> Result<NextStates>
    pub fn memory_state(&self, reviews: Vec<FSRSReview>) -> Result<MemoryState>
    pub fn current_retrievability(&self, state: MemoryState, days_elapsed: u32, decay: f32) -> f32
}
```

### Database Storage Strategy

Flattened storage approach for FSRS memory state:

```rust
// Database representation
#[derive(sqlx::FromRow)]
pub struct CardInDB {
    pub fsrs_stability: Option<f32>,
    pub fsrs_difficulty: Option<f32>,
}

// Domain model
pub struct Card {
    pub fsrs_memory: Option<SerializableMemoryState>,
}

// Automatic conversion
impl From<CardInDB> for Card {
    fn from(db_entry: CardInDB) -> Self {
        let fsrs_memory = match (db_entry.fsrs_stability, db_entry.fsrs_difficulty) {
            (Some(stability), Some(difficulty)) => Some(SerializableMemoryState {
                stability, difficulty,
            }),
            _ => None,
        };
        Card { fsrs_memory, /* ... */ }
    }
}
```


### Testing Strategy

Use snapshot testing. Don't test trivial things that will obviously work based on the type system.

Use snapshot testing to make the test sequence readable. For SRS scheduling, for example, we can create a snapshot of the expected memory state after a series of reviews.

## Conclusion

This design provides a comprehensive foundation for integrating FSRS into Influx while maintaining the existing token-based learning system. The orthogonal approach ensures flexibility and allows users to benefit from both the intuitive maturity levels and the scientific accuracy of spaced repetition scheduling.

The phased implementation approach allows for iterative development and user feedback incorporation, ensuring the final system meets the needs of language learners while maintaining technical excellence.