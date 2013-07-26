require "sinatra/base"

class AuthWrapper < Sinatra::Base

  def initialize(app, provider, redirect_to="/")
    super(app)
    @provider = provider
    @redirect_to = redirect_to

    %w(get post).each do |method|
      self.class.send(method, callback_path) do
        payload = request.env.fetch("omniauth.auth", {})
        payload_extra = payload.fetch("extra", {})
        permissions = payload_extra.fetch("permissions", [])
        if permissions.include?("signin")
          session[:authenticated] = true
          redirect @redirect_to
        else
          redirect "/auth/unauthorized"
        end
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
      ["/auth/failure", "/auth/unauthorized", callback_path]
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
    message = params["message"] || "unknown cause"
    throw(:halt, [401, "Authentication failure: #{message}\n"])
  end

  get "/auth/unauthorized" do
    throw(:halt, [401, "Not authorized\n"])
  end

end

