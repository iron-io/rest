require 'typhoeus'

module Rest

  module Wrappers

    class TyphoeusTimeoutError < Rest::TimeoutError
      def initialize(response)
        msg ||= "HTTP Request Timed out. Curl code: #{response.return_code}. Curl error msg: #{response.return_message}."
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

      def initialize(client)
        @client = client
      end

      def default_typhoeus_options
        req_hash = {}
        # todo: should change this timeout to longer if it's for posting file
        req_hash[:connecttimeout] = 5000
        req_hash[:timeout] = 10000
        req_hash[:followlocation] = true
        req_hash[:maxredirs] = 3
        req_hash[:accept_encoding] = 'gzip'
        req_hash
      end

      def get(url, req_hash={})
        req_hash = default_typhoeus_options.merge(req_hash)
        req_hash[:proxy] = @client.options[:http_proxy] if @client.options[:http_proxy]
        # puts "REQ_HASH=" + req_hash.inspect
        response = Typhoeus::Request.get(url, req_hash)
        #p response
        response = handle_response(response)
        response
      end

      def handle_response(response)
        r = TyphoeusResponseWrapper.new(response)
        if response.success?
          return r
        elsif response.timed_out?
          raise TyphoeusTimeoutError.new(response)
        elsif response.code == 0
          # Could not get an http response, something's wrong.
          raise Rest::RestError.new("Could not get a response. Curl error 0.")
        else
          raise Rest::HttpError.new(r, r.code)
        end
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

      def patch(url, req_hash={})
        req_hash = default_typhoeus_options.merge(req_hash)
        # puts "REQ_HASH=" + req_hash.inspect
        response = Typhoeus::Request.patch(url, req_hash)
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
