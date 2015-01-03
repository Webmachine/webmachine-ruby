﻿require 'webmachine/adapter'
require 'webmachine/constants'
require 'set'
require 'reel'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'

module Webmachine
  module Adapters
    class Reel < Adapter
      # Used to override default Reel server options (useful in testing)
      DEFAULT_OPTIONS = {}

      def run
        @options = DEFAULT_OPTIONS.merge({
          :port => application.configuration.port,
          :host => application.configuration.ip
        }).merge(application.configuration.adapter_options)

        if extra_verbs = application.configuration.adapter_options[:extra_verbs]
          @extra_verbs = Set.new(extra_verbs.map(&:to_s).map(&:upcase))
        else
          @extra_verbs = Set.new
        end

        if @options[:ssl]
          unless @options[:ssl][:cert] && @options[:ssl][:key]
            raise ArgumentError, 'Certificate or Private key missing for HTTPS Server'
          end
          @server = ::Reel::Server::HTTPS.supervise(@options[:host], @options[:port], @options[:ssl], &method(:process))
        else
          @server = ::Reel::Server::HTTP.supervise(@options[:host], @options[:port], &method(:process))
        end

        Celluloid::Actor.join(@server)
      end

      def process(connection)
        connection.each_request do |request|
          # Users of the adapter can configure a custom WebSocket handler
          if request.websocket?
            if handler = @options[:websocket_handler]
              handler.call(request.websocket)
            else
              # Pretend we don't know anything about the WebSocket protocol
              # FIXME: This isn't strictly what RFC 6455 would have us do
              request.respond :bad_request, "WebSockets not supported"
            end

            next
          end

          # Optional support for e.g. WebDAV verbs not included in Webmachine's
          # state machine. Do the "Railsy" thing and handle them like POSTs
          # with a magical parameter
          if @extra_verbs.include?(request.method)
            method = POST_METHOD
            param  = "_method=#{request.method}"
            uri    = request_uri(request.url, request.headers, param)
          else
            method = request.method
            uri    = request_uri(request.url, request.headers)
          end

          wm_headers  = Webmachine::Headers[request.headers.dup]
          wm_request  = Webmachine::Request.new(method, uri, wm_headers, request.body)

          wm_response = Webmachine::Response.new
          application.dispatcher.dispatch(wm_request, wm_response)

          fixup_headers(wm_response)
          fixup_callable_encoder(wm_response)

          request.respond ::Reel::Response.new(wm_response.code,
                                               wm_response.headers,
                                               wm_response.body)
        end
      end

      def request_uri(path, headers, extra_query_params = nil)
        path_parts = path.split('?')
        uri_hash = {path: path_parts.first}
        uri_hash[:query] = path_parts.last if path_parts.length == 2

        if extra_query_params
          if uri_hash[:query]
            uri_hash[:query] << "&#{extra_query_params}"
          else
            uri_hash[:query] = extra_query_params
          end
        end

        URI::HTTP.build(uri_hash)
      end

      def fixup_headers(response)
        response.headers.each do |key, value|
          if value.is_a?(Array)
            response.headers[key] = value.join(", ")
          end
        end
      end

      def fixup_callable_encoder(response)
        if response.body.is_a?(Streaming::CallableEncoder)
          response.body = [response.body.call]
        end
      end
    end
  end
end
