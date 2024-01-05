use std::collections::HashMap;
use std::hash::Hash;

#[derive(Default, Debug)]
pub struct Trie<T: Eq + Hash + Clone> {
    children: HashMap<T, Trie<T>>,
    is_terminal: bool,
}

impl<T: Eq + Hash + Clone> Trie<T> {
    pub fn new() -> Self {
        Trie {
            children: HashMap::new(),
            is_terminal: false,
        }
    }

    pub fn insert<I>(&mut self, seq: I) where I: IntoIterator<Item = T>,
    {
        let mut curr = self;
        for x in seq {
            curr = curr.children.entry(x).or_insert(Trie::new());
        }
        curr.is_terminal = true;
    }

    pub fn search<I>(&self, seq: I) -> bool where I: IntoIterator<Item = T>,
    {
        let mut curr = self;
        for x in seq {
            match curr.children.get(&x) {
                Some(child) => curr = child,
                None => return false,
            }
        }
        curr.is_terminal
    }

    pub fn search_prefixes<I>(&self, seq: I) -> Vec<Vec<T>> where I: IntoIterator<Item = T>,
    {
        let mut prefixes = vec![];
        let mut curr = self;
        let mut prefix = vec![];
        for x in seq {
            match curr.children.get(&x) {
                Some(child) => {
                    curr = child;
                    prefix.push(x);
                    if curr.is_terminal {
                        prefixes.push(prefix.clone());
                    }
                },
                None => return prefixes,
            }
        }
        prefixes
    }
    
    /// given a vector, return all prefixes of the vector that are in the trie
    /// ensures result is sorted by ascending length
    pub fn search_prefixes_by_ref<'a, I>(&'a self, seq: I) -> Vec<Vec<T>> 
    where 
        I: IntoIterator<Item = &'a T>,
        T: 'a,
        T: Copy,
    {
        let mut prefixes = vec![];
        let mut curr = self;
        let mut prefix = vec![];
        for x in seq {
            match curr.children.get(x) {
                Some(child) => {
                    curr = child;
                    prefix.push(*x);
                    if curr.is_terminal {
                        prefixes.push(prefix.clone());
                    }
                },
                None => return prefixes,
            }
        }
        prefixes
    }
    
    pub fn new_with_entries(entries: Vec<Vec<T>>) -> Self {
        let mut trie = Trie::new();
        for x in entries {
            trie.insert(x);
        }
        trie
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_trie_basic() {
        let mut trie = super::Trie::new();
        trie.insert(vec!["hello", "world"]);
        trie.insert(vec!["world", "wide", "web"]);

        assert!(trie.search(vec!["hello", "world"]));
        assert!(trie.search(vec!["world", "wide", "web"]));
        assert!(!trie.search(vec!["hello", "world", "wide", "web"]));
        assert!(!trie.search(vec!["hello", "world", "wide", "web", "design"]));
    }

    #[test]
    fn test_search_prefixes() {
        let mut trie = super::Trie::new();
        trie.insert(vec![1, 2, 3, 4]);
        trie.insert(vec![1, 2]);
        trie.insert(vec![2, 4]);
        
        assert_eq!(trie.search_prefixes(vec![1, 2, 3, 4]), vec![vec![1, 2], vec![1, 2, 3, 4]]);
        assert_eq!(trie.search_prefixes(vec![1, 2, 3, 4, 5]), vec![vec![1, 2], vec![1, 2, 3, 4]]);
        assert_eq!(trie.search_prefixes(vec![2, 4]), vec![vec![2, 4]]);
        assert_eq!(trie.search_prefixes(vec![2, 4, 5]), vec![vec![2, 4]]);
        assert_eq!(trie.search_prefixes(vec![1, 2, 3]), vec![vec![1, 2]]);
        assert_eq!(trie.search_prefixes(vec![3, 4]).is_empty(), true);

        assert_eq!(trie.search_prefixes_by_ref(&vec![1, 2, 3, 4]), vec![vec![1, 2], vec![1, 2, 3, 4]]);
    }
}