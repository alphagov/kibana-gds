$:.unshift(File.expand_path(File.dirname(__FILE__), "lib"))
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))

require 'rubygems'
require 'bundler'
require 'envvar'
require 'authwrapper'
require 'kibana'

Bundler.require

use Rack::Session::Cookie, :secret => ENV["SECRET_KEY"]
use OmniAuth::Builder do
  provider :gds, ENV["SIGNON_CLIENT_ID"], ENV["SIGNON_CLIENT_SECRET"],
    :client_options => { :site => ENV["SIGNON_ROOT"],
                         :authorize_url => "#{ENV["SIGNON_ROOT"]}/oauth/authorize",
                         :token_url => "#{ENV["SIGNON_ROOT"]}/oauth/access_token" }
end
use AuthWrapper, :gds
run KibanaApp

