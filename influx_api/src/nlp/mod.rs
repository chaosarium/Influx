#![allow(unused_imports, unused_must_use)]
// use anyhow::Ok;
use anyhow;
use pyo3::prelude::*;
use pyo3::types::{IntoPyDict, PyTuple};

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

fn run_some_python_binding() -> PyResult<()> {
    let code = vec![
        "import stanza",
        "nlp = stanza.Pipeline(lang='fr', processors='tokenize, lemma')",
        "doc = nlp('Le chat mange la souris.')",
        "print(doc, flush=True)",
    ].join("\n");
    
    let arg1 = "arg1";
    let arg2 = "arg2";
    let arg3 = "arg3";

    Python::with_gil(|py| {
        let builtins = PyModule::import(py, "builtins")?;

        let total: i32 = builtins
            .getattr("sum")?
            .call1((vec![1, 2, 3],))?
            .extract()?;
        assert_eq!(total, 6);

        let stanza = PyModule::import(py, "stanza")?;

        let fun: Py<PyAny> = PyModule::from_code(
            py,
            "def example(*args, **kwargs):
                import stanza
                nlp = stanza.Pipeline(lang='fr', processors='tokenize, lemma')
                doc = nlp('Le chat mange la souris.')
                print(doc, flush=True)
                if args != ():
                    print('called with args', args)
                if kwargs != {}:
                    print('called with kwargs', kwargs)
                if args == () and kwargs == {}:
                    print('called with no arguments')",
            "",
            "",
        )?.getattr("example")?.into();

        print!("===");
        dbg!(&fun);

        // call object without any arguments
        dbg!(fun.call0(py));

        // call object with PyTuple
        let args = PyTuple::new(py, &[arg1, arg2, arg3]);
        fun.call1(py, args)?;

        // pass arguments as rust tuple
        let args = (arg1, arg2, arg3);
        fun.call1(py, args)?;
        Ok(())
    })
}

fn try_importing() -> PyResult<()> {
    Python::with_gil(|py| {
        let sys = py.import("sys")?;
        println!(">>> imported sys");
        dbg!(py.import("stanza"));
        let stanza = py.import("stanza")?;
        println!(">>> imported stanza");
        let locals = [("stanza", stanza), ("sys", sys)].into_py_dict(py);
        let code = "print(sys.version)\n";
        println!("Running Python code:\n{}", code);
        dbg!(py.eval(code, None, None));
        Ok(())
    })

}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_run_some_python() {
        assert!(run_some_python().is_ok());
    }

    #[test]
    fn test_try_importing() {
        assert!(try_importing().is_ok());
    }

    #[test]
    fn test_run_some_python_binding() {
        assert!(run_some_python_binding().is_ok());
    }
}
