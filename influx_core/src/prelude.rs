pub use elm_rs::{Elm, ElmDecode, ElmEncode};
pub use serde::{Deserialize, Serialize};

macro_rules_attribute::derive_alias! {
    #[derive(SerdeDerives!)] = #[derive(Deserialize, Serialize)];
    #[derive(ElmDerives!)] = #[derive(Elm, ElmEncode, ElmDecode)];
}
