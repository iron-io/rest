require_relative 'internal_client/internal_client'

module Rest

  module Wrappers
    class InternalClientExceptionWrapper < HttpError
      attr_reader :ex

      def initialize(ex)
        super(ex.response, ex.http_code)
        @ex = ex
      end
    end

    class InternalClientResponseWrapper < BaseResponseWrapper
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
        @response.headers
      end

    end

    class InternalClientWrapper < BaseWrapper

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
          r2 = Rest::InternalClient::Request.execute(req_hash)
          response = InternalClientResponseWrapper.new(r2)
        rescue Rest::InternalClient::Exception => ex
          #p ex
          #if ex.http_code == 404
          #  return InternalClientResponseWrapper.new(ex.response)
          #end
          raise InternalClientExceptionWrapper.new(ex)
        end
        response
      end

      def post(url, req_hash={})
        response = nil
        begin
          req_hash[:method] = :post
          req_hash[:url] = url
          b = req_hash[:body]
          if b
            if b.is_a?(Hash)
              b = b.to_json
            end
            req_hash[:payload] = b
          end
          r2 = Rest::InternalClient::Request.execute(req_hash)
          response = InternalClientResponseWrapper.new(r2)
        rescue Rest::InternalClient::Exception => ex
          raise InternalClientExceptionWrapper.new(ex)
        end
        response
      end

      def put(url, req_hash={})
        response = nil
        begin
          req_hash[:method] = :put
          req_hash[:url] = url
          req_hash[:payload] = req_hash[:body] if req_hash[:body]
          r2 = Rest::InternalClient::Request.execute(req_hash)
          response = InternalClientResponseWrapper.new(r2)
        rescue Rest::InternalClient::Exception => ex
          raise InternalClientExceptionWrapper.new(ex)
        end
        response
      end

      def patch(url, req_hash={})
        response = nil
        begin
          req_hash[:method] = :patch
          req_hash[:url] = url
          req_hash[:payload] = req_hash[:body] if req_hash[:body]
          r2 = Rest::InternalClient::Request.execute(req_hash)
          response = InternalClientResponseWrapper.new(r2)
        rescue Rest::InternalClient::Exception => ex
          raise InternalClientExceptionWrapper.new(ex)
        end
        response
      end


      def delete(url, req_hash={})
        response = nil
        begin
          req_hash[:method] = :delete
          req_hash[:url] = url
          req_hash[:payload] = req_hash[:body] if req_hash[:body]
          r2 = Rest::InternalClient::Request.execute(req_hash)
          response = InternalClientResponseWrapper.new(r2)
            # todo: make generic exception
        rescue Rest::InternalClient::Exception => ex
          raise InternalClientExceptionWrapper.new(ex)
        end
        response
      end
    end

  end

end
