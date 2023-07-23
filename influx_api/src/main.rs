use clap::Parser;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Whether to run db on disk
    #[arg(short, long, default_value_t = false)]
    disk: bool,

    /// Whether to not seed database
    #[arg(short, long, default_value_t = false)]
    no_seed: bool,
}

#[tokio::main]
async fn main() {
    let args = Args::parse();

    influx_api::launch(args.disk, !args.no_seed).await
}
