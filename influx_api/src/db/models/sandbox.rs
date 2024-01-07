use super::{models_prelude::*, lang};
use std::collections::{HashMap, BTreeMap, HashSet};
use crate::prelude::*;
use surrealdb::sql::{Id, Object, Value, Thing, Array};


const FOO_TABLE: &str = "foo_table";
const BAR_TABLE: &str = "bar_table";

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash)]
pub struct FooId {
    pub lang_id: String,
    pub orthography: String,
}

pub fn mk_foo_thing(fooid: FooId) -> Thing {
    let object = Id::Object(Object(
        btreemap!{
            "lang_id".to_string() => Value::from(fooid.lang_id),
            "orthography".to_string() => Value::from(fooid.orthography),
        }
    ));
    Thing::from((FOO_TABLE.to_string(), object))
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash)]
pub struct BarId {
    pub lang_id: String,
    pub orthography_seq: Vec<String>,
}

pub fn mk_bar_thing(barid: BarId) -> Thing {
    let object = Id::Object(Object(
        btreemap!{
            "lang_id".to_string() => Value::from(barid.lang_id),
            "orthography_seq".to_string() => Value::from(barid.orthography_seq),
        }
    ));
    Thing::from((FOO_TABLE.to_string(), object))
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash)]
pub struct Foo {
    pub id: Thing,
    pub note: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash)]
pub struct Bar {
    pub id: Thing,
    pub note: String,
}

impl Foo {
    pub fn essential_foo(lang_id: &str, orthography: &str) -> Foo {
        Foo {
            id: mk_foo_thing(FooId{orthography: orthography.to_string(), lang_id: lang_id.to_string()}),
            note: "".to_string(),
        }
    }

    pub fn fancier_foo(lang_id: &str, orthography: &str, notes: &str) -> Foo {
        Foo {
            id: mk_foo_thing(FooId{orthography: orthography.to_string(), lang_id: lang_id.to_string()}),
            note: notes.to_string(),
        }
    }
}

impl Bar {
    pub fn essential_bar(lang_id: &str, orthography_seq: Vec<&str>) -> Bar {
        Bar {
            id: mk_bar_thing(BarId{orthography_seq: orthography_seq.iter().map(|s| s.to_string()).collect(), lang_id: lang_id.to_string()}),
            note: "".to_string(),
        }
    }

    pub fn fancier_bar(lang_id: &str, orthography_seq: Vec<&str>, notes: &str) -> Bar {
        Bar {
            id: mk_bar_thing(BarId{orthography_seq: orthography_seq.iter().map(|s| s.to_string()).collect(), lang_id: lang_id.to_string()}),
            note: notes.to_string(),
        }
    }
}

impl DB {
    pub async fn create_foo(&self, foo: Foo) -> Result<Foo> {

        let sql = format!("CREATE {FOO_TABLE} CONTENT $foo");
        let mut res: Response = self.db
            .query(sql)
            .bind(("foo", foo))
            .await?;

        dbg!(&res);
        match res.take(0) {
            Ok(Some::<Foo>(v)) => Ok(v),
            Ok(None) => Err(anyhow::anyhow!("sql didn't fail but no foo was returned")),
            Err(e) => Err(anyhow::anyhow!("Error creating foo: {:?}", e)),
        }
    }

    pub async fn query_foo_by_id(&self, id: FooId) -> Result<Option<Foo>> {
        let res = self.db.select(mk_foo_thing(id)).await;

        dbg!(&res);
        match res {
            Ok(Some::<Foo>(v)) => Ok(Some(v)),
            Ok(None) => Ok(None),
            Err(e) => Err(anyhow::anyhow!("Error querying foo: {:?}", e)),
        }
    }

    pub async fn create_bar(&self, bar: Bar) -> Result<Bar> {
        let sql = format!("CREATE {BAR_TABLE} CONTENT $bar");
        let mut res: Response = self.db
            .query(sql)
            .bind(("bar", bar))
            .await?;

        dbg!(&res);
        match res.take(0) {
            Ok(Some::<Bar>(v)) => Ok(v),
            Ok(None) => Err(anyhow::anyhow!("sql didn't fail but no bar was returned")),
            Err(e) => Err(anyhow::anyhow!("Error creating bar: {:?}", e)),
        }
    }

    pub async fn query_bar_by_id(&self, id: BarId) -> Result<Option<Bar>> {
        let res = self.db.select(mk_bar_thing(id)).await;

        dbg!(&res);
        match res {
            Ok(Some::<Bar>(v)) => Ok(Some(v)),
            Ok(None) => Ok(None),
            Err(e) => Err(anyhow::anyhow!("Error querying bar: {:?}", e)),
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::db::DBLocation;

    use super::*;

    #[tokio::test]
    async fn test_create_foo() {
        let db = DB::create_db(DBLocation::Mem).await;
        let foo = Foo::essential_foo("langs:en_demo", "test");
        let foo = db.create_foo(foo).await.unwrap();
        println!("{:?}", foo);
    }

    #[tokio::test]
    async fn test_query_foo_by_id() {
        let db = DB::create_db(DBLocation::Mem).await;
        let tkn: Foo = db.create_foo(Foo::fancier_foo("langs:en_demo", "test", "testnote")).await.unwrap();
        let res = db.query_foo_by_id(FooId{orthography: "test".to_string(), lang_id: "langs:en_demo".to_string()}).await;
        assert!(res.is_ok());
        let foo = res.unwrap().unwrap();
        dbg!(&foo);
    }

    #[tokio::test]
    async fn test_create_bar() {
        let db = DB::create_db(DBLocation::Mem).await;
        let bar = Bar::essential_bar("langs:en_demo", vec!["test", "test2"]);
        let bar = db.create_bar(bar).await.unwrap();
        println!("{:?}", bar);
    }

    #[tokio::test]
    async fn test_query_bar_by_id() {
        let db = DB::create_db(DBLocation::Mem).await;
        let tkn: Bar = db.create_bar(Bar::fancier_bar("langs:en_demo", vec!["test", "test2"], "testnote")).await.unwrap();
        let res = db.query_bar_by_id(BarId{orthography_seq: vec!["test".to_string(), "test2".to_string()], lang_id: "langs:en_demo".to_string()}).await;
        assert!(res.is_ok());
        let bar = res.unwrap().unwrap();
        dbg!(&bar);
    }
}