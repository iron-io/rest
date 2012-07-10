
module Rest

  # Base Rest error class
  class RestError < StandardError

  end

  class HttpError < RestError
    def initialize(response)
      super("#{response.code} Error")
      @response = response
    end

    def response
      @response
    end
    def code
      response.code
    end

    def to_s
      "HTTP #{code} Error. #{response.body}"
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

