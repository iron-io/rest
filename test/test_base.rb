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
    @rest = Rest::Client.new(:gem => :excon)
    @rest.logger.level = Logger::DEBUG
    @request_bin = "http://requestb.in/18l5ny91"

  end

  def bin
    @request_bin
  end

end
