require 'yaml'
begin
  require File.join(File.dirname(__FILE__), '../lib/rest')
rescue Exception => ex
  puts "Could NOT load gem: " + ex.message
  raise ex
end

@rest = Rest::Client.new # (:gem=>:rest_client)
@rest.logger.level = Logger::DEBUG

response = @rest.get("http://smooth-sword-1395.herokuapp.com/code/503?switch_after=3&switch_to=200")
p response
p response.code
