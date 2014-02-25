require 'test_helper'

describe Forward::Api::User do

  before :each do
    FakeWeb.allow_net_connect = false
  end

  it "retrieves the users api token and returns it" do
    fake_body = { :user => { :api_token => '123abc' } }

    stub_api_request(:post, '/api/v2/users/api_token', :body => fake_body.to_json)

    response = Api::User.api_token('guy@example.com', 'secret')
    response[:api_token].must_equal '123abc'
  end

  it "exits with message if authentication fails" do
    fake_body = { :type => 'api_error' }

    stub_api_request(:post, '/api/v2/users/api_token', :body => fake_body.to_json, :status => [ 401, 'Authentication Failed' ])

    out, err = capture_io do
      begin
        Api::User.api_token('guy@example.com', 'secret')
      rescue SystemExit; end
    end
    out.must_match /unable to authenticate/i
  end

  it "exits with message if response has errors" do
    fake_body = { :type => 'api_error' }

    stub_api_request(:post, '/api/v2/users/api_token', :body => fake_body.to_json, :status => [ 422, 'Unprocessable Entity' ])

    lambda { 
      dev_null { Api::User.api_token('guy@example.com', 'secret') }
    }.must_raise SystemExit
  end

end
