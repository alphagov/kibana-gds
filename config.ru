require 'rubygems'
require 'bundler'

Bundler.require

require ::File.expand_path('../envvar',  __FILE__)
require ::File.expand_path('../lib/authwrapper',  __FILE__)
require 'kibana/rack'

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

Kibana.configure do |config|
  config.elasticsearch_host = ENV["ES_HOST"]
  config.kibana_dashboards_path = File.expand_path('../dashboards', __FILE__)
end

map('/kibana') { run Kibana::Rack::Web }
