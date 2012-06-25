$LOAD_PATH << File.expand_path("..", __FILE__)
$LOAD_PATH << File.expand_path("../../lib", __FILE__)

require 'rubygems'
require 'webmachine'
require 'rspec'

RSpec.configure do |config|
  config.mock_with :rspec
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true
  if defined?(::Java)
    config.seed = Time.now.utc
  else
    config.order = :random
  end
end

# For use in specs that need a fully initialized resource
shared_context "default resource" do
  let(:method) { 'GET' }
  let(:uri) { URI.parse("http://localhost/") }
  let(:headers) { Webmachine::Headers.new }
  let(:body) { "" }
  let(:request) { Webmachine::Request.new(method, uri, headers, body) }
  let(:response) { Webmachine::Response.new }

  let(:resource_class) do
    Class.new(Webmachine::Resource) do
      def to_html
        "<html><body>Hello, world!</body></html>"
      end
    end
  end
  let(:resource) { resource_class.new(request, response) }
end
