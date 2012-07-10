gem 'test-unit'
require 'test/unit'
require 'yaml'
begin
  require File.join(File.dirname(__FILE__), '../lib/rest')
rescue Exception => ex
  puts "Could NOT load gem: " + ex.message
  raise ex
end

class TestBase < Test::Unit::TestCase

  def setup
    puts 'setup'
    @rest = Rest::Client.new(:gem => :net_http_persistent)
    @rest.logger.level = Logger::DEBUG
    @request_bin = "http://requestb.in/13t6hs51"

  end

  def bin
    @request_bin
  end

end
