# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml

gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class TestRest < TestBase
  def setup
    super


  end

  def test_basics
    response = @rest.get("http://www.github.com")
    p response
    p response.code
    assert response.code == 200
    p response.body
    assert response.body.include?("Social Coding")
  end

  def test_backoff
    response = @rest.get("http://rest-test.iron.io/code/503?switch_after=3&switch_to=200")
    p response
    p response.code
    assert response.tries == 3
    assert response.code == 200

    # Now let's try to error out
    begin
      response = @rest.get("http://rest-test.iron.io/code/503")
      assert false, "shouldn't get here"
    rescue Rest::HttpError => ex
      puts "EX: " + ex.inspect
      p ex.backtrace
      assert ex.is_a?(Rest::HttpError)
      assert ex.response
      assert ex.response.body
      assert ex.code == 503
      #assert ex.response.tries == 5 # the default max
      assert ex.response.body.include?("503")
      assert ex.to_s.include?("503")
    end

  end

  def test_gets
    @token = "abctoken"
    headers = {
        'Content-Type' => 'application/json',
        'Authorization' => "OAuth #{@token}",
        'User-Agent' => "someagent"
    }
    body = {"foo" => "bar"}
    response = @rest.get("#{bin}?param1=x")

    # params as hash
    response = @rest.get("#{bin}?x=y#frag", :params => {:param2 => "abc"})
    response = @rest.get("#{bin}", :params => {param3: "xyz"})
    response = @rest.get("#{bin}")

    response = @rest.get("http://rest-test.iron.io/code/200")
    assert response.code == 200
    assert response.body.include?("200")
    p response.headers
    assert response.headers.is_a?(Hash)

  end

  def test_404
    begin
      response = @rest.get("http://rest-test.iron.io/code/404")
      assert false, "shouldn't get here"
    rescue Rest::HttpError => ex
      puts "EX: " + ex.inspect
      p ex.backtrace
      assert ex.is_a?(Rest::HttpError)
      assert ex.response
      assert ex.response.body
      assert ex.code == 404
      assert ex.response.body.include?("404")
      assert ex.to_s.include?("404")
    end
  end

  def test_400
    begin
      response = @rest.get("http://rest-test.iron.io/code/400")
      assert false, "shouldn't get here"
    rescue Rest::HttpError => ex
      puts "EX: #{ex}"
      p ex.backtrace
      assert ex.is_a?(Rest::HttpError)
      assert ex.response
      assert ex.response.body
      assert ex.code == 400
    end
  end

  def test_500
    puts '500'
    begin
      response = @rest.get("http://rest-test.iron.io/code/500")
      assert false, "shouldn't get here"
    rescue Rest::HttpError => ex
      puts "EX: " + ex.inspect
      p ex.backtrace
      assert ex.is_a?(Rest::HttpError)
      assert ex.response
      assert ex.response.body
      assert ex.code == 500
    end
  end


  def test_post_with_headers

    @token = "abctoken"
    headers = {
        'Content-Type' => 'application/json',
        'Authorization' => "OAuth #{@token}",
        'User-Agent' => "someagent"
    }
    body = {"foo" => "bar"}
    response = @rest.post("#{bin}",
                          :body => body,
                          :headers => headers)
    p response
    response = @rest.post("http://rest-test.iron.io/code/200",
                          :body => body,
                          :headers => headers)
    p response

    response = @rest.post("#{bin}",
                          :body => "some string body",
                          :headers => headers)
    p response


  end

end

