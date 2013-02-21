require 'rubygems'
require 'bundler'

Bundler.require

require ::File.expand_path('../envvar',  __FILE__)
require ::File.expand_path('../lib/authwrapper',  __FILE__)
require 'kibana'

use Rack::Session::Cookie, :secret => ENV["SECRET_KEY"]
use OmniAuth::Builder do
  provider :gds, ENV["SIGNON_CLIENT_ID"], ENV["SIGNON_CLIENT_SECRET"],
    :client_options => { :site => ENV["SIGNON_ROOT"],
                         :authorize_url => "#{ENV["SIGNON_ROOT"]}/oauth/authorize",
                         :token_url => "#{ENV["SIGNON_ROOT"]}/oauth/access_token" }
end
use AuthWrapper, :gds
run KibanaApp
