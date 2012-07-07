# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml

gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class TestTests < TestBase
  def setup
    super


  end

  def test_basics
    response = @rest.get("http://www.github.com")
    p response
    p response.code
    assert response.code == 200
    #p response.body
    assert response.body.include?("Social Coding")

  end

  def test_gets
    @token = "abctoken"
    headers = {
        'Content-Type' => 'application/json',
        'Authorization' => "OAuth #{@token}",
        'User-Agent' => "someagent"
    }
    body = {"foo" => "bar"}
    response = @rest.get("http://requestb.in/16q6zwq1?param1=x")

  end

  def test_post_with_headers

    @token = "abctoken"
    headers = {
        'Content-Type' => 'application/json',
        'Authorization' => "OAuth #{@token}",
        'User-Agent' => "someagent"
    }
    body = {"foo" => "bar"}
    response = @rest.post("http://requestb.in/ydyd4nyd",
                          :body => body,
                          :headers => headers)
    p response

    response = @rest.post("http://requestb.in/ydyd4nyd",
                          :body => "some string body",
                          :headers => headers)
    p response


  end

end

