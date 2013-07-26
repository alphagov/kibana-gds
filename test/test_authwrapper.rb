require_relative "../lib/authwrapper"
require "omniauth"
require "omniauth-gds"
require "test/unit"
require "rack/test"

ENV["RACK_ENV"] = "test"

OmniAuth.config.test_mode = true

class TestApp < Sinatra::Base
  get "/bar" do
    "Got through to TestApp"
  end
end

class AuthWrapperTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Rack::Builder.app do
      use Rack::Session::Cookie, :secret => "TEST"
      use OmniAuth::Builder do
        provider :gds
      end
      use AuthWrapper, :gds, "/bar"
      run TestApp
    end
  end

  def test_redirects_to_omniauth_when_unauthorized
    get "/bar"
    assert last_response.redirect?
    assert_equal "http://example.org/auth/gds", last_response["Location"]
  end

  def test_failure_without_signin_permission
    get "/bar"
    # Follow redirect to auth provider
    follow_redirect!
    # Follow redirect to callback
    follow_redirect!
    assert last_response.redirect?
    assert_equal "http://example.org/auth/unauthorized", last_response["Location"]
  end

  def test_auth_failure
    get "/auth/failure"
    assert_equal 401, last_response.status
    assert_equal "Authentication failure: unknown cause\n", last_response.body
  end

  def test_auth_failure_with_custom_message
    get "/auth/failure?message=#{CGI.escape("terrible pain in all the diodes down my left side")}"
    assert_equal 401, last_response.status
    assert_equal "Authentication failure: terrible pain in all the diodes down my left side\n", last_response.body
  end

  def test_auth_failure_with_custom_message_gets_escaped
    message = 'invalid_credentials"><script> alert(0)</script>&strategy=gds'
    get "/auth/failure?message=#{CGI.escape(message)}"
    assert_equal 401, last_response.status
    assert_equal "Authentication failure: invalid_credentials&quot;&gt;&lt;script&gt; alert(0)&lt;/script&gt;&amp;strategy=gds\n", last_response.body
  end

  def test_success_with_signin_permission
    OmniAuth.config.add_mock(:gds, {:extra => {:permissions => ["signin"]}})
    get "/bar"
    # Follow redirect to auth provider
    follow_redirect!
    # Follow redirect to callback
    follow_redirect!
    assert last_response.redirect?
    assert_equal "http://example.org/bar", last_response["Location"]
    # Follow redirect to the page I requested in the first place
    follow_redirect!
    assert last_response.ok?
    assert_equal "Got through to TestApp", last_response.body
  end
end
