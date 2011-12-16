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

    @rest.get(full_url, options...)

options:

- params - query params for url
- headers

POST
======

    @rest.post(full_url, options...)

options:

- headers
- body



