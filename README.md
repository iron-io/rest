Rest Wrapper
-------------

HTTP/REST client wrapper that provides a standard interface for making http requests using different http clients.
If no client is specified it will choose the best one you have installed.

Getting Started
==============

Install the gem:

    gem install rest

Create an Rest client:

    @rest = Rest::Client.new()

To choose a specific underlying http client lib:

    @rest = Rest::Client.new(:gem=>:typhoeus)

Supported http libraries are:

* rest-client
* net-http-persistent
* typhoeus

Then use it:

GET
=========

    @rest.get(url, options...)

options:

- :params => query params for url
- :headers => headers

POST
======

    @rest.post(url, options...)

options:

- :body => POST body
- :headers => headers

PUT
======

    @rest.put(url, options...)

options:

- :body => POST body
- :headers => headers

DELETE
======

    @rest.delete(url, options...)



