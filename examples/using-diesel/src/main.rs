#[macro_use]
extern crate diesel;
extern crate openssl;

use diesel::connection::Connection;
use diesel::pg::PgConnection;
use diesel::prelude::*;
use diesel::sqlite::SqliteConnection;
use diesel::sql_types::{HasSqlType, Integer, Text};
use std::env;

table! {
    users (id) {
        id -> Integer,
        name -> Text,
    }
}

#[derive(Debug, Insertable, Queryable)]
#[table_name="users"]
struct User {
    id: i32,
    name: String,
}

/// Run a query against our `users` table.
fn query_users<C>(conn: &C)
where
    // OK, we made the mistake of trying to write generic `diesel` code that
    // works for multiple types of databases. This requires some pretty
    // hairy declarations.
    C: Connection,
    User: Queryable<(Integer, Text), C::Backend>,
    C::Backend: HasSqlType<Integer> + HasSqlType<Text>,
{
    let rows = users::table
        .limit(5)
        .load::<User>(conn)
        .expect("could not load users");
    for row in rows {
        println!("{:?}", row);
    }
}

fn main() {
    println!("Hello, world!");

    // Only run our database example if we have a database. Otherwise, we just
    // want to make sure everything links correctly.
    if let Ok(url) = env::var("DATABASE_URL") {
        if url.starts_with("postgres:") {
            let conn = PgConnection::establish(&url)
                .expect("could not connect to database");
            query_users(&conn);
        } else if url.starts_with("sqlite:") {
            let conn = SqliteConnection::establish(&url)
                .expect("could not connect to database");
            query_users(&conn);
        } else {
            println!("Unsupported database URL: {}", url);
        }
    } else {
        println!("No DATABASE_URL set, so doing nothing")
    }
}
