#[derive(thiserror::Error, Debug)]
pub enum APIError {
    #[error("Value not of type '{0}'")]
    XValueNotOfType(&'static str),

    #[error(transparent)]
    Surreal(#[from] surrealdb::Error),

    #[error(transparent)]
    IO(#[from] std::io::Error),

    #[error("Whatever")]
    Whatever,
}
