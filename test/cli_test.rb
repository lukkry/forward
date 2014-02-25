require 'test_helper'

describe Forward::CLI do

  it 'parses a forwarded port' do
    forwarded = Forward::CLI.parse_forwarded('600')
    forwarded.has_key?(:port).must_equal true
    forwarded[:port].must_equal 600
  end

  it 'parses a forwarded host' do
    forwarded = Forward::CLI.parse_forwarded('mysite.dev')
    forwarded.has_key?(:host).must_equal true
    forwarded[:host].must_equal 'mysite.dev'
  end

  it 'parses a forwarded host and port' do
    forwarded = Forward::CLI.parse_forwarded('mysite.dev:88')
    forwarded.has_key?(:host).must_equal true
    forwarded.has_key?(:port).must_equal true
    forwarded[:host].must_equal 'mysite.dev'
    forwarded[:port].must_equal 88
  end

  it 'exits if username is invalid' do
    [ 'foo ', ' asdfasdf ', 'fooo bar' ].each do |username|
      lambda {
        dev_null { Forward::CLI.validate_username(username) }
      }.must_raise SystemExit
    end
  end

  it 'validates a good username' do
    [ 'foo', 'asdflkj3r&)(#@#)', 'DF#R::#SFSDF' ].each do |username|
      Forward::CLI.validate_username(username).must_be_nil
    end
  end

  it 'exits if password is invalid' do
    [ 'foo ', ' asdfasdf ', 'fooo bar' ].each do |password|
      lambda {
        dev_null { Forward::CLI.validate_password(password) }
      }.must_raise SystemExit
    end
  end

  it 'validates a good password' do
    [ 'foo', 'asdflkj3r&)(#@#)', 'DF#R::#SFSDF' ].each do |password|
      Forward::CLI.validate_password(password).must_be_nil
    end
  end

  it 'parses a Forwardfile' do
    hash_to_forwardfile(:auth => 'username:password')

    options = Forward::CLI.parse_forwardfile
    options.has_key?(:auth).must_equal true
  end

  it 'exits if a Forwardfile does not parse to a Hash' do
    hash_to_forwardfile('username:password')

    lambda {
      dev_null { Forward::CLI.parse_forwardfile }
    }.must_raise SystemExit
  end

  it 'overloads Forwardfile options via commandline options' do    
    hash_to_forwardfile(
      :port             => 8000, 
      :username         => 'username', 
      :password         => 'password', 
      :subdomain_prefix => 'foo'
    )
    args    = [ '3000', '-a', 'example:secret', 'bar' ]
    options = Forward::CLI.parse_args_and_options(args)

    options[:port].must_equal 3000
    options[:username].must_equal 'example'
    options[:password].must_equal 'secret'
    options[:subdomain_prefix].must_equal 'bar'
  end

  it 'doesnt exit on valid ports' do
    Forward::CLI.validate_port(69).must_be_nil
    Forward::CLI.validate_port(3000).must_be_nil
    Forward::CLI.validate_port(65535).must_be_nil
  end

  it 'validates port and exits if invalid' do
    [ 0, 65536 ].each do |port|
      lambda {
        dev_null { Forward::CLI.validate_port(port) }
      }.must_raise SystemExit
    end
  end

  it 'doesnt exit on valid cnames' do
    [ 'foo.com', 'whatever-foo.com', 'www.foo.com', 'asdf.asdf.asdf.com' ].each do |cname|
      Forward::CLI.validate_cname(cname).must_be_nil
    end
  end

  it 'validates cname and exits if invalid' do
    [ 'whatever', 'asdfasdf.', '-asdf', 'adsf#$).com' ].each do |cname|
      lambda {
        dev_null { Forward::CLI.validate_cname(cname) }
      }.must_raise SystemExit
    end
  end

  it 'doesnt exit on valid subdomains prefix' do
    [ 'foo', 'whatever-foo', 'asdf40' ].each do |subdomain|
      Forward::CLI.validate_subdomain_prefix(subdomain).must_be_nil
    end
  end

  it 'validates subdomain prefix and exits if invalid' do
    [ '-asdf', 'adsf#$)' ].each do |subdomain|
      lambda {
        dev_null { Forward::CLI.validate_subdomain_prefix(subdomain) }
      }.must_raise SystemExit
    end
  end

end

def hash_to_forwardfile(hash)
  yaml = YAML.dump(hash)
  File.open('Forwardfile', 'w') { |f| f.write(yaml) }
end
