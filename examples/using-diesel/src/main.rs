#[macro_use]
extern crate diesel;
#[macro_use]
extern crate diesel_codegen;
extern crate openssl_sys;

use std::env;

use diesel::pg::PgConnection;
use diesel::prelude::*;
use diesel::sqlite::SqliteConnection;

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

fn main() {
    println!("Hello, world!");

    // Only run our database example if we have a database. Otherwise, we just
    // want to make sure everything links correctly.
    if let Ok(url) = env::var("DATABASE_URL") {
        let conn = PgConnection::establish(&url)
            .expect("could not connect to site");
        let rows = users::table
            .limit(5)
            .load::<User>(&conn)
            .expect("could not load users");
        for row in rows {
            println!("{:?}", row);
        }
    } else {
        println!("No DATABASE_URL set, so doing nothing")
    }

    // Test that we can establish a SQLite connection.
    SqliteConnection::establish(":memory:").expect("could not connect to in-memory database");
}
