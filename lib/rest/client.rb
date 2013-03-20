if RUBY_VERSION.split('.')[1].to_i == 8
  require 'rubygems'
  gem 'json'
end

require 'json'
require 'logger'

# This is a simple wrapper that can use different http clients depending on what's installed.
# The purpose of this is so that users who can't install binaries easily (like windoze users)
# can have fallbacks that work.

require 'rest/errors'

module Rest

  require 'rest/wrappers/base_wrapper'

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger()
    @logger
  end

  class Client

    attr_accessor :options, :logger, :gem
    # options:
    # - :gem => specify gem explicitly
    #
    def initialize(options={})
      @options = options
      # todo: initialize this as module variable above
      @logger = Logger.new(STDOUT)
      @logger.level = options[:log_level] || Logger::INFO
      Rest.logger = @logger

      @gem = options[:gem] if options[:gem]

      if @gem.nil?
        choose_best_gem()
      end

      if @gem == :excon
        require File.expand_path('wrappers/excon_wrapper', File.dirname(__FILE__))
        @wrapper = Rest::Wrappers::ExconWrapper.new(self)
        @logger.debug "Using excon gem."
      elsif @gem == :typhoeus
        require File.expand_path('wrappers/typhoeus_wrapper', File.dirname(__FILE__))
        @wrapper = Rest::Wrappers::TyphoeusWrapper.new
        @logger.debug "Using typhoeus gem."
      elsif @gem == :net_http_persistent
        require File.expand_path('wrappers/net_http_persistent_wrapper', File.dirname(__FILE__))
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
        require 'typhoeus'
        @gem = :typhoeus
      rescue LoadError => ex
        begin
          # try net-http-persistent
          require 'net/http/persistent'
          @gem = :net_http_persistent
        rescue LoadError => ex
          raise ex
        end
      end
      if @gem.nil?
        require 'rest_client'
        @gem = :rest_client
      end
    end

    def get(url, req_hash={})
      res = nil
      res = perform_op(:get, req_hash) do
        res = @wrapper.get(url, req_hash)
      end
      return res
    end

    # This will attempt to perform the operation with an exponential backoff on 503 errors.
    # Amazon services throw 503
    # todo: just make perform_op a method and have it call the wrapper. The block is a waste now.
    def perform_op(method, req_hash, options={}, &blk)
      set_defaults(options)
      max_retries = options[:max_retries] || 5
      max_follows = options[:max_follows] || 10
      if options[:follow_count] && options[:follow_count] >= max_follows
        raise Rest::RestError, "Too many follows. #{options[:follow_count]}"
      end
      current_retry = 0
      current_follow = 0
      success = false
      tries = 0
      res = nil
      #  todo: typhoeus does retries in the library so it shouldn't do retries here. And we should use the max_retries here as a parameter to typhoeus
      while current_retry < max_retries && current_follow < max_follows do
        tries += 1
        begin
          res = yield blk
          res.tries = tries
          if res.code >= 300 && res.code < 400
            # try new location
            #p res.headers
            loc = res.headers["location"]
            @logger.debug "#{res.code} Received. Trying new location: #{loc}"
            if loc.nil?
              raise InvalidResponseError.new("No location header received with #{res.code} status code!")
            end
            # options.merge({:max_follows=>options[:max_follows-1]}
            options[:follow_count] ||= 0
            options[:follow_count] += 1
            res = perform_op(method, req_hash, options) do
              res = @wrapper.send(method, loc, req_hash)
            end
            #puts 'X: ' + res.inspect
            return res
          end
          # If it's here, then it's all good
          break
        rescue Rest::HttpError => ex
          if ex.code == 503
            raise ex if current_retry == max_retries - 1

            pow = (4 ** (current_retry)) * 100 # milliseconds
                                               #puts 'pow=' + pow.to_s
            s = rand * pow
                                               #puts 's=' + s.to_s
            sleep_secs = 1.0 * s / 1000.0
                                               #puts 'sleep for ' + sleep_secs.to_s
            current_retry += 1
            @logger.debug "#{ex.code} Received. Retrying #{current_retry} out of #{max_retries} max in #{sleep_secs} seconds."
            sleep sleep_secs
          else
            raise ex
          end
        end
      end
      res
    end

    def set_defaults(options)
      options[:max_retries] ||= (@options[:max_retries] || 5)
      options[:max_follows] ||= (@options[:max_follows] || 10)
    end

    # req_hash options:
    # - :body => post body
    #
    def post(url, req_hash={})
      res = nil
      res = perform_op(:post, req_hash) do
        res = @wrapper.post(url, req_hash)
      end
      return res
    end

    def put(url, req_hash={})
      res = nil
      res = perform_op(:put, req_hash) do
        res = @wrapper.put(url, req_hash)
      end
      return res
    end

    def delete(url, req_hash={})
      res = nil
      res = perform_op(:delete, req_hash) do
        res = @wrapper.delete(url, req_hash)
      end
      return res
    end

    def post_file(url, req_hash={})
      res = nil
      res = perform_op(:post_file, req_hash) do
        res = @wrapper.post_file(url, req_hash)
      end
      return res
    end

    def close
      @wrapper.close
    end

  end
end
