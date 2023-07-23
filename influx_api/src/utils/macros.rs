// example usage
// map![
//     "title".into() => val.title.into(),
//     "completed".into() => val.completed.into()
// ]
#[macro_export]
macro_rules! map {
    ($($k:expr => $v:expr),* $(,)?) => {{
        let mut m = ::std::collections::BTreeMap::new();
            $(m.insert($k, $v);)+
            m
    }};
}

// pub(crate) use map;
