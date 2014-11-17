require 'test/unit'
require 'yaml'
require 'quicky'
require File.expand_path('test_base', File.dirname(__FILE__))

class TestPerformance < TestBase
  def setup
    super

  end

  def test_get_performance
    puts 'test_get_performance'

    times = 100

    quicky = Quicky::Timer.new

    to_run = [:typhoeus, :rest_client, :net_http_persistent, :internal]
    to_run.each do |gem|
      run_perf(quicky, times, gem)
    end

    quicky.results.each_pair do |k, v|
      puts "#{k}: #{v.duration}"
    end

  end

  def run_perf(quicky, times, gem)
    puts "Starting #{gem} test..."
    client = Rest::Client.new(:gem => gem)
    quicky.loop(gem, times) do
      client.get("http://rest-test.iron.io/code/200")
    end
  end

end

