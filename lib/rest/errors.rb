
module Rest

  # Base Rest error class
  class RestError < StandardError

  end

  class HttpError < RestError
    attr_reader :response, :code
    attr_accessor :options

    def initialize(response, code, options={})
      super("#{code} Error")
      @response = response
      @code = code
      @options = options
    end

    def to_s
      "HTTP #{code} Error."
    end
  end

  # If it didn't even get a response, it will be a ClientError
  class ClientError < RestError

  end

  class TimeoutError < ClientError
    def initialize(msg=nil)
      msg ||= "HTTP Request Timed out."
      super(msg)
    end
  end

  class InvalidResponseError < RestError

  end
end

