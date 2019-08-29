# Tenbew DOI API

Exposes an API with functionality to:

* Receive API calls from `Tenbew Gateway` app

* Processes SOAP integration logic to `DOI` API

* Handle / return downstream logic back to GATEWAY


## Dependencies

  * Make sure you have `Ruby` installed, following are compatible versions:
    - Ruby >= 2.5.3
    - Rails >= 5.2.3

## Getting Started

  * Clone the project with `git clone git@bitbucket.org:brandonleetruter/tenbew_doi_api.git`
  * Install bundler `gem install bundler`, move to app `cd tenbew_doi_api` and install gems `bundle install`
  * Create and migrate database with `bin/rake db:setup`
  * Start Server with `bin/rails s`

  Now we can response to API requests on [`localhost:3000`](http://localhost:3000)

## API Usage

**POST** /subscriptions

```bash
$ curl --request POST \
   --url 'http://localhost:3000/api/v1/subscriptions' \
   --header 'Content-Type: application/json; charset=utf-8' \
   --data $'{ "msisdn": "27124247232", "state": "active", "message": "first subscription", "service": "none", "reference": "test" }'
```
Response:
```
  {
    "id":1,"state":"active","service":"none","msisdn":"27124247232","message":"first subscription","reference":"test"
  }
```

**GET** /subscriptions

```bash
$ curl --request GET \
     --url 'http://localhost:3000/api/v1/subscriptions' \
     --header 'Content-Type: application/json'
```
Response:
```
  [{"id":1,"state":"active","service":"none","msisdn":"27124247232","message":"first subscription","reference":"test"}]
```

**GET** /subscriptions/:id

```bash
$ curl --request GET \
     --url 'http://localhost:3000/api/v1/subscriptions/1' \
     --header 'Content-Type: application/json'
```
Response:
```
  {
    "id":1,"state":"active","service":"none","msisdn":"27124247232","message":"first subscription","reference":"test"
  }
```   
