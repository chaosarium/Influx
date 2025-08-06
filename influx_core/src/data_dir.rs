use anyhow::Result;
use std::path::PathBuf;
use tracing::info;

pub fn get_data_dir() -> Result<PathBuf> {
    let data_dir = dirs::data_dir()
        .ok_or_else(|| anyhow::anyhow!("Could not determine data directory"))?
        .join("Influx");
    Ok(data_dir)
}

pub fn get_dictionaries_dir() -> Result<PathBuf> {
    Ok(get_data_dir()?.join("dictionaries").join("stardicts"))
}

pub fn init_data_directories() -> Result<()> {
    let data_dir = get_data_dir()?;
    let dictionaries_dir = get_dictionaries_dir()?;

    info!("Influx data directory: {}", data_dir.display());

    std::fs::create_dir_all(&data_dir)?;
    std::fs::create_dir_all(&dictionaries_dir)?;

    info!("Created data directories: {}", data_dir.display());
    info!("Dictionaries directory: {}", dictionaries_dir.display());

    Ok(())
}

pub fn resolve_dict_path(relative_path: &str) -> Result<PathBuf> {
    let dictionaries_dir = get_dictionaries_dir()?;
    Ok(dictionaries_dir.join(relative_path))
}
