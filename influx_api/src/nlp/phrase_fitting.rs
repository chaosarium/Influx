///! phrase fitting optimisation algorithms
use crate::utils::trie::Trie;
use std::{hash::Hash, vec};

pub fn greedy_fit<T: Eq + Hash + Copy>(seq: Vec<T>, trie: &Trie<T>) -> Vec<Vec<T>> {
    let positional_prefixes = (0..seq.len())
        .map(|i| {
            let suffix = &seq[i..];
            let mut prefixes = trie.search_prefixes_by_ref(suffix);
            if prefixes.len() == 0 {
                prefixes.push(vec![seq[i]]);
            }
            let longest_prefix = prefixes.last().unwrap().clone();
            longest_prefix
        })
        .collect::<Vec<_>>();

    let mut segments = vec![];

    let mut i: usize = 0;
    while i < seq.len() {
        let prefix = &positional_prefixes[i];
        let prefix_len = prefix.len();
        segments.push(prefix.clone());
        i += prefix_len;
    }

    segments
}

/// recursive implementation of best fit, but NOT efficient
pub fn recursion_best_fit<T: Eq + Hash + Copy>(seq: Vec<T>, trie: &Trie<T>) -> (Vec<Vec<T>>, usize) {
    if seq.len() == 0 {
        return (vec![], 0);
    }

    let mut prefixes = trie.search_prefixes_by_ref(&seq);
    if prefixes.len() == 0 {
        prefixes.push(vec![seq[0]]);
    }
    let max_fitting = prefixes.iter().map(|prefix: &Vec<T>| {
            let prefix_len = prefix.len();
            let suffix = seq[prefix_len..].to_vec();
            let (sub_segments, sub_score) = recursion_best_fit(suffix, trie);
            let mut segments = vec![prefix.clone()];
            segments.extend(sub_segments);
            (segments, sub_score + 1)
        })
        .max_by_key(|(_, score)| *score);

    match max_fitting {
        Some((segments, score)) => (segments, score),
        None => (vec![], 0),
    }
}


#[cfg(test)]
mod test {
    #[test] 
    fn test_greedy_fit1() {
        use super::greedy_fit;
        use crate::utils::trie::Trie;
        let trie = Trie::new_with_entries(vec![
            vec![1, 2, 3], 
            vec![1, 2, 3, 4], 
            vec![1, 2, 3, 4, 5],
            vec![6, 7],
            vec![7, 8, 9],
        ]);
        let seq = vec![1, 2, 3, 4, 5, 6, 7, 8, 9];
        let res = greedy_fit(seq, &trie);
        assert_eq!(res, vec![vec![1, 2, 3, 4, 5], vec![6, 7], vec![8], vec![9]]);
    }

    #[test]
    fn test_recursion_best_fit1() {
        use super::greedy_fit;
        use crate::utils::trie::Trie;
        let trie = Trie::new_with_entries(vec![
            vec![1, 2, 3], 
            vec![1, 2, 3, 4], 
            vec![1, 2, 3, 4, 5],
            vec![6, 7],
            vec![7, 8, 9],
        ]);
        let seq = vec![1, 2, 3, 4, 5, 6, 7, 8, 9];
        let res = greedy_fit(seq, &trie);
        println!("{:?}", res);
    }

}