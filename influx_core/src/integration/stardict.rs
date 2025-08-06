use stardict::{no_cache, with_sled, StarDict};
use std::collections::HashMap;

pub struct StardictManager {
    dictionaries: HashMap<String, Box<dyn StarDict + Send>>,
    use_cache: bool,
}

impl StardictManager {
    pub fn new() -> Self {
        Self {
            dictionaries: HashMap::new(),
            use_cache: false,
        }
    }

    pub fn new_with_cache() -> Self {
        Self {
            dictionaries: HashMap::new(),
            use_cache: true,
        }
    }

    pub fn load_dictionary(&mut self, ifo_path: String) -> &mut Box<dyn StarDict + Send> {
        if !self.dictionaries.contains_key(&ifo_path) {
            let dict: Box<dyn StarDict + Send> = if self.use_cache {
                // TODO cache name is definitely not right. maybe use the path library to get our app data dir?
                Box::new(with_sled(&ifo_path, "influx_stardict").unwrap())
            } else {
                Box::new(no_cache(&ifo_path).unwrap())
            };
            self.dictionaries.insert(ifo_path.clone(), dict);
        }

        self.dictionaries.get_mut(&ifo_path).unwrap()
    }

    pub fn lookup_word(
        &mut self,
        ifo_path: String,
        word: &str,
    ) -> anyhow::Result<Option<Vec<stardict::WordDefinition>>> {
        let dict: &mut Box<dyn StarDict + Send> = self.load_dictionary(ifo_path);

        dict.lookup(word)
            .map_err(|e| anyhow::anyhow!("Failed to lookup word '{}': {}", word, e))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use insta::assert_debug_snapshot;

    fn get_jitendex_path() -> String {
        "/Users/chaosarium/Documents/Repos/Influx/dictionaries/jitendex/jitendex.ifo".to_string()
    }

    fn get_fra_eng_path() -> String {
        "/Users/chaosarium/Documents/Repos/Influx/dictionaries/fra-eng/fra-eng.ifo".to_string()
    }

    fn truncated_definitions<E>(
        definitions: Result<Option<Vec<stardict::WordDefinition>>, E>,
    ) -> Result<Option<Vec<stardict::WordDefinition>>, E> {
        definitions.map(|opt| {
            opt.map(|defs| {
                defs.into_iter()
                    .map(|mut def| {
                        for segment in &mut def.segments {
                            if segment.text.len() > 15 {
                                segment.text.truncate(15);
                                segment.text.push_str("...");
                            }
                        }
                        def
                    })
                    .collect()
            })
        })
    }

    #[test]
    fn test_direct_stardict_interface() {
        let path = get_fra_eng_path();
        let mut dict = no_cache(get_fra_eng_path()).unwrap();

        dict.ifo.description = if dict.ifo.description.len() > 10 {
            let mut truncated = dict.ifo.description[..10].to_string();
            truncated.push_str("...");
            truncated
        } else {
            dict.ifo.description.clone()
        };
        assert_debug_snapshot!((dict.ifo(), dict.dict_name()), @r#"
        (
            Ifo {
                version: V300,
                bookname: "French-English FreeDict Dictionary (fr-en)",
                wordcount: 8505,
                synwordcount: 0,
                idxfilesize: 147979,
                idxoffsetbits: 32,
                author: "",
                email: "",
                website: "",
                description: "Publisher:...",
                date: "",
                sametypesequence: "h",
                dicttype: "",
            },
            "French-English FreeDict Dictionary (fr-en)",
        )
        "#);
        let definitions = dict.lookup("sur");
        assert_debug_snapshot!(truncated_definitions(definitions), @r#"
        Ok(
            Some(
                [
                    WordDefinition {
                        word: "sur",
                        segments: [
                            WordDefinitionSegment {
                                types: "h",
                                text: "<div>/<font col...",
                            },
                        ],
                    },
                ],
            ),
        )
        "#);
    }

    #[test]
    fn test_direct_stardict_interface2() {
        let path = get_fra_eng_path();
        let mut dict = no_cache(get_jitendex_path()).unwrap();
        let definitions = dict.lookup("@jitendex-1369180");
        assert_debug_snapshot!(truncated_definitions(definitions), @r#"
        Ok(
            Some(
                [
                    WordDefinition {
                        word: "@jitendex-1369180",
                        segments: [
                            WordDefinitionSegment {
                                types: "h",
                                text: "<link rel='styl...",
                            },
                        ],
                    },
                ],
            ),
        )
        "#);
        let path = get_fra_eng_path();
        let mut dict = with_sled(
            "/Users/chaosarium/Documents/Repos/Influx/dictionaries/jitendex/jitendex.ifo",
            "jitendex-sled-cache",
        )
        .unwrap();
        let definitions = dict.lookup("じんぶんちり");
        assert_debug_snapshot!(truncated_definitions(definitions), @r#"
        Ok(
            Some(
                [
                    WordDefinition {
                        word: "@jitendex-1369180",
                        segments: [
                            WordDefinitionSegment {
                                types: "h",
                                text: "<link rel='styl...",
                            },
                        ],
                    },
                ],
            ),
        )
        "#);
    }

    #[test]
    fn test_add_jitendex_dictionary() {
        let mut manager = StardictManager::new();

        let _ = manager.load_dictionary(get_jitendex_path());
        let definitions = manager.lookup_word(get_jitendex_path(), "じんぶんちり");

        assert_debug_snapshot!(truncated_definitions(definitions), @r#"
        Ok(
            Some(
                [
                    WordDefinition {
                        word: "@jitendex-1369180",
                        segments: [
                            WordDefinitionSegment {
                                types: "h",
                                text: "<link rel='styl...",
                            },
                        ],
                    },
                ],
            ),
        )
        "#);
    }
}
