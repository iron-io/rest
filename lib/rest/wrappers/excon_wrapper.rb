require 'excon'

module Rest

  module Wrappers
    class ExconExceptionWrapper < ClientError
      def initialize(ex)
        super(ex.message)
        @ex = ex
      end
    end

    class ExconResponseWrapper < BaseResponseWrapper
      def initialize(response)
        @response = response
      end

      def code
        @response.status
      end

      def body
        @response.body
      end

      def headers_orig
        @response.headers
      end

    end

    class ExconWrapper < BaseWrapper

      def initialize(client)
        @client = client
        # Would need to pass in base url to use persistent connection.
        #@http = Excon.new("")
      end

      def default_headers
        {}
      end

      def get(url, req_hash={})
        response = nil
        begin
          uri = URI(url)
          req_hash[:method] = :get
          req_hash[:url] = url
          req_hash[:headers] ||= default_headers
          req_hash[:query] = req_hash[:params] if req_hash[:params]
          #p req_hash
          response = excon_request(url, req_hash)
        rescue Rest::RestClient::Exception => ex
          #p ex
          raise ExconExceptionWrapper.new(ex)
        end
        response
      end

      def excon_request(url, req_hash)
        conn = Excon.new(url)
        r2 = conn.request(req_hash)
        response = ExconResponseWrapper.new(r2)
        if response.code >= 400
          raise HttpError.new(response, response.code)
        end
        response
      end

      def post(url, req_hash={})
        response = nil
        begin
          req_hash[:method] = :post
          req_hash[:url] = url
          to_json_parts(req_hash)
          response = excon_request(url, req_hash)
        rescue Rest::RestClient::Exception => ex
          raise HttpError.new(ex.response, ex.http_code)
        end
        response
      end

      def put(url, req_hash={})
        response = nil
        begin
          req_hash[:method] = :put
          req_hash[:url] = url
          response = excon_request(url, req_hash)
        rescue Rest::RestClient::Exception => ex
          raise RestClientExceptionWrapper.new(ex)
        end
        response
      end

      def patch(url, req_hash={})
        response = nil
        begin
          req_hash[:method] = :patch
          req_hash[:url] = url
          response = excon_request(url, req_hash)
        rescue RestClient::Exception => ex
          raise RestClientExceptionWrapper.new(ex)
        end
        response
      end

      def delete(url, req_hash={})
        response = nil
        begin
          req_hash[:method] = :delete
          req_hash[:url] = url
          response = excon_request(url, req_hash)
        rescue Rest::RestClient::Exception => ex
          raise RestClientExceptionWrapper.new(ex)
        end
        response
      end
    end

  end

end
