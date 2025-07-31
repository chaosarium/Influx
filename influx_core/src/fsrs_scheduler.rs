use crate::db::InfluxResourceId;
use anyhow::Result;
use fsrs::{FSRSItem, FSRSReview, MemoryState, NextStates, FSRS};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone)]
pub struct FSRSScheduler {
    fsrs: FSRS,
    pub lang_id: InfluxResourceId,
    pub desired_retention: f32,
}

impl FSRSScheduler {
    pub fn new(
        parameters: Option<&[f32]>,
        lang_id: InfluxResourceId,
        desired_retention: f32,
    ) -> Result<Self> {
        let fsrs = FSRS::new(parameters)?;
        Ok(Self {
            fsrs,
            lang_id,
            desired_retention,
        })
    }

    pub fn with_default_parameters(
        lang_id: InfluxResourceId,
        desired_retention: f32,
    ) -> Result<Self> {
        // Use default FSRS parameters
        let default_params: [f32; 21] = [
            0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001, 1.8722, 0.1666, 0.796,
            1.4835, 0.0614, 0.2629, 1.6483, 0.6014, 1.8729, 0.5425, 0.0912, 0.0658, 0.1542,
        ];
        Self::new(Some(&default_params), lang_id, desired_retention)
    }

    pub fn next_states(
        &self,
        current_memory_state: Option<MemoryState>,
        days_elapsed: u32,
    ) -> Result<NextStates> {
        Ok(self
            .fsrs
            .next_states(current_memory_state, self.desired_retention, days_elapsed)?)
    }

    pub fn memory_state(&self, reviews: Vec<FSRSReview>) -> Result<MemoryState> {
        let item = FSRSItem { reviews };
        Ok(self.fsrs.memory_state(item, None)?)
    }

    pub fn current_retrievability(&self, state: MemoryState, days_elapsed: u32, decay: f32) -> f32 {
        self.fsrs.current_retrievability(state, days_elapsed, decay)
    }
}

#[derive(
    Debug,
    Serialize,
    Deserialize,
    Clone,
    PartialEq,
    elm_rs::Elm,
    elm_rs::ElmEncode,
    elm_rs::ElmDecode,
)]
pub struct SerializableMemoryState {
    pub stability: f32,
    pub difficulty: f32,
}

impl From<MemoryState> for SerializableMemoryState {
    fn from(memory_state: MemoryState) -> Self {
        Self {
            stability: memory_state.stability,
            difficulty: memory_state.difficulty,
        }
    }
}

impl From<SerializableMemoryState> for MemoryState {
    fn from(serializable: SerializableMemoryState) -> Self {
        MemoryState {
            stability: serializable.stability,
            difficulty: serializable.difficulty,
        }
    }
}

pub fn memory_state_to_json(memory_state: MemoryState) -> Result<serde_json::Value> {
    let serializable = SerializableMemoryState::from(memory_state);
    Ok(serde_json::to_value(serializable)?)
}

pub fn memory_state_from_json(json: serde_json::Value) -> Result<MemoryState> {
    let serializable: SerializableMemoryState = serde_json::from_value(json)?;
    Ok(MemoryState::from(serializable))
}

#[cfg(test)]
mod tests {
    use super::*;
    use expect_test::expect;

    #[test]
    fn test_fsrs_scheduler_creation() {
        let lang_id = InfluxResourceId::SerialId(1);
        let scheduler = FSRSScheduler::with_default_parameters(lang_id, 0.9).unwrap();
        assert_eq!(scheduler.desired_retention, 0.9);
        assert_eq!(scheduler.lang_id, InfluxResourceId::SerialId(1));
    }

    #[test]
    fn test_memory_state_serialization() {
        let memory_state = MemoryState {
            stability: 2.5,
            difficulty: 5.0,
        };

        let json = memory_state_to_json(memory_state).unwrap();
        let deserialized = memory_state_from_json(json).unwrap();

        assert_eq!(memory_state.stability, deserialized.stability);
        assert_eq!(memory_state.difficulty, deserialized.difficulty);
    }

    #[test]
    fn test_next_states_calculation() {
        let lang_id = InfluxResourceId::SerialId(1);
        let scheduler = FSRSScheduler::with_default_parameters(lang_id, 0.9).unwrap();

        // Test with no previous memory state (new card)
        let next_states = scheduler.next_states(None, 0).unwrap();

        // Basic sanity checks
        assert!(next_states.again.interval > 0.0);
        assert!(next_states.hard.interval >= next_states.again.interval);
        assert!(next_states.good.interval >= next_states.hard.interval);
        assert!(next_states.easy.interval >= next_states.good.interval);

        expect![[r#"
            NextStates {
                again: ItemState {
                    memory: MemoryState {
                        stability: 0.212,
                        difficulty: 6.4133,
                    },
                    interval: 0.212,
                },
                hard: ItemState {
                    memory: MemoryState {
                        stability: 1.2931,
                        difficulty: 5.1121707,
                    },
                    interval: 1.2931,
                },
                good: ItemState {
                    memory: MemoryState {
                        stability: 2.3065,
                        difficulty: 2.118104,
                    },
                    interval: 2.3065,
                },
                easy: ItemState {
                    memory: MemoryState {
                        stability: 8.2956,
                        difficulty: 1.0,
                    },
                    interval: 8.2956,
                },
            }
        "#]]
        .assert_debug_eq(&next_states);
    }

    #[test]
    fn test_memory_state_from_reviews() {
        let lang_id = InfluxResourceId::SerialId(1);
        let scheduler = FSRSScheduler::with_default_parameters(lang_id, 0.9).unwrap();

        // Simulate a few reviews
        let reviews = vec![
            FSRSReview {
                rating: 3,
                delta_t: 0,
            }, // Good on first review
            FSRSReview {
                rating: 2,
                delta_t: 7,
            }, // Hard after 7 days
            FSRSReview {
                rating: 3,
                delta_t: 3,
            }, // Good after 3 days
        ];

        let memory_state = scheduler.memory_state(reviews).unwrap();

        // The memory state should have been updated by the reviews
        assert!(memory_state.stability > 0.0);
        assert!(memory_state.difficulty > 0.0);

        expect![[r#"
            MemoryState {
                stability: 22.354225,
                difficulty: 4.7433343,
            }
        "#]]
        .assert_debug_eq(&memory_state);
    }
}
