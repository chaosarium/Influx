#![allow(unused_imports, unused_must_use)]
use std::collections::HashMap;

// use anyhow::Ok;
use anyhow;
use pyo3::prelude::*;
use pyo3::types::{IntoPyDict, PyTuple};
use std::env;
use std::path::PathBuf;
use indoc::indoc;

// from https://pyo3.rs/v0.20.0/
fn run_some_python() -> PyResult<()> {
    Python::with_gil(|py| {
        let sys = py.import("sys")?;
        let version: String = sys.getattr("version")?.extract()?;

        let locals = [("os", py.import("os")?)].into_py_dict(py);
        let code = "os.getenv('USER') or os.getenv('USERNAME') or 'Unknown'";
        let user: String = py.eval(code, None, Some(&locals))?.extract()?;

        py.eval("help('modules')", None, None)?;

        println!("Hello {}, I'm Python {}", user, version);
        Ok(())
    })
}

#[derive(FromPyObject, Debug)]
enum RustyEnum {
    #[pyo3(transparent, annotation = "str")]
    String(String),
    #[pyo3(transparent, annotation = "int")]
    Int(isize),
    #[pyo3(transparent, annotation = "tuple")]
    IntTuple((isize, isize)),
}

type TokenisedText = Vec<Vec<Vec<HashMap<String, RustyEnum>>>>;

fn tokenise_pipeline(text: &str, language: String) -> PyResult<()> {

    let current_dir = env::current_dir()?;
    let pylib_path = current_dir.join("./src/nlp/pylib").canonicalize()?;

    Python::with_gil(|py| {
        let stanza = PyModule::import(py, "stanza")?;

        let pylib_path_str = pylib_path.to_str().unwrap();
        let code = indoc!(
            r#"
            import sys, os
            sys.path.insert(0, os.path.abspath("{path}"))
            from stanza_integration import fun
            "#
        );
        let code = code.replace("{path}", pylib_path_str);

        let fun: Py<PyAny> = PyModule::from_code(
            py, &code, "", "",
        )?.getattr("fun")?.into();

        let callret = fun
            .call1(py, (text, language))?
            .extract::<Vec<Vec<Vec<HashMap<String, RustyEnum>>>>>(py);

        dbg!(callret);

        Ok(())
    })
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tokenise_pipeline() {
        const TEXT: &str = indoc! {
            r#"
            Out, out, brief candle!
            Life's but a walking shadow, a poor player,
            That struts and frets his hour upon the stage,
            And then is heard no more. It is a tale
            Told by an idiot, full of sound and fury,
            Signifying nothing.
            "#
        };
        
        let res = tokenise_pipeline(TEXT, "en".to_string());
        dbg!(&res);
        assert!(res.is_ok());
    }


    #[test]
    fn test_run_some_python() {
        assert!(run_some_python().is_ok());
    }

}
