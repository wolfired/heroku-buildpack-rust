#!/usr/bin/env bash

# This is a script for auto create a heroku app which use rust lang, and use this buildpack.

APP_NAME=${1:?you need pass a app name}

if [[ -d "./$APP_NAME" ]]; then
    echo Dir \"$APP_NAME\" is already existed
    exit 1
fi

heroku apps:create $APP_NAME --buildpack https://github.com/wolfired/heroku-buildpack-rust#develop
if [[ 0 -ne $? ]]; then
    exit 1
fi

heroku config:set PORT=80 -a $APP_NAME
heroku git:clone -a $APP_NAME

cd $APP_NAME

cargo init --vcs none

cat <<EOF > ./src/main.rs
#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use]
extern crate rocket;

#[get("/")]
fn index() -> &'static str {
    "Hello, world!"
}

fn main() {
    // use rocket::ignite() because we need to override the parameters by env var
    rocket::ignite().mount("/", routes![index]).launch();
}
EOF

cat <<EOF > ./.gitignore
/target
EOF

cat <<EOF > ./Cargo.toml
[package]
name = "$APP_NAME"
version = "0.1.0"
authors = ["YourName <your@email.com>"]
edition = "2018"

# See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

[dependencies]
rocket = "0.4.4"
EOF

cat <<EOF > ./Procfile
web: ROCKET_ENV=stage ROCKET_LOG=off ROCKET_PORT=\$PORT ./bin/$APP_NAME
EOF

git add .
git commit -m "Init commit"
git push heroku
