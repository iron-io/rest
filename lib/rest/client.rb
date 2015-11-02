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

  @@logger = Logger.new(STDOUT)
  @@logger.level = Logger::INFO

  def self.logger=(logger)
    @@logger = logger
  end

  def self.logger()
    @@logger
  end


  class BackingGem
    attr_accessor :name, :gem_name

    def initialize(name, gem_name)
      @name = name
      @gem_name = gem_name
    end

  end

  # setup metadata about backing gem options
  @@backing_gems = {}
  @@backing_gems[:typhoeus] = BackingGem.new(:typhoeus, 'typhoeus')
  @@backing_gems[:rest_client] = BackingGem.new(:rest_client, 'rest_client')
  @@backing_gems[:net_http_persistent] = BackingGem.new(:net_http_persistent, 'net/http/persistent')
  @@backing_gems[:internal] = BackingGem.new(:internal, 'internal_client')

  def self.backing_gems
    @@backing_gems
  end

  class Client

    attr_accessor :options, :logger, :gem
    attr_reader :wrapper
    # options:
    # - :gem => specify gem explicitly
    #
    def initialize(options={})
      @options = options

      @logger = Rest.logger

      @gem = options[:gem]

      if @gem.nil?
        choose_best_gem()
      end

      if @gem == :excon
        require File.expand_path('wrappers/excon_wrapper', File.dirname(__FILE__))
        @wrapper = Rest::Wrappers::ExconWrapper.new(self)
        @logger.debug "Using excon gem."
      elsif @gem == :typhoeus
        require File.expand_path('wrappers/typhoeus_wrapper', File.dirname(__FILE__))
        @wrapper = Rest::Wrappers::TyphoeusWrapper.new(self)
        @logger.debug "Using typhoeus gem."
      elsif @gem == :net_http_persistent
        require File.expand_path('wrappers/net_http_persistent_wrapper', File.dirname(__FILE__))
        @wrapper = Rest::Wrappers::NetHttpPersistentWrapper.new(self)
        @logger.debug "Using net-http-persistent gem."
      elsif @gem == :rest_client
        require File.expand_path('wrappers/rest_client_wrapper', File.dirname(__FILE__))
        @wrapper = Rest::Wrappers::RestClientWrapper.new
        hint = (options[:gem] ? "" : "NOTICE: Please upgrade to Ruby 2.X for optimal performance.")
        puts hint
        @logger.debug "Using rest-client gem. #{hint}"
        RestClient.proxy = options[:http_proxy] if options[:http_proxy]
      else # use internal client
        @wrapper = Rest::Wrappers::InternalClientWrapper.new
        @logger.debug "Using rest internal client. #{hint}"
      end
      # Always set this because of the shared post_file in base_wrapper
      InternalClient.proxy = options[:http_proxy] if options[:http_proxy]
    end

    def choose_best_gem
      gems_to_try = []
      #puts "Ruby MAJOR: #{Rest.ruby_major}"
      if Rest.ruby_major >= 2
        gems_to_try << :net_http_persistent
        gems_to_try << :typhoeus
        gems_to_try << :rest_client
        gems_to_try << :internal
      else
        # net-http-persistent has issues with ssl and keep-alive connections on ruby < 1.9.3p327
        gems_to_try << :typhoeus
        gems_to_try << :rest_client
        gems_to_try << :internal
      end
      gems_to_try.each_with_index do |g, i|
        bg = Rest.backing_gems[g]
        begin
          require bg.gem_name unless g == :internal
          @gem = bg.name
          return @gem
        rescue LoadError => ex
          if (i+1) >= gems_to_try.length
            raise ex
          end
          @logger.debug "LoadError on #{bg.name}, trying #{Rest.backing_gems[gems_to_try[i+1]].name}..."
        end
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

    def patch(url, req_hash={})
      res = nil
      res = perform_op(:patch, req_hash) do
        res = @wrapper.patch(url, req_hash)
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
