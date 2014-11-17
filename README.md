Rest Wrapper
-------------

HTTP/REST client wrapper that provides a standard interface for making http requests using different http
clients. If no client is specified **it will choose the best http client** you have installed based on
our performance tests.

Features
========

* All clients behave exactly the same:
  * Same error behavior
  * Same 30X redirect behavior
  * Same response object methods
  * Same way to access and manipulate requests and responses such as body, headers, code, etc.
* Chooses best client you have installed on your system based on what we have found performs the best.
  * Currently net_http_persistent and typhoeus are nearly the same, but since net_http_persistent doesn't have a binary
    dependency, it wins.
  * You can run performance tests yourself by running: `ruby test/test_performance.rb`, quite a difference between the libs.
* Handles 503 errors with exponential backoff.


Getting Started
==============

Install the gem:

    gem install rest

Create an Rest client:

    @rest = Rest::Client.new()

To choose a specific underlying http client lib:

    @rest = Rest::Client.new(:gem=>:typhoeus)

Supported http libraries are:

* rest_client
* net_http_persistent
* typhoeus
* internal - this gem's built in client.

Then use it:

GET
------

    @rest.get(url, options...)

options:

- :params => query params for url
- :headers => headers

POST
-----

    @rest.post(url, options...)

options:

- :body => POST body
- :headers => headers hash
- :form_data => hash of fields/values, sent form encoded (only tested with default net-http-persistent)

PUT
------

    @rest.put(url, options...)

options:

- :body => POST body
- :headers => headers

DELETE
-------- 

    @rest.delete(url, options...)

Responses
=========

The response object you get back will always be consistent and will have the following functions:

    response.code
    response.body


Exceptions
======

If it didn't get a response for whatever reason, you will get a Rest::ClientError

If status code is 40X or 50X, it will raise an exception with the following methods.

    err.code
    err.response (which has body: err.response.body)

