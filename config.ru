$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))

require 'rubygems'
require 'kibana'
require 'authwrapper'
require 'bundler'

Bundler.require

ENV["SIGNON_ROOT"] = "http://0.0.0.0:3000"
ENV["SIGNON_CLIENT_ID"] = "3a31c225f7e7589991477da6fcf3df7eb5a060572d32ceb91ccf4b73f51717a6"
ENV["SIGNON_CLIENT_SECRET"] ="0324d981ffd8b1422fb51a453e22b4e08255d5920e841ea4ebdfc8e29e7a1e1a"

use Rack::Session::Cookie, :secret => ENV["SECRET_KEY"]
use OmniAuth::Builder do
  provider :gds, ENV["SIGNON_CLIENT_ID"], ENV["SIGNON_CLIENT_SECRET"],
    :client_options => { :site => ENV["SIGNON_ROOT"],
                         :authorize_url => "#{ENV["SIGNON_ROOT"]}/oauth/authorize",
                         :token_url => "#{ENV["SIGNON_ROOT"]}/oauth/access_token" }
end
use AuthWrapper, :gds
run KibanaApp

