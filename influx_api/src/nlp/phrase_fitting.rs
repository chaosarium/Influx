///! phrase fitting optimisation algorithms
use crate::utils::trie::Trie;
use std::{hash::Hash, vec};

/// not the most efficient but it works as a baseline
pub fn greedy_fit<T: Eq + Hash + Clone, S>(seq: Vec<T>, trie: &Trie<T, S>) -> (Vec<Vec<T>>, Vec<(usize, usize)>) {
    let positional_prefixes = (0..seq.len())
        .map(|i| {
            let suffix = &seq[i..];
            let prefixes = trie.search_prefixes_by_ref(suffix, true);
            let longest_prefix = prefixes.last().unwrap().clone();
            longest_prefix
        })
        .collect::<Vec<_>>();

    let mut segments = vec![];
    let mut segment_locs = vec![];

    let mut i: usize = 0;
    while i < seq.len() {
        let prefix = &positional_prefixes[i];
        let prefix_len = prefix.len();
        segments.push(prefix.clone());
        segment_locs.push((i, i+prefix_len));
        i += prefix_len;
    }

    (segments, segment_locs)
}


/// recursive implementation of best fit, but NOT efficient
pub fn recursion_best_fit_prime<T: Eq + Hash + Clone, S>(seq: Vec<T>, trie: &Trie<T, S>) -> ((Vec<Vec<T>>, Vec<(usize, usize)>), usize) {
    if seq.len() == 0 {
        return ((vec![], vec![]), 0);
    }

    let prefixes = trie.search_prefixes_by_ref(&seq, true);
    let max_fitting = prefixes.iter().map(|prefix: &Vec<T>| {
            let prefix_len = prefix.len();
            let suffix = seq[prefix_len..].to_vec();
            let ((sub_segments, sub_slices), sub_cost) = recursion_best_fit_prime(suffix, trie);
            let mut segments = vec![prefix.clone()];
            segments.extend(sub_segments);
            let mut slices = vec![(0, prefix_len)];
            slices.extend(sub_slices.iter().map(|(start, end)| (start + prefix_len, end + prefix_len)));
            ((segments, slices), sub_cost + 1)
        })
        .min_by_key(|(_, cost)| *cost);

    match max_fitting {
        Some(((segments, slices), cost)) => ((segments, slices), cost),
        None => ((vec![], vec![]), 0),
    }
}

pub fn recursion_best_fit<T: Eq + Hash + Clone, S>(seq: Vec<T>, trie: &Trie<T, S>) -> (Vec<Vec<T>>, Vec<(usize, usize)>) {
    let (res, _) = recursion_best_fit_prime(seq, trie);
    res
}

/// dynamic programming implementation of best fit, returning only the start and end indices of the segments
pub fn dp_best_fit<T: Eq + Hash + Clone, S>(seq: Vec<T>, trie: &Trie<T, S>) -> Vec<(usize, usize)> {
    let mut memo: Vec<(Vec<(usize, usize)>, usize)> = vec![(vec![], 0); seq.len() + 1];
    memo[0] = (vec![], 0);

    for suffix_len in 1..=seq.len() {
        let suffix = &seq[seq.len() - suffix_len..];
        let sub_prefixes = trie.search_prefixes_by_ref(suffix, true);

        let best_sub_prefix_sol = sub_prefixes
            .iter()
            .map(|prefix| {
                let prefix_len = prefix.len();
                let sub_suffix_len = suffix_len - prefix_len;
                let (sub_suffix_slices, sub_suffix_cost) = &memo[sub_suffix_len];
                let suffix_cost = sub_suffix_cost + 1;
                let mut suffix_slices = vec![(0, prefix_len)];
                suffix_slices.extend(
                    sub_suffix_slices
                        .iter()
                        .map(|(start, end)| (start + prefix_len, end + prefix_len))
                );
                (suffix_slices, suffix_cost)
            })
        .min_by_key(|(suffix_slices, suffix_cost)| *suffix_cost).unwrap();

        memo[suffix_len] = best_sub_prefix_sol.clone();
    }

    let (slices, _) = &memo[seq.len()];
    slices.clone()
}


#[cfg(test)]
mod test {
    #[test] 
    fn test_greedy_fit1() {
        use super::greedy_fit;
        use crate::utils::trie::Trie;
        let trie: Trie<i32, ()> = Trie::new_with_entries(vec![
            vec![1, 2, 3], 
            vec![1, 2, 3, 4], 
            vec![1, 2, 3, 4, 5],
            vec![6, 7],
            vec![7, 8, 9],
        ]);
        let seq = vec![1, 2, 3, 4, 5, 6, 7, 8, 9];
        let (segments, segment_locs) = greedy_fit(seq, &trie);
        println!("{:?}", &segments);
        assert_eq!(segments, vec![vec![1, 2, 3, 4, 5], vec![6, 7], vec![8], vec![9]]);
        assert_eq!(segment_locs, vec![(0, 5), (5, 7), (7, 8), (8, 9)]);
    }

    #[test]
    fn test_recursion_best_fit1() {
        use super::recursion_best_fit;
        use crate::utils::trie::Trie;
        let trie: Trie<i32, ()> = Trie::new_with_entries(vec![
            vec![1, 2, 3], 
            vec![1, 2, 3, 4], 
            vec![1, 2, 3, 4, 5],
            vec![6, 7],
            vec![7, 8, 9],
        ]);
        let seq = vec![1, 2, 3, 4, 5, 6, 7, 8, 9];
        let (segments, segment_locs) = recursion_best_fit(seq, &trie);
        println!("{:?}", &segments);
        assert_eq!(segments, vec![vec![1, 2, 3, 4, 5], vec![6], vec![7, 8, 9]]);
        assert_eq!(segment_locs, vec![(0, 5), (5, 6), (6, 9)]);
    }

    #[test]
    fn test_dp_best_fit1() {
        use super::dp_best_fit;
        use crate::utils::trie::Trie;
        let trie: Trie<i32, ()> = Trie::new_with_entries(vec![
            vec![1, 2, 3], 
            vec![1, 2, 3, 4], 
            vec![1, 2, 3, 4, 5],
            vec![6, 7],
            vec![7, 8, 9],
        ]);
        let seq = vec![1, 2, 3, 4, 5, 6, 7, 8, 9];
        let segments = dp_best_fit(seq, &trie);
        println!("{:?}", &segments);
        assert_eq!(segments, vec![(0, 5), (5, 6), (6, 9)]);
    }

}