require 'rubygems'
require 'bundler'

Bundler.require

require ::File.expand_path('../lib/authwrapper',  __FILE__)

if ENV['SECRET_KEY'] == nil or ENV['SECRET_KEY'] == ''
  raise 'SECRET_KEY environment variable must be set'
end

use Rack::Session::Cookie,
  :key => 'rack.kibana_session',
  :secret => ENV["SECRET_KEY"],
  :expire_after => 20 * 60 * 60 # gds-sso default expiry is 20h
use OmniAuth::Builder do
  provider :gds, ENV["SIGNON_CLIENT_ID"], ENV["SIGNON_CLIENT_SECRET"],
    :client_options => { :site => ENV["SIGNON_ROOT"],
                         :authorize_url => "#{ENV["SIGNON_ROOT"]}/oauth/authorize",
                         :token_url => "#{ENV["SIGNON_ROOT"]}/oauth/access_token" }
end
use AuthWrapper, :gds

system("/usr/local/bin/kibana-docker")
