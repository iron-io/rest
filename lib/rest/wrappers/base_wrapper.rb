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

      r2 = RestClient.post(url, req_hash, headers)
      response = Rest::Wrappers::RestClientResponseWrapper.new(r2)
    rescue RestClient::Exception => ex
      raise Rest::Wrappers::RestClientExceptionWrapper.new(ex)
    end
    response
  end

  # if wrapper has a close/shutdown, override this
  def close

  end
end

# we need it for post_file, ok as gem already depends on it
require_relative 'rest_client_wrapper'
