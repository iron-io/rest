require 'excon'

module Rest

  module Wrappers
    class ExconExceptionWrapper < ClientError
      def initialize(ex)
        super(ex.message)
        @ex = ex
      end
    end

    class ExconResponseWrapper
      def initialize(response)
        @response = response
      end

      def code
        @response.status
      end

      def body
        @response.body
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
        rescue RestClient::Exception => ex
          #p ex
          if ex.http_code == 404
            return RestClientResponseWrapper.new(ex.response)
          end
          raise RestClientExceptionWrapper.new(ex)
        end
        response
      end

      def excon_request(url, req_hash)
        conn = Excon.new(url)
        r2 = conn.request(req_hash)
        response = ExconResponseWrapper.new(r2)
      end

      def post(url, req_hash={})
        response = nil
        begin
          req_hash[:method] = :post
          req_hash[:url] = url
          response = excon_request(url, req_hash)
        rescue RestClient::Exception => ex
          raise RestClientExceptionWrapper.new(ex)
        end
        response
      end

      def put(url, req_hash={})
        response = nil
        begin
          req_hash[:method] = :put
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
        rescue RestClient::Exception => ex
          raise RestClientExceptionWrapper.new(ex)
        end
        response
      end
    end

  end

end
