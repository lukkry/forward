module Forward
  module Api
    class User < Resource

      def self.api_token(email, password)
        resource     = User.new(:api_token)
        resource.uri = '/api/v2/users/api_token'
        params       = { :email => email, :password => password }

        user      = resource.post(params)[:user].symbolize_keys
        user[:id] = user.delete(:_id)

        user
      rescue ResourceError => e
        Forward::Client.cleanup_and_exit!('Unable to authenticate with email and password')
      end

    end
  end
end
