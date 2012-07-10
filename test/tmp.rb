gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class TestTemp < TestBase
  def setup
    super

  end

  def test_500
    puts '500'
    begin
      puts 'in block'
      response = @rest.get("http://rest-test.iron.io/code/500")
      assert false, "shouldn't get here"
    rescue => ex
      p ex
      assert ex.is_a?(Rest::HttpError)
      assert ex.response
      assert ex.response.body
      assert ex.code == 500
    end
  end
end

