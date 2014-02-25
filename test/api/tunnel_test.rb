require 'test_helper'

describe Forward::Api::Tunnel do

  before :each do
    FakeWeb.allow_net_connect = false
    Forward::Api.token      = 'abc123'
  end

  it "creates a tunnel and returns the attributes" do
    fake_body = { :tunnel => { :_id => '1', :subdomain => 'foo', :port => 56789 }}

    stub_api_request(:post, '/api/v2/tunnels', :body => fake_body.to_json)

    response = Forward::Api::Tunnel.create(:port => 3000)

    response[:_id].must_equal fake_body[:tunnel][:_id]
    response[:subdomain].must_equal fake_body[:tunnel][:subdomain]
    response[:port].must_equal fake_body[:tunnel][:port]
  end

  it "exits with message if create response is a resource_error" do
    fake_body = {
      :type => 'resource_error',
      :errors => {
        :base => [ 'did not work '],
        :subdomain => [ 'is invalid', 'is too short' ]
      }
    }

    stub_api_request(:post, '/api/v2/tunnels', :body => fake_body.to_json, :status => [ 422, 'Unprocessable Entity' ])

    out, err = capture_io do
      begin
        Forward::Api::Tunnel.create(:port => 3000)
      rescue SystemExit; end
    end
    out.must_match /did not work/i
    out.must_match /subdomain is invalid/i
    out.must_match /subdomain is too short/i
  end

  it "exits with message if trial has expired" do
     fake_body = {
       :type => 'trial_expired',
       :message => 'your trial has expired'
     }

     stub_api_request(:post, '/api/v2/tunnels', :body => fake_body.to_json, :status => [ 422, 'Unprocessable Entity' ])

     out, err = capture_io do
       begin
         Forward::Api::Tunnel.create(:port => 3000)
       rescue SystemExit; end
     end
     out.must_match /trial has expired/i
   end

   it "exits with message if account has been suspended" do
      fake_body = {
        :type => 'account_suspended',
        :message => 'your account has been suspended due for failed payment'
      }

      stub_api_request(:post, '/api/v2/tunnels', :body => fake_body.to_json, :status => [ 422, 'Unprocessable Entity' ])

      out, err = capture_io do
        begin
          Forward::Api::Tunnel.create(:port => 3000)
        rescue SystemExit; end
      end
      out.must_match /account has been suspended/i
    end

  it "gives a choice and closes a tunnel if limit is reached" do
     post_options = [
       { :body => { :type => 'tunnel_limit_reached', :message => 'you have reached your limit' }.to_json, :status => [ 422, 'Unprocessable Entity' ] },
       { :body => { :tunnel => { :_id => '1', :subdomain => 'foo', :port => 56789 } }.to_json }
     ]
     index_body = { :tunnels => [ { :_id => 'abc123', :hostport => 1234 }, { :_id => 'def456', :hostport => 1235 } ] }

     stub_api_request(:post, '/api/v2/tunnels', post_options)
     stub_api_request(:get, '/api/v2/tunnels', :body => index_body.to_json)
     STDIN.expects(:gets).returns('1')
     Forward::Api::Tunnel.expects(:destroy).with(index_body[:tunnels].first[:_id])

     dev_null { Forward::Api::Tunnel.create(:port => 3000) }
   end

end
