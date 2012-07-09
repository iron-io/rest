
module Rest

  # Base Rest error class
  class RestError < StandardError

  end

  class HttpError < RestError

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
end

