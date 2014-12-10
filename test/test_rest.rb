# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml

require 'test/unit'
require 'yaml'
require File.expand_path('test_base', File.dirname(__FILE__))

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
    assert response.body.include?("Explore")
  end

  def test_backoff
    response = @rest.get("http://rest-test.iron.io/code/503?switch_after=2&switch_to=200")
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
    ALL_OPS.each do |op|
      puts "Trying #{op}"
      response = @rest.__send__(op, "http://rest-test.iron.io/code/200")
      assert response.code == 200
      assert response.body.include?("200")
      p response.headers
      assert response.headers.is_a?(Hash)
    end
  end


  def test_404
    puts 'test_404'
    ALL_OPS.each do |op|
      puts "Trying #{op}"
      begin
        response = @rest.__send__(op, "http://rest-test.iron.io/code/404")
        assert false, "shouldn't get here"
      rescue Rest::HttpError => ex
        puts "Expected error: #{ex}"
        #p ex.backtrace
        assert ex.is_a?(Rest::HttpError)
        assert ex.response
        assert ex.response.body
        assert_equal 404, ex.code
        assert ex.response.body.include?("404")
        assert ex.to_s.include?("404")
      end
    end

  end

  def test_400
    puts 'test_400'
    ALL_OPS.each do |op|
      puts "Trying #{op}"
      begin
        response = @rest.__send__(op, "http://rest-test.iron.io/code/400")
        assert false, "shouldn't get here"
      rescue Rest::HttpError => ex
        puts "Expected error: #{ex}"
        #p ex.backtrace
        assert ex.is_a?(Rest::HttpError)
        assert ex.response
        assert ex.response.body
        assert ex.code == 400
      end
    end

  end

  def test_500
    puts 'test_500'
    ALL_OPS.each do |op|
      puts "Trying #{op}"
      begin
        response = @rest.__send__(op, "http://rest-test.iron.io/code/500")
        assert false, "shouldn't get here"
      rescue Rest::HttpError => ex
        puts "Expected error: #{ex}"
        #p ex.backtrace
        assert ex.is_a?(Rest::HttpError)
        assert ex.response
        assert ex.response.body
        assert ex.code == 500
      end
    end
  end


  def test_post_with_headers

    @token = "abctoken"
    oauth = "OAuth #{@token}"
    headers = {
        'Content-Type' => 'application/json',
        'Authorization' => oauth,
        'User-Agent' => "someagent"
    }
    key = "rest-gem-post"
    body = {"foo" => "bar"}
    response = @rest.post("http://rest-test.iron.io/code/200?store=#{key}",
                          :body => body,
                          :headers => headers)
    p response
    response = @rest.get("http://rest-test.iron.io/stored/#{key}")
    parsed = JSON.parse(response.body)
    p parsed
    assert_equal body, JSON.parse(parsed['body'])
    assert_equal oauth, parsed['headers']['Authorization']

    body2 = "hello world"
    response = @rest.post("http://rest-test.iron.io/code/200?store=#{key}",
                          :body => body2,
                          :headers => headers)
    p response
    response = @rest.get("http://rest-test.iron.io/stored/#{key}")
    parsed = JSON.parse(response.body)
    assert_equal body2, parsed['body']

    response = @rest.post("http://rest-test.iron.io/code/200",
                          :body => body,
                          :headers => headers)
    p response

    response = @rest.post("http://rest-test.iron.io/code/200?store=#{key}",
                          :body => "some string body",
                          :headers => headers)
    p response

  end

  def test_form_post
    r = @rest.post("http://rest-test.iron.io/code/200", :params => {:q => "Rick Astley"})
    p r
  end

  def test_gzip

    options = {}
    url = "http://api.stackexchange.com/2.1/users?order=desc&sort=reputation&site=stackoverflow"
    rest = Rest::Client.new

    res = rest.get(url, options)

    # puts res.body
    assert res.body.include?("items")
  end

  def test_bad_host
    puts "test bad host"
    # OpenDNS, YOU SUCK!
    assert_raise SocketError do
      r = @rest.get("http://something-that-is-not-here.com", :params => {:q => "Rick Astley"})
      p r
    end
  end

  def test_post_file
    r = @rest.post_file("http://httpbin.org/post", :params => {:q => "Rick Astley"})
    p r
  end
end

