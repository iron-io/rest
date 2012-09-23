gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class TestTemp < TestBase
  def setup
    super

  end

  def test_gzip

    options = {}
    url = "http://api.stackexchange.com/2.1/users?order=desc&sort=reputation&site=stackoverflow"
    rest = Rest::Client.new

    res = rest.get(url, options)

    puts res.body
    assert res.body.include?("items")
  end
end

