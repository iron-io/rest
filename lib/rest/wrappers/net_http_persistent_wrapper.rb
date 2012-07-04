require 'net/http/persistent'

module Rest

  module Wrappers
    class NetHttpPersistentExceptionWrapper < ClientError
      def initialize(ex)
        super(ex.message)
        @ex = ex
      end
    end

    class NetHttpPersistentResponseWrapper
      def initialize(response)
        @response = response
      end

      def code
        @response.code.to_i
      end

      def body
        @response.body
      end

    end

    class NetHttpPersistentWrapper < BaseWrapper

      attr_reader :http

      def initialize(client)
        @client = client
        @http = Net::HTTP::Persistent.new 'rest_gem'
      end

      def default_headers
        {}
      end

      def add_headers(post, req_hash, default_headers)
        headers = {}
        headers.merge!(default_headers)
        headers.merge!(req_hash[:headers]) if req_hash[:headers]
        headers.each_pair do |k, v|
          post[k] = v
        end
      end

      def get(url, req_hash={}, options={})
        @client.logger.debug "limit #{options[:limit]}"
        options[:limit] ||= 10
        response = nil
        begin

          uri = URI(url)
          #p uri
          #p uri.path
          post = Net::HTTP::Get.new fix_path(uri.path)
          add_headers(post, req_hash, default_headers)
          response = http.request uri, post
          @client.logger.debug response.class.name
          case response
            when Net::HTTPRedirection
              @client.logger.debug "moved to #{response['location']}"
              response = get(response['location'], req_hash, {limit: options[:limit]-1})
            when Net::HTTPMovedPermanently
              @client.logger.debug "moved to #{response['location']}"
              response = get(response['location'], req_hash, {limit: options[:limit]-1})
          end
          response = NetHttpPersistentResponseWrapper.new(response)
        rescue Net::HTTPClientError => ex
          if ex.code == 404
            return NetHttpPersistentResponseWrapper.new(ex)
          end
          raise NetHttpPersistentExceptionWrapper.new(ex)
        rescue Net::HTTPServerError => ex
          if ex.code == 404
            return NetHttpPersistentResponseWrapper.new(ex)
          end
          raise NetHttpPersistentExceptionWrapper.new(ex)
        end
        response
      end

      def fix_path(path)
        return "/" if path.nil? || path == ""
        path
      end


      def post(url, req_hash={})
        response = nil
        begin
          uri = URI(url)
          post = Net::HTTP::Post.new uri.path
          add_headers(post, req_hash, default_headers)
          post.body = stringed_body(req_hash[:body]) if req_hash[:body]
          response = http.request uri, post
          response = NetHttpPersistentResponseWrapper.new(response)
        rescue Net::HTTPClientError => ex
          raise NetHttpPersistentExceptionWrapper.new(ex)
        rescue Net::HTTPServerError => ex
          raise NetHttpPersistentExceptionWrapper.new(ex)
        end
        response
      end

      def stringed_body(body)
        return nil unless body
        if body.is_a?(Hash)
          return body.to_json
        end
        body
      end

      def put(url, req_hash={})
        response = nil
        begin
          uri = URI(url)
          post = Net::HTTP::Put.new uri.path
          add_headers(post, req_hash, default_headers)
          post.body = stringed_body(req_hash[:body]) if req_hash[:body]
          response = http.request uri, post
          response = NetHttpPersistentResponseWrapper.new(response)
        rescue Net::HTTPClientError => ex
          raise NetHttpPersistentExceptionWrapper.new(ex)
        rescue Net::HTTPServerError => ex
          raise NetHttpPersistentExceptionWrapper.new(ex)
        end
        response
      end

      def delete(url, req_hash={})
        response = nil
        begin
          uri = URI(url)
          post = Net::HTTP::Delete.new uri.path
          add_headers(post, req_hash, default_headers)
          response = http.request uri, post
          response = NetHttpPersistentResponseWrapper.new(response)
        rescue Net::HTTPClientError => ex
          raise NetHttpPersistentExceptionWrapper.new(ex)
        rescue Net::HTTPServerError => ex
          raise NetHttpPersistentExceptionWrapper.new(ex)
        end
        response
      end

      def close
        http.shutdown
      end
    end

  end

end
