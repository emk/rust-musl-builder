use std::env;

use sqlx::{Connection, postgres::PgConnection};

#[tokio::main]
async fn main() -> Result<(), sqlx::Error> {
    openssl_probe::init_ssl_cert_env_vars();

    let url = env::var("POSTGRES_URL")
        .unwrap_or_else(|_| "postgresql://postgres@localhost/postgres".to_owned());

    // Create a connection.
    let mut conn = PgConnection::connect(&url).await?;

    // Make a simple query using the `query!` macro.
    let row = sqlx::query!("SELECT $1::INTEGER AS value", 2i32)
        .fetch_one(&mut conn)
        .await?;

    assert_eq!(row.value, Some(2));

    Ok(())
}
