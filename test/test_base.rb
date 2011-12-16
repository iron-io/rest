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
    #@config = YAML::load_file(File.expand_path(File.join("~", "Dropbox", "configs", "rest", "test", "config.yml")))
    @rest = Rest::Client.new
    #@client.logger.level = Logger::DEBUG

  end
end
