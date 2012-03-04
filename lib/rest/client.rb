require 'json'
require 'logger'

# This is a simple wrapper that can use different http clients depending on what's installed.
# The purpose of this is so that users who can't install binaries easily (like windoze users) can have fallbacks that work

module Rest

  class ClientError < StandardError

  end


  class TimeoutError < ClientError
    def initialize(msg=nil)
      msg ||= "HTTP Request Timed out."
      super(msg)
    end
  end


  def self.gem=(g)
    @gem = g
  end

  def self.gem
    @gem
  end

  begin
    require 'typhoeus'
    Rest.gem = :typhoeus
    require_relative 'wrappers/typhoeus_wrapper'
  rescue LoadError => ex
    puts "Could not load typhoeus, falling back to rest-client. Please install 'typhoeus' gem for best performance."
    require 'rest_client'
    Rest.gem = :rest_client
    require_relative 'wrappers/rest_client_wrapper'
  end


  class Client

    attr_accessor :options
    # options:
    # - :gem => specify gem explicitly
    #
    def initialize(options={})
      @logger = Logger.new(STDOUT)
      @logger.level=Logger::INFO
      @options = options

      Rest.gem = options[:gem] if options[:gem]

      if Rest.gem == :typhoeus
        @wrapper = Rest::Wrappers::TyphoeusWrapper.new
      else
        @wrapper = Rest::Wrappers::RestClientWrapper.new
      end

    end

    def get(url, req_hash={})
      res = nil
      perform_op do
        res = @wrapper.get(url, req_hash)
      end
      return res
    end

    def perform_op(&blk)
      max_retries = @options[:max_retries] || 5
      current_retry = 0
      success = false
      res = nil
      while current_retry < max_retries do
        res = yield blk
        #p res
        #p res.code
        if res.code == 503
          pow = (4 ** (current_retry)) * 100 # milliseconds
          #puts 'pow=' + pow.to_s
          s = Random.rand * pow
          #puts 's=' + s.to_s
          sleep_secs = 1.0 * s / 1000.0
          #puts 'sleep for ' + sleep_secs.to_s
          current_retry += 1
          @logger.debug "503 Error. Retrying #{current_retry} out of #{max_retries} max."
          sleep sleep_secs
        else
          break
        end
      end
      res
    end

    # req_hash options:
    # - :body => post body
    #
    def post(url, req_hash={})
      res = nil
      perform_op do
        res = @wrapper.post(url, req_hash)
      end
      return res
    end

    def put(url, req_hash={})
      res = nil
      perform_op do
        res = @wrapper.put(url, req_hash)
      end
      return res
    end

    def delete(url, req_hash={})
      res = nil
      perform_op do
        res = @wrapper.delete(url, req_hash)
      end
      return res
    end
  end
end
