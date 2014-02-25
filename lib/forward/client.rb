module Forward
  class Client
    attr_reader :config
    attr_reader :options
    attr_accessor :tunnel

    def initialize(options = {})
      @options = options
      @config  = Config.create_or_load
    end

    def basic_auth?
      @options[:username] && @options[:password]
    end

   # Sets up a Tunnel instance and adds it to the Client.
    def setup_tunnel
      Forward.log.debug('Setting up tunnel')
      @tunnel = Forward::Tunnel.new(self.options)
      if @tunnel.id
        @tunnel.poll_status
      else
        Forward::Client.cleanup_and_exit!('Unable to create a tunnel. If this continues contact support@forwardhq.com')
      end
      Forward.log.debug("Tunnel setup: #{@tunnel.inspect}")

      @tunnel
    end

    # The options Hash used by Net::SSH.
    #
    # Returns a Hash of options.
    def ssh_options
      {
        :port       => Forward.ssh_port,
        :keys_only  => true,
        :keys       => [],
        :key_data   => [ @config.private_key ],
        :encryption => 'blowfish-cbc',
        :logger     => Forward.logger,
        :verbose    => Forward.debug? ? :debug : :warn
      }
    end

    def self.current
      @client
    end

    def self.watch_session(session)
      @client.tunnel.inactive_for = 0 if session.busy?(true)
      true
    end

    def self.forwarding_message(tunnel)
      remote = HighLine.color("https://#{@tunnel.subdomain}.fwd.wf", :underline)

      unless tunnel.cname.nil? || tunnel.cname.empty?
        remote << ' and '<< HighLine.color("http://#{@tunnel.cname}", :underline)
      end

      if !tunnel.vhost.nil? && tunnel.vhost !~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
        local = tunnel.vhost
        local << " port #{tunnel.hostport}" unless tunnel.hostport.to_i == 80
      else
        local = "port #{tunnel.hostport}"
      end

      "Forwarding #{local} to #{remote}\nCtrl-C to stop forwarding"
    end

    def self.start(options = {})
      Forward.log.debug('Starting client')
      trap(:INT) { cleanup_and_exit!('closing tunnel and exiting...') }

      Forward.client = @client = Client.new(options)
      @tunnel        = @client.setup_tunnel
      @session       = Net::SSH.start(@tunnel.tunneler, Forward.ssh_user, @client.ssh_options)

      Forward.log.debug("Starting remote forward at #{@tunnel.subdomain}.fwd.wf")
      puts forwarding_message(@tunnel)

      @session.forward.remote(@tunnel.hostport, @tunnel.host, @tunnel.port)
      @session.loop { watch_session(@session) }

    rescue Net::SSH::AuthenticationFailed => e
      Forward.log.fatal("SSH Auth failed `#{e}'")
      cleanup_and_exit!("Authentication failed, try deleting `#{Forward::Config.config_path}' and giving it another go. If the problem continues, contact support@forwardhq.com")
    rescue => e
      Forward.log.fatal("#{e.message}\n#{e.backtrace.join("\n")}")
      cleanup_and_exit!("You've been disconnected...")
    end

    def self.cleanup_and_exit!(message = 'exiting...')
      puts message.chomp

      @session.close if @session && !@session.closed?

      Forward.log.debug('Exiting')
      send_debug_log if Forward.debug_remotely?
    ensure
      Thread.main.exit
    end

    def self.send_debug_log
      log = Forward.stringio_log.string
      Forward::Api::ClientLog.create(log)
    end
  end
end
