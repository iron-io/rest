# we need InternalClient client for post_file
module Rest
  class BaseWrapper

    def post_file(url, req_hash={})
      response = nil
      begin
        if req_hash[:body]
          req_hash = req_hash.merge(req_hash[:body])
          req_hash.delete(:body)
        end

        headers = {}
        if req_hash[:headers]
          headers = req_hash[:headers]
          req_hash.delete(:headers)
        end

        r2 = Rest::InternalClient.post(url, req_hash, headers)
        response = Rest::Wrappers::InternalClientResponseWrapper.new(r2)
      rescue Rest::InternalClient::Exception => ex
        raise Rest::Wrappers::InternalClientExceptionWrapper.new(ex)
      end
      response
    end

    # if body is a hash, it will convert it to json
    def to_json_parts(h)
      h[:body] = h[:body].to_json if h[:body] && h[:body].is_a?(Hash)
    end

    # if wrapper has a close/shutdown, override this
    def close

    end
  end

  class BaseResponseWrapper
    attr_accessor :tries

    # Provide a headers_orig method in your wrapper to allow this to work
    def headers
      new_h = {}
      headers_orig.each_pair do |k, v|
        if v.is_a?(Array) && v.size == 1
          v = v[0]
        end
        new_h[k.downcase] = v
      end
      new_h
    end

  end
end
