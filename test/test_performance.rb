# Put config.yml file in ~/Dropbox/configs/ironmq_gem/test/config.yml

gem 'test-unit'
require 'test/unit'
require 'yaml'
require_relative 'test_base'

class TestTests < TestBase
  def setup
    super

  end

  def test_get_performance

    times = 100

    collector = []

    collector << run_perf(times, :typhoeus)
    collector << run_perf(times, :rest_client)
    collector << run_perf(times, :net_http_persistent)

    collector.each do |c|
      p c
    end

  end

  def run_perf(times, gem)
    puts "Starting #{gem} test..."
    t = Time.now
    client = Rest::Client.new(:gem => gem)
    times.times do |i|
      client.get("http://requestb.in/ydyd4nyd")
    end
    duration = Time.now.to_f - t.to_f
    puts "#{times} posts took #{duration}"
    {:gem=>gem, :duration=>duration}
  end

end

