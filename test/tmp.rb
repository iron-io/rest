require 'test/unit'
require 'yaml'
require_relative 'test_base'

class TestTemp < TestBase
  def setup
    super

  end

  def test_post_file
    r = @rest.post_file("http://httpbin.org/post", :params=>{:q => "Rick Astley"})
    p r
  end

end

