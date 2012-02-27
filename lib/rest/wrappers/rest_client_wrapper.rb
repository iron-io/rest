require 'rest_client'

module Rest

  module Wrappers
    class RestClientExceptionWrapper < ClientError
      def initialize(ex)
        super(ex.message)
        @ex = ex
      end
    end

    class RestClientResponseWrapper
      def initialize(response)
        @response = response
      end

      def code
        @response.code
      end

      def body
        @response.body
      end

    end

    class RestClientWrapper

      def default_headers
        {}
      end

      def get(url, req_hash={})
        response = nil
        begin
          req_hash[:method] = :get
          req_hash[:url] = url
          req_hash[:headers] ||= default_headers
          req_hash[:headers][:params] = req_hash[:params] if req_hash[:params]
          #p req_hash
          r2 = RestClient::Request.execute(req_hash)
          response = RestClientResponseWrapper.new(r2)
        rescue RestClient::Exception => ex
          #p ex
          if ex.http_code == 404
            return RestClientResponseWrapper.new(ex.response)
          end
          raise RestClientExceptionWrapper.new(ex)
        end
        response
      end

      def post(url, req_hash={})
        response = nil
        begin
          req_hash[:method] = :post
          req_hash[:url] = url
          req_hash[:payload] = req_hash[:body] if req_hash[:body]
          r2 = RestClient::Request.execute(req_hash)
          response = RestClientResponseWrapper.new(r2)
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
          req_hash[:payload] = req_hash[:body] if req_hash[:body]
          r2 = RestClient::Request.execute(req_hash)
          response = RestClientResponseWrapper.new(r2)
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
          req_hash[:payload] = req_hash[:body] if req_hash[:body]
          r2 = RestClient::Request.execute(req_hash)
          response = RestClientResponseWrapper.new(r2)
            # todo: make generic exception
        rescue RestClient::Exception => ex
          raise RestClientExceptionWrapper.new(ex)
        end
        response
      end
    end

  end

end