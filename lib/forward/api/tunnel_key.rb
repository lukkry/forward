module Forward
  module Api
    class TunnelKey < Resource

      def self.create
        resource     = TunnelKey.new(:create)
        resource.uri = '/api/v2/tunnel_keys'

        response = resource.post

        response[:private_key]
      rescue
        Forward::Client.cleanup_and_exit!
      end

    end
  end
end
