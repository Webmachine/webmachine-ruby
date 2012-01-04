require 'webmachine/decision/helpers'
require 'webmachine/decision/fsm'
require 'webmachine/translation'

module Webmachine
  module Decision
    # Implements the finite-state machine described by the Webmachine
    # sequence diagram.
    class FSM
      include Flow
      include Helpers
      include Translation

      attr_reader :resource, :request, :response, :metadata

      def initialize(resource, request, response)
        @resource, @request, @response = resource, request, response
        @metadata = {}
      end

      # Processes the request, iteratively invoking the decision methods in {Flow}.
      def run
        state = Flow::START
        loop do
          response.trace << state
          result = send(state)
          case result
          when Fixnum # Response code
            respond(result)
            break
          when Symbol # Next state
            state = result
          else # You bwoke it
            raise InvalidResource, t('fsm_broke', :state => state, :result => result.inspect)
          end
        end
      rescue MalformedRequest => malformed
        Webmachine.render_error(400, request, response, :message => malformed.message)
        respond(400)
      rescue => e # Handle all exceptions without crashing the server
        error_response(e, state)
      end

      private
      def respond(code, headers={})
        response.headers.merge!(headers)
        end_time = Time.now
        case code
        when 404
          Webmachine.render_error(code, request, response)
        when 304
          response.headers.delete('Content-Type')
          add_caching_headers
        end
        response.code = code
        resource.finish_request
        # TODO: add logging/tracing
      end

      # Renders a 500 error by capturing the exception information.
      def error_response(exception, state)
        response.error = [exception.message, exception.backtrace].flatten.join("\n    ")
        response.end_state = state
        Webmachine.render_error(500, request, response)
        respond(500)
      end

    end # class FSM
  end # module Decision
end # module Webmachine
