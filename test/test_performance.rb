gem 'test-unit'
require 'test/unit'
require 'yaml'
require 'quicky'

require_relative 'test_base'

class TestPerformance < TestBase
  def setup
    super

  end

  def test_get_performance
    puts 'test_get_performance'

    times = 10

    quicky = Quicky::Timer.new

    to_run = [:typhoeus, :rest_client, :net_http_persistent]
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
      client.get(bin)
    end
  end

end

