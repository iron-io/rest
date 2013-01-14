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
    @rest = Rest::Client.new(:gem => :net_http_persistent, :log_level=>Logger::DEBUG)

  end

  def test_fake
  end

  ALL_OPS = [:get, :put, :post, :delete]


end
