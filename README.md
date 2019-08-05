# Tenbew DOI API

Exposes an API with functionality to:

* Receive API calls from `Tenbew Gateway`

* Processes SOAP integration logic to `DOI` API

* Handle / return downstream logic back to GATEWAY

* Initialization and instructions for:

  ● Configuration, Database, Development, Deployment, Tests, etc


## Getting Started

### Dependencies

  * Make sure you have `Ruby` installed, following are compatible versions:
    - Ruby >= 2.5.3
    - Rails >= 5.2.3

### Development

  * Clone the project with `git clone git@bitbucket.org:brandonleetruter/tenbew_doi_api.git`
  * Install bundler `gem install bundler` and install gems with `bundle install`
  * Create and migrate database with `bin/rake db:setup`
  * Start Server with `bin/rails s`

  Now we can response to API requests on [`localhost:3000`](http://localhost:3000)

## SETUP

### Project

  * $ rails new tenbew_doi_api --api
  * $ cd tenbew_doi_api
  * $ bundle install
  * $ bin/rake db:setup

### Repo

  * $ git remote add origin git@bitbucket.org:brandonleetruter/tenbew_doi_api.git
  * $ git push -u origin master
  * $ git add --all && git commit -a -m "initial commit, created new rails project with --api flag"

### Testing

  - gem rspec-rails, factory_girl_rails
  * $ bundle
  * $ bin/rails g rspec:install
  * $ rm -rf test
  * $ git add --all && git commit -a -m "added rspec testing framework"

### Database

  * $ bin/rails g scaffold subscription state service msisdn message reference
  * $ bin/rake db:migrate
  * $ bin/rails s
  * $ git add --all && git commit -a -m "added subscription scaffold, includes migration, controllers, model"

### Config

  - initializers: qq.rb, cellc.rb
  - yaml configs: qq.yml, cellc.yml
  - added DOI related logic in controller
  * $ git add --all && git commit -a -m "added qq and cellc configs, updated controller with DOI related logic"

### Serializers

  - gem active_model_serializers
  * $ bundle
  * $ rails g serializer subscription
  - update SubscriptionSerializer file
  * $ git add --all && git commit -a -m "added subscription serializer"

### Versioning

  - create 'api/v1' directory with x2 new controllers:
    - api_controller.rb
    - subscriptions_controller.rb
  - update routes.rb with namespace
  * $ git add --all && git commit -a -m "added versioning, accessed through /api/v1/ namespace"

### Authentication

  * $ rails g migration AddApiKeyToSubscriptions api_key:string doi_key:string
  * $ bin/rake db:migrate
  - update 'subscription.rb' to generate api_key logic
  - update 'api/v1/api_controller.rb' to authorize requests
  * $ git add --all && git commit -a -m "added authentication, authorised by token in header"


## TESTING:

**todo** : update rspec tests

### REST API Endpoints

  - `POST` /subscriptions

    ```bash
    $ curl --request POST \
       --url 'http://localhost:3000/api/v1/subscriptions' \
       --header 'Content-Type: application/json; charset=utf-8' \
       --data $'{ "msisdn": "27124247232", "state": "active", "message": "first subscription", "service": "none", "reference": "test" }'
    ```

    ```
      {
        "id":1,"state":"active","service":"none","msisdn":"27124247232","message":"first subscription","reference":"test"
      }
    ```

  - `GET` /subscriptions

    ```bash
    $ curl --request GET \
         --url 'http://localhost:3000/api/v1/subscriptions' \
         --header 'Content-Type: application/json'
    ```

    ```
      [{"id":1,"state":"active","service":"none","msisdn":"27124247232","message":"first subscription","reference":"test"}]
    ```

  - `GET` /subscriptions/:id

    ```bash
    $ curl --request GET \
         --url 'http://localhost:3000/api/v1/subscriptions/1' \
         --header 'Content-Type: application/json'
    ```

    ```
      {
        "id":1,"state":"active","service":"none","msisdn":"27124247232","message":"first subscription","reference":"test"
      }
    ```   

### Authorization

  - `Fail` (without token)

  ```bash
  $ curl --request GET \
         --url 'http://localhost:3000/api/v1/subscriptions' \
         --header 'Content-Type: application/json'
  ```
  ```
    Bad credentials
  ```

  - `Pass` (with token)

  ```bash
  $ curl -H "Authorization: Token token=PsmmvKBqQDOaWwEsPpOCYMsy" http://localhost:3000/subscriptions
  ```

  ```
  [{"id":1,"state":"active","service":"none","msisdn":"27124247232","message":"first subscription","reference":"test"}]
  ```
