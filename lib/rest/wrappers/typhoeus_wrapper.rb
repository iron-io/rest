require 'typhoeus'

module Rest

  module Wrappers

    class TyphoeusTimeoutError < Rest::TimeoutError
      def initialize(response)
        msg ||= "HTTP Request Timed out. Curl code: #{response.curl_return_code}. Curl error msg: #{response.curl_error_message}."
        super(msg)
      end
    end

    class TyphoeusResponseWrapper < BaseResponseWrapper

      def initialize(response)
        @response = response
      end

      def code
        @response.code
      end

      def body
        @response.body
      end

      def headers_orig
        @response.headers_hash
      end

    end

    class TyphoeusWrapper < BaseWrapper

      def default_typhoeus_options
        req_hash = {}
        # todo: should change this timeout to longer if it's for posting file
        req_hash[:connect_timeout] = 5000
        req_hash[:timeout] = 10000
        req_hash[:follow_location] = true
        req_hash[:max_redirects] = 2
        req_hash
      end

      def get(url, req_hash={})
        req_hash = default_typhoeus_options.merge(req_hash)
        # puts "REQ_HASH=" + req_hash.inspect
        response = Typhoeus::Request.get(url, req_hash)
        #p response
        response = handle_response(response)
        response
      end

      def handle_response(response)
        if response.timed_out?
          raise TyphoeusTimeoutError.new(response)
        end
        r = TyphoeusResponseWrapper.new(response)
        if response.code >= 400
          raise Rest::HttpError.new(r)
        end
        r
      end



      def post(url, req_hash={})
        req_hash = default_typhoeus_options.merge(req_hash)
        to_json_parts(req_hash)
        response = Typhoeus::Request.post(url, req_hash)
        response = handle_response(response)
        response
      end

      def put(url, req_hash={})
        req_hash = default_typhoeus_options.merge(req_hash)
        # puts "REQ_HASH=" + req_hash.inspect
        response = Typhoeus::Request.put(url, req_hash)
        response = handle_response(response)
        response
      end

      def delete(url, req_hash={})
        req_hash = default_typhoeus_options.merge(req_hash)
        response = Typhoeus::Request.delete(url, req_hash)
        response = handle_response(response)
        response
      end

    end

  end

end
