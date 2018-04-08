// A useless example application using `git2`, to make sure that we link it
// correctly.

extern crate git2;

use git2::Repository;

fn main() {
    let _ = Repository::init("test-repo");
    println!("Hello, world!");
}
