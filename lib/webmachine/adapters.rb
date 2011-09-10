require 'webmachine/adapters/webrick'

module Webmachine
  # Contains classes and modules that connect Webmachine to Ruby
  # application servers.
  module Adapters
    autoload :Mongrel, 'webmachine/adapters/mongrel'
  end
end
