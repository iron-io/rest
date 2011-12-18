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
    puts "Could not load typhoeus. #{ex.class.name}: #{ex.message}. Falling back to rest-client. Please install 'typhoeus' gem for best performance."
    require 'rest_client'
    Rest.gem = :rest_client
    require_relative 'wrappers/typhoeus_wrapper'
  end


  class Client

    # options:
    # - :gem => specify gem explicitly
    #
    def initialize(options={})
      @logger = Logger.new(STDOUT)
      @logger.level=Logger::INFO

      Rest.gem = options[:gem] if options[:gem]

      if Rest.gem == :typhoeus
        @wrapper = Rest::Wrappers::TyphoeusWrapper.new
      else
        @wrapper = Rest::Wrappers::RestClientWrapper.new
      end

    end


    def get(url, req_hash={})
      @wrapper.get(url, req_hash)
    end

    # req_hash options:
    # - :body => post body
    #
    def post(url, req_hash={})
      @wrapper.post(url, req_hash)
    end

    def delete(url, req_hash={})
      @wrapper.delete(url, req_hash)
    end
  end
end