module Forward
  module Api
    class Tunnel < Resource

      def self.create(options = {})
        resource     = Tunnel.new(:create)
        resource.uri = '/api/v2/tunnels'
        params       = {
          :hostport => options[:port],
          :vhost    => options[:host],
          :client   => Forward.client_string,
        }
        
        params[:subdomain] = options[:subdomain_prefix] if options.has_key?(:subdomain_prefix)
        [ :cname, :username, :password, :no_auth ].each do |param|
          params[param] = options[param] if options.has_key?(param)
        end

        resource.post(params)[:tunnel].symbolize_keys
      rescue ResourceError => e
        error_on_create(e, options)
      end

      def self.index
        resource     = Tunnel.new(:index)
        resource.uri = "/api/v2/tunnels"

        resource.get[:tunnels]
      end

      def self.show(id)
        resource     = Tunnel.new(:show)
        resource.uri = "/api/v2/tunnels/#{id}"

        resource.get[:tunnel].symbolize_keys
      rescue Forward::Api::ResourceNotFound
        nil
      end

      private

      def self.ask_to_destroy(message, options)
        tunnels = index

        puts message
        choose do |menu|
          menu.prompt = "Choose a tunnel from the list to close or `q' to exit forward "

          tunnels.each do |tunnel|
            text = "Forwarding port #{tunnel['hostport']}"
            menu.choice(text) { destroy_and_create(tunnel['_id'], options) }
          end
          menu.hidden('quit') { Forward::Client.cleanup_and_exit! }
          menu.hidden('exit') { Forward::Client.cleanup_and_exit! }
        end
      end

      def self.destroy_and_create(id, options)
        Forward.log.debug("Destroying tunnel: #{id}")
        destroy(id)
        puts "tunnel removed, now we're creating a new one"
        create(options)
      end

      def self.error_on_create(error, options)
        Forward.log.debug("An error occured creating tunnel:\n#{error.inspect}")

        if error.type == 'tunnel_limit_reached'
          Forward.log.debug('Tunnel limit reached')
          ask_to_destroy(error.api_message, options)
        elsif error.type =~ /(?:account_suspended|trial_expired)/i
          Forward::Client.cleanup_and_exit!(error.api_message)
        else
          message = "We were unable to create your tunnel for the following reasons: \n"
          error.errors.each do |key, value|
            if key == 'base'
              message << " #{value.join(', ')}\n"
            else
              value.each { |m| message << " #{key} #{m}\n"}
            end
          end
          Forward::Client.cleanup_and_exit!(message)
        end
      end

    end
  end
end
