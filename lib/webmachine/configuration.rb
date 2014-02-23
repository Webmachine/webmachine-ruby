module Webmachine
  # A simple configuration container for items that are used across
  # multiple web server adapters. Typically set using
  # {Webmachine::configure}. If not set by your application, the
  # defaults will be filled in when {Webmachine::run} is called.
  # @attr [String] ip the interface to bind to, defaults to "0.0.0.0"
  #    (all interfaces)
  # @attr [Fixnum] port the port to bind to, defaults to 8080
  # @attr [Symbol] adapter the adapter to use, defaults to :WEBrick
  # @attr [Hash] adapter_options adapter-specific options, defaults to {}
  # @attr [Boolean] runs_behind_proxy whether Webmachine runs behind a proxy or not, defaults to false
  # @attr [Array] trusted_headers a list of trusted headers when running behind a proxy, defaults to []
  Configuration = Struct.new(:ip, :port, :adapter, :adapter_options, :runs_behind_proxy, :trusted_headers)

  # @return [Configuration] the default configuration
  def Configuration.default
    new("0.0.0.0", 8080, :WEBrick, {}, false, [])
  end

  # Yields the current configuration to the passed block.
  # @yield [config] a block that will modify the configuration
  # @yieldparam [Configuration] config the adapter configuration
  # @return self
  # @see Application#configure
  def self.configure(&block)
    application.configure(&block)
    self
  end

  # @return [Configuration] the current configuration
  # @see Application#configuration
  def self.configuration
    application.configuration
  end

  # Sets the current configuration
  # @param [Configuration] configuration the new config
  # @see Application#configuration=
  def self.configuration=(configuration)
    application.configuration = configuration
  end
end # Webmachine
