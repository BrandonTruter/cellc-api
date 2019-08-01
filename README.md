# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...


# REPO
  git clone git@bitbucket.org:brandonleetruter/tenbew_doi_api.git



- setup project

rails new tenbew_doi_api --api
cd tenbew_doi_api
bundle install
bin/rake db:setup

- setup repo

git remote add origin git@bitbucket.org:brandonleetruter/tenbew_doi_api.git
git push -u origin master
git add --all && git commit -a -m "initial commit, created new rails project with --api flag"

- setup testing

bundle
bin/rails g rspec:install
rm -rf test
git add --all && git commit -a -m "added rspec testing framework"

- setup database

bin/rails g scaffold subscription state service msisdn message reference
bin/rake db:migrate
bin/rails s
git add --all && git commit -a -m "added subscription scaffold, includes migration, controllers, model"
# http://localhost:3000

-


#



-
