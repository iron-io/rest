require 'net/http/persistent'

module Rest

  module Wrappers
    class NetHttpPersistentExceptionWrapper < ClientError
      def initialize(ex)
        super(ex.message)
        @ex = ex
      end
    end

    class NetHttpPersistentResponseWrapper < BaseResponseWrapper
      def initialize(response)
        @response = response

        if response.header['content-encoding'].eql?('gzip')
          Rest.logger.debug 'GZIPPED'

          if response.body
            sio = StringIO.new(response.body)
            gz = Zlib::GzipReader.new(sio)
            page = gz.read()
            @body = page
          else
            @body = nil
          end

        end
      end

      def code
        @response.code.to_i
      end

      def body
        @body || @response.body
      end

      # In case for some reason you want the unencoded body
      def body_raw
        @response.body
      end

      def headers_orig
        @response.to_hash
      end

    end

    class NetHttpPersistentWrapper < BaseWrapper

      attr_reader :http

      def initialize(client)
        @client = client
        @http = Net::HTTP::Persistent.new('rest_gem')
        @http.proxy = URI(@client.options[:http_proxy]) if @client.options[:http_proxy]
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      def default_headers
        {
            #"Accept-Encoding" => "gzip, deflate",
            #"Accept" => "*/*; q=0.5, application/xml"
        }
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
        r = nil
        begin

          uri = URI(url)
          #p uri
          #p uri.path
          #p uri.request_uri
          #puts "query: " + uri.query.inspect
          #puts "fragment: " + uri.fragment.inspect
          append_query_params(req_hash, uri)
          #p uri.request_uri
          post = Net::HTTP::Get.new fix_path(uri.request_uri)
          add_headers(post, req_hash, default_headers)
          response = http.request uri, post
          if @client.logger.debug?
            @client.logger.debug "Response class: #{response.class.name}"
            @client.logger.debug "Response headers: #{response.header.to_hash.inspect}"
          end

          r = NetHttpPersistentResponseWrapper.new(response)
          case response
            when Net::HTTPClientError, Net::HTTPServerError
              raise Rest::HttpError.new(r, r.code.to_i)
          end
          #  when Net::HTTPRedirection
          #    @client.logger.debug "moved to #{response['location']}"
          #    response = get(response['location'], req_hash, {limit: options[:limit]-1})
          #  when Net::HTTPMovedPermanently
          #    @client.logger.debug "moved to #{response['location']}"
          #    response = get(response['location'], req_hash, {limit: options[:limit]-1})
          #end
          #rescue Net::HTTPClientError, Net::HTTPServerError => ex
          #  raise NetHttpPersistentExceptionWrapper.new(ex)
          #rescue Net::HTTPServerError => ex
          #  if ex.code == 404
          #    return NetHttpPersistentResponseWrapper.new(ex)
          #  end
          #  raise NetHttpPersistentExceptionWrapper.new(ex)
        end
        r
      end

      def append_query_params(req_hash, uri)
        if req_hash[:params]
          new_q = URI.encode_www_form(req_hash[:params])
          if uri.query
            new_q = uri.query + "&" + new_q
          end
          #puts "new_q: " + new_q
          uri.query = new_q
        end
      end

      def fix_path(path)
        return "/" if path.nil? || path == ""
        path
      end


      def post(url, req_hash={})
        r = nil
        uri = URI(url)
        append_query_params(req_hash, uri)
        post = Net::HTTP::Post.new fix_path(uri.request_uri)
        add_headers(post, req_hash, default_headers)
        post.body = stringed_body(req_hash[:body]) if req_hash[:body]
        post.set_form_data req_hash[:form_data] if req_hash[:form_data]
        Rest.logger.debug "POST request to #{uri}. body: #{post.body}"
        response = http.request uri, post
        r = NetHttpPersistentResponseWrapper.new(response)
        case response
          when Net::HTTPClientError, Net::HTTPServerError
            raise Rest::HttpError.new(r, r.code.to_i)
        end
        r
      end

      def stringed_body(body)
        return nil unless body
        if body.is_a?(Hash)
          return body.to_json
        end
        body
      end

      def put(url, req_hash={})
        r = nil
        uri = URI(url)
        append_query_params(req_hash, uri)
        post = Net::HTTP::Put.new fix_path(uri.request_uri)
        add_headers(post, req_hash, default_headers)
        post.body = stringed_body(req_hash[:body]) if req_hash[:body]
        response = http.request uri, post
        r = NetHttpPersistentResponseWrapper.new(response)
        case response
          when Net::HTTPClientError, Net::HTTPServerError
            raise Rest::HttpError.new(r, r.code.to_i)
        end
        r
      end

      def patch(url, req_hash={})
        r = nil
        uri = URI(url)
        append_query_params(req_hash, uri)
        post = Net::HTTP::Patch.new fix_path(uri.request_uri)
        add_headers(post, req_hash, default_headers)
        post.body = stringed_body(req_hash[:body]) if req_hash[:body]
        response = http.request uri, post
        r = NetHttpPersistentResponseWrapper.new(response)
        case response
          when Net::HTTPClientError, Net::HTTPServerError
            raise Rest::HttpError.new(r, r.code.to_i)
        end
        r
      end

      def delete(url, req_hash={})
        r = nil
        uri = URI(url)
        append_query_params(req_hash, uri)
        post = Net::HTTP::Delete.new fix_path(uri.request_uri)
        add_headers(post, req_hash, default_headers)
        post.body = stringed_body(req_hash[:body]) if req_hash[:body]
        response = http.request uri, post
        r = NetHttpPersistentResponseWrapper.new(response)
        case response
          when Net::HTTPClientError, Net::HTTPServerError
            raise Rest::HttpError.new(r, r.code.to_i)
        end
        r
      end

      def close
        http.shutdown
      end
    end

  end

end
