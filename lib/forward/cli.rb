module Forward
  class CLI
    BASIC_AUTH_REGEX       = /\A[^\s:]+:[^\s:]+\z/i
    CNAME_REGEX            = /\A[a-z0-9]+(?:[\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}\z/i
    SUBDOMAIN_PREFIX_REGEX = /\A[a-z0-9]{1}[a-z0-9\-]+\z/i
    USERNAME_REGEX         = PASSWORD_REGEX = /\A[^\s]+\z/i

    BANNER = <<-BANNER
    Usage: forward <port> [options]
           forward <host> [options]
           forward <host:port> [options]

    Description:

       Share a server running on localhost:port over the web by tunneling
       through Forward. A URL is created for each tunnel.

    Simple example:

      # You are developing a Rails site.

      > rails server &
      > forward 3000
        Forward created at https://mycompany.fwd.wf

    Assigning a static subdomain prefix:

      > rails server &
      > forward 3000 myapp
        Forward created at https://myapp-mycompany.fwd.wf

    Virtual Host example:

      # You are already running something on port 80 that uses
      # virtual host names.

      > forward mysite.dev
        Forward created at https://mycompany.fwd.wf

    BANNER

    # Parse non-published options and remove them from ARGV, then
    # parse published options and update the options Hash with provided
    # options and removes switches from ARGV.
    def self.parse_cli_options(args)
      Forward.log.debug("Parsing options")
      options = {}

      @opts = OptionParser.new do |opts|
        opts.banner = BANNER.gsub(/^ {6}/, '')

        opts.separator ''
        opts.separator 'Options:'

        opts.on('-a', '--auth [USER:PASS]', 'Protect this tunnel with HTTP Basic Auth.') do |credentials|
          exit_with_error("Basic Auth: bad format, expecting USER:PASS") if credentials !~ BASIC_AUTH_REGEX
          username, password  = credentials.split(':')
          options[:username] = username
          options[:password] = password
        end

        opts.on('-A', '--no-auth', 'Disable authentication on this tunnel (if a default is set in your preferences)') do |credentials|
          options[:no_auth] = true
        end

        opts.on('-c', '--cname [CNAME]', 'Allow access to this tunnel as CNAME (you will need to setup a CNAME entry on your DNS server).') do |cname|
          options[:cname] = cname.downcase
        end

        opts.on( '-h', '--help', 'Display this help.' ) do
          puts opts
          exit
        end

        opts.on('-v', '--version', 'Display version number.') do
          puts "forward #{VERSION}"
          exit
        end
      end

      @opts.parse!(args)

      options
    end

    # Returns a String file path for PWD/Forwardfile
    def self.forwardfile_path
      File.join(Dir.pwd, 'Forwardfile')
    end

    # Parse arguments from CLI and options from Forwardfile
    #
    # args - An Array of command line arguments
    #
    # Returns a Hash of options.
    def self.parse_args_and_options(args)
      options = {
        :host   => '127.0.0.1',
        :port   => 80
      }

      Forward.log.debug("Default options: `#{options.inspect}'")

      if File.exist? forwardfile_path
        options.merge!(parse_forwardfile)
        Forward.log.debug("Forwardfile options: `#{options.inspect}'")
      end

      options.merge!(parse_cli_options(args))

      forwarded, prefix = args[0..1]
      options[:subdomain_prefix] = prefix unless prefix.nil?
      options.merge!(parse_forwarded(forwarded))
      Forward.log.debug("CLI options: `#{options.inspect}'")

      options
    end

    # Parse a local Forwardfile (in the PWD) and return it as a Hash.
    # Raise an error and exit if unable to parse or result isn't a Hash.
    #
    # Returns a Hash of the options found in the Forwardfile
    def self.parse_forwardfile
      options = YAML.load_file(forwardfile_path)
      raise CLIError unless options.kind_of?(Hash)

      options.symbolize_keys
    rescue ArgumentError, SyntaxError, CLIError
      exit_with_error("Unable to parse #{forwardfile_path}")
    end

    # Parses the arguments to determine if we're forwarding a port or host
    # and validates the port or host and updates @options if valid.
    #
    # arg - A String representing the port or host.
    #
    # Returns a Hash containing the forwarded host or port
    def self.parse_forwarded(arg)
      Forward.log.debug("Forwarded: `#{arg}'")
      forwarded = {}

      if arg =~ /\A\d{1,5}\z/
        port = arg.to_i

        forwarded[:port] = port
      elsif arg =~ /\A[-a-z0-9\.\-]+\z/i
        forwarded[:host] = arg
      elsif arg =~ /\A[-a-z0-9\.\-]+:\d{1,5}\z/i
        host, port = arg.split(':')
        port       = port.to_i

        forwarded[:host] = host
        forwarded[:port] = port
      end

      forwarded
    end

    # Checks to make sure the port being set is a number between 1 and 65535
    # and exits with an error message if it's not.
    #
    # port - port number Integer
    def self.validate_port(port)
      Forward.log.debug("Validating Port: `#{port}'")
      unless port.between?(1, 65535)
        exit_with_error "Invalid Port: #{port} is an invalid port number"
      end
    end

    # Checks to make sure the username is a valid format
    # and exits with an error message if not.
    #
    # username - username String
    def self.validate_username(username)
      Forward.log.debug("Validating Username: `#{username}'")
      exit_with_error("`#{username}' is an invalid username format") unless username =~ USERNAME_REGEX
    end

    # Checks to make sure the password is a valid format
    # and exits with an error message if not.
    #
    # password - password String
    def self.validate_password(password)
      Forward.log.debug("Validating Password: `#{password}'")
      exit_with_error("`#{password}' is an invalid password format") unless password =~ PASSWORD_REGEX
    end

    # Checks to make sure the cname is in the correct format and exits with an
    # error message if it isn't.
    #
    # cname - cname String
    def self.validate_cname(cname)
      Forward.log.debug("Validating CNAME: `#{cname}'")
      exit_with_error("`#{cname}' is an invalid domain format") unless cname =~ CNAME_REGEX
    end

    # Checks to make sure the subdomain prefix is in the correct format 
    # and exits with an error message if it isn't.
    #
    # prefix - subdomain prefix String
    def self.validate_subdomain_prefix(prefix)
      Forward.log.debug("Validating Subdomain Prefix: `#{prefix}'")
      exit_with_error("`#{prefix}' is an invalid subdomain prefix format") unless prefix =~ SUBDOMAIN_PREFIX_REGEX
    end

    # Validate all options in options Hash.
    #
    # options - the options Hash
    def self.validate_options(options)
      Forward.log.debug("Validating options: `#{options.inspect}'")
      options.each do |key, value|
        next if value.nil?
        validate_method = :"validate_#{key}"
        send(validate_method, value) if respond_to?(validate_method)
      end
    end

    # Asks for the user's email and password and puts them in a Hash.
    #
    # Returns a Hash with the email and password
    def self.authenticate
      puts 'Enter your email and password'
      email    = ask('email: ').chomp
      password = ask('password: ') { |q| q.echo = false }.chomp
      Forward.log.debug("Authenticating User: `#{email}:#{password.gsub(/./, 'x')}'")

      { :email => email, :password => password }
    end

    # Parses various options and arguments, validates everything to ensure
    # we're safe to proceed, and finally passes options to the Client.
    def self.run(args)
      ::HighLine.use_color = false if Forward.windows?
      if ARGV.include?('--debug')
        Forward.debug!
        ARGV.delete('--debug')
      elsif ARGV.include?('--rdebug')
        Forward.debug_remotely!
        ARGV.delete('--rdebug')
      end

      Forward.log.debug("Starting forward v#{Forward::VERSION}")

      options = parse_args_and_options(args)

      validate_options(options)
      print_usage_and_exit if args.empty? && !File.exist?(forwardfile_path)

      Client.start(options)
    end

    # Colors an error message red and displays it.
    #
    # message - error message String
    def self.exit_with_error(message)
      Forward.log.fatal(message)
      puts HighLine.color(message, :red)
      exit 1
    end

    # Print the usage banner and Exit Code 0.
    def self.print_usage_and_exit
      puts @opts
      exit
    end

  end
end
