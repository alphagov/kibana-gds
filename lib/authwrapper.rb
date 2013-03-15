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

  def served_paths
    if session[:authenticated]
      ["/auth/logout"]
    else
      ["/auth/failure", callback_path]
    end
  end

  before do
    # Don't protect paths that the auth wrapper serves
    return if served_paths.include? request.path

    if session[:authenticated]
      forward
    else
      redirect "/auth/#{@provider}"
    end
  end

  get "/auth/logout" do
    session[:authenticated] = false
    redirect @redirect_to
  end

  get "/auth/failure" do
    throw(:halt, [401, "Not authorized\n"])
  end

end

