require 'test_helper'

describe Forward::Tunnel do

  it "create a tunnel instance" do
    tunnel_response = {
      :_id => '1234',
      :subdomain => 'foo',
      :cname => 'foo.bar.com',
      :vhost => '127.0.0.1',
      :hostport => '3000',
      :port => 20000,
      :tunneler_public => 'test.forwardhq.com',
      :timeout => 0
    }

    Forward::Api::Tunnel.expects(:create).returns(tunnel_response)
    tunnel = Forward::Tunnel.new

    tunnel.id.must_equal tunnel_response[:_id]
    tunnel.subdomain.must_equal tunnel_response[:subdomain]
    tunnel.cname.must_equal tunnel_response[:cname]
    tunnel.vhost.must_equal tunnel_response[:vhost]
    tunnel.hostport.must_equal tunnel_response[:hostport]
    tunnel.port.must_equal tunnel_response[:port]
    tunnel.tunneler.must_equal tunnel_response[:tunneler_public]
    tunnel.timeout.must_equal tunnel_response[:timeout]
  end
end
