Rest Wrapper
-------------

Getting Started
==============

Install the gem:

    gem install rest

Create an IronMQ client object:

    @rest = Rest::Client.new()

Then use it.

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

DELETE
======

    @rest.delete(url, options...)



