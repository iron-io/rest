# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml

gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class TestRest < TestBase
  def setup
    super

    @request_bin = "http://requestb.in/16q6zwq1"

  end

  def bin
    @request_bin
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
    response = @rest.get("http://smooth-sword-1395.herokuapp.com/code/503?switch_after=3&switch_to=200")
    p response
    p response.code
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
    response = @rest.get("#{bin}?x=y#frag", :params=>{:param2=>"abc"})
    response = @rest.get("#{bin}", :params=>{param3: "xyz"})
    response = @rest.get("#{bin}")

  end

  def test_404
    response = @rest.get("http://rest-test.iron.io/code/404")
    p response
    p response.code
    assert response.code == 404
  end

  def test_400
    response = @rest.get("http://rest-test.iron.io/code/400")
    p response
    p response.code
    assert response.code == 400
  end

  def test_500
    assert_raise Rest::Error50X
    response = @rest.get("http://rest-test.iron.io/code/500")
    p response
    p response.code
    assert response.code == 500
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

    response = @rest.post("#{bin}",
                          :body => "some string body",
                          :headers => headers)
    p response


  end

end

