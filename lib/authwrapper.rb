require "sinatra/base"

class AuthWrapper < Sinatra::Base

  def initialize(app, provider, redirect_to="/")
    super(app)
    @provider = provider
    @redirect_to = redirect_to

    %w(get post).each do |method|
      self.class.send(method, callback_path) do
        if request.env["omniauth.auth"]
          session[:authenticated] = true
        end

        redirect @redirect_to
      end
    end
  end

  def callback_path
    "/auth/#{@provider}/callback"
  end

  before do
    # Don't protect callback path
    return if request.path == callback_path

    if session[:authenticated]
      # Don't protect logout path
      return if request.path == "/auth/logout"

      # Otherwise proceed to next app in stack
      forward
    else
      redirect "/auth/#{@provider}"
    end
  end

  get "/auth/logout" do
    session[:authenticated] = false
    redirect @redirect_to
  end

end

