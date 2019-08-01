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
  - git clone git@bitbucket.org:brandonleetruter/tenbew_doi_api.git

# SERVER
  $ bin/rails s
  - http://localhost:3000


# STEPS:

## setup project

  $ rails new tenbew_doi_api --api
  $ cd tenbew_doi_api
  $ bundle install
  $ bin/rake db:setup

## setup repo

  $ git remote add origin git@bitbucket.org:brandonleetruter/tenbew_doi_api.git
  $ git push -u origin master
  $ git add --all && git commit -a -m "initial commit, created new rails project with --api flag"

## setup testing

  - gem rspec-rails, factory_girl_rails
  $ bundle
  $ bin/rails g rspec:install
  $ rm -rf test
  $ git add --all && git commit -a -m "added rspec testing framework"

## setup database

  $ bin/rails g scaffold subscription state service msisdn message reference
  $ bin/rake db:migrate
  $ bin/rails s
  $ git add --all && git commit -a -m "added subscription scaffold, includes migration, controllers, model"

## setup DOI config

  - initializers: qq.rb, cellc.rb
  - yaml configs: qq.yml, cellc.yml
  - added DOI related logic in controller
  $ git add --all && git commit -a -m "added qq and cellc configs, updated controller with DOI related logic"

## setup serializers

  - gem active_model_serializers
  $ bundle
  $ rails g serializer subscription
  - update SubscriptionSerializer file
  $ git add --all && git commit -a -m "added subscription serializer"

## setup versioning

  - create 'api/v1' directory with x2 new controllers:
    -> api_controller.rb
    -> subscriptions_controller.rb
  - update routes.rb with namespace
  $ git add --all && git commit -a -m "added versioning, accessed through /api/v1/ namespace"


## setup authenticating

  $ rails g migration AddApiKeyToUsers api_key:string

  -
    ->
  -
  $




## setup cors

  - gem 'rack-cors'
  $ bundle
  - config/application.rb:

  module YourApp
    class Application < Rails::Application

      # ...

      config.middleware.insert_before 0, "Rack::Cors" do
        allow do
          origins '*'
          resource '*', :headers => :any, :methods => [:get, :post, :options]
        end
      end

    end
  end

  https://github.com/cyu/rack-cors


## setup security

  $ 
  -
    ->
  -
  $


Make API safe from brute force attacks

gem 'rack-attack'

bundle

Update 'config/application.rb':

  module YourApp
    class Application < Rails::Application

      # ...

      config.middleware.use Rack::Attack

    end
  end

Create 'config/initializers/rack_attack.rb':

  class Rack::Attack

    # `Rack::Attack` is configured to use the `Rails.cache` value by default,
    # but you can override that by setting the `Rack::Attack.cache.store` value
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    # Allow all local traffic
    whitelist('allow-localhost') do |req|
      '127.0.0.1' == req.ip || '::1' == req.ip
    end

    # Allow an IP address to make 5 requests every 5 seconds
    throttle('req/ip', limit: 5, period: 5) do |req|
      req.ip
    end

    # Send the following response to throttled clients
    self.throttled_response = ->(env) {
      retry_after = (env['rack.attack.match_data'] || {})[:period]
      [
        429,
        {'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s},
        [{error: "Throttle limit reached. Retry later."}.to_json]
      ]
    }
  end

# Test Endpoints

  - POST /subscriptions
    $ curl --request POST \
       --url 'http://localhost:3000/api/v1/subscriptions' \
       --header 'Content-Type: application/json; charset=utf-8' \
       --data $'{ "msisdn": "27124247232", "state": "active", "message": "first subscription", "service": "none", "reference": "test" }'

       {"id":1,"state":"active","service":"none","msisdn":"27124247232","message":"first subscription","reference":"test"}

  - GET /subscriptions
    $ curl --request GET \
         --url 'http://localhost:3000/api/v1/subscriptions' \
         --header 'Content-Type: application/json'

         [{"id":1,"state":"active","service":"none","msisdn":"27124247232","message":"first subscription","reference":"test"}]

  - GET /subscriptions/:id
    $ curl --request GET \
         --url 'http://localhost:3000/api/v1/subscriptions/1' \
         --header 'Content-Type: application/json'

         {"id":1,"state":"active","service":"none","msisdn":"27124247232","message":"first subscription","reference":"test"}




TODO

- routing
- response (to gw)
- request (to doi)
