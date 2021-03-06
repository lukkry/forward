require 'base64'
require 'json'
require 'logger'
require 'openssl'
require 'optparse'
require 'rbconfig'
require 'stringio'
require 'uri'

require 'highline/import'
require 'net/ssh'

require 'forward/core_extensions'

require 'forward/error'
require 'forward/api'
require 'forward/config'
require 'forward/tunnel'
require 'forward/client'
require 'forward/cli'
require 'forward/version'

module Forward
  DEFAULT_SSL      = true
  DEFAULT_SSH_PORT = 22
  DEFAULT_SSH_USER = 'tunnel'

  # Returns either a ssh user set in the environment or a set default.
  #
  # Returns a String containing the ssh user.
  def self.ssh_user
    ENV['FORWARD_SSH_USER'] || DEFAULT_SSH_USER
  end

  # Returns either a ssh port set in the environment or a set default.
  #
  # Returns a String containing the ssh port.
  def self.ssh_port
    ENV['FORWARD_SSH_PORT'] || DEFAULT_SSH_PORT
  end

  def self.windows?
    RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
  end

  def self.config=(config)
    @config = config
  end

  def self.config
    @config
  end

  def self.client=(client)
    @client = client
  end

  def self.client
    @client
  end

  def self.debug!
    @logdev   = STDOUT
    @debug    = true
    log.level = Logger::DEBUG
  end

  def self.debug?
    @debug
  end

  def self.stringio_log
    @stringio_log ||= StringIO.new
  end

  def self.debug_remotely!
    @logdev         = stringio_log
    @debug          = true
    @debug_remotely = true
    log.level       = Logger::DEBUG
  end

  def self.debug_remotely?
    @debug_remotely ||= false
  end

  def self.logdev
    @logdev ||= (windows? ? 'NUL:' : '/dev/null')
  end

  def self.logger
    @log ||= Logger.new(logdev)
  end

  def self.log
    logger
  end

  # Returns a string representing a detailed client version.
  #
  # Returns a String representing the client.
  def self.client_string
    os     = RbConfig::CONFIG['host_os']
    engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'

    "[#{os}]::[#{engine}-#{RUBY_VERSION}]::[ruby-client-#{Forward::VERSION}]"
  end
end
