require 'json'
require 'logger'

# This is a simple wrapper that can use different http clients depending on what's installed.
# The purpose of this is so that users who can't install binaries easily (like windoze users)
# can have fallbacks that work.

module Rest

  class ClientError < StandardError

  end


  class TimeoutError < ClientError
    def initialize(msg=nil)
      msg ||= "HTTP Request Timed out."
      super(msg)
    end
  end

  require_relative 'wrappers/base_wrapper'

  #def self.puts(s)
  #  Kernel.puts("rest gem: #{s}")
  #end

  class Client

    attr_accessor :options, :logger, :gem
    # options:
    # - :gem => specify gem explicitly
    #
    def initialize(options={})
      @logger = Logger.new(STDOUT)
      @logger.level=Logger::INFO
      @options = options

      @gem = options[:gem] if options[:gem]

      if @gem.nil?
        choose_best_gem()
      end

      if @gem == :typhoeus
        require_relative 'wrappers/typhoeus_wrapper'
        @wrapper = Rest::Wrappers::TyphoeusWrapper.new
        @logger.debug "Using typhoeus gem."
      elsif @gem == :net_http_persistent
        require_relative 'wrappers/net_http_persistent_wrapper'
        @wrapper = Rest::Wrappers::NetHttpPersistentWrapper.new(self)
        @logger.debug "Using net-http-persistent gem."
      else
        @wrapper = Rest::Wrappers::RestClientWrapper.new
        hint = (options[:gem] ? "" : " Please install 'typhoeus' or net-http-persistent gem for best performance.")
        @logger.debug "Using rest-client gem.#{hint}"
      end
    end

    def choose_best_gem
      begin
        raise LoadError
        #require 'typhoeus'
        #@gem = :client
      rescue LoadError => ex
        begin
          # try net-http-persistent
          #require 'net/http/persistent'
          #@gem = :net_http_persistent
        rescue LoadError => ex
        end
      end
      if @gem.nil?
        require 'rest_client'
        @gem = :rest_client
      end
    end

    def get(url, req_hash={})
      res = nil
      perform_op do
        res = @wrapper.get(url, req_hash)
      end
      return res
    end

    # This will attempt to perform the operation with an exponential backoff on 503 errors.
    # Amazon services throw 503
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
          puts 'sleep for ' + sleep_secs.to_s
          current_retry += 1
          @logger.debug "503 Received. Retrying #{current_retry} out of #{max_retries} max in #{sleep_secs} seconds."
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

    def post_file(url, req_hash={})
      res = nil
      perform_op do
        res = @wrapper.post_file(url, req_hash)
      end
      return res
    end

    def close
      @wrapper.close
    end

  end
end
