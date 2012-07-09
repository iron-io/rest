require 'yaml'
begin
  require File.join(File.dirname(__FILE__), '../lib/rest')
rescue Exception => ex
  puts "Could NOT load gem: " + ex.message
  raise ex
end

@rest = Rest::Client.new(:gem=>:net_http_persistent)
@rest.logger.level = Logger::DEBUG

begin
response = @rest.get("http://rest-test.iron.io/code/400")
p response
p response.code
