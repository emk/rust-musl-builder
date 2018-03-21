extern crate git2;

use git2::Repository;

fn main() {
  let _local = Repository::init("fkbr");
  println!("Hello, world!");
}
