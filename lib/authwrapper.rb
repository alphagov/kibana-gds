require "sinatra/base"
require "json"

class AuthWrapper < Sinatra::Base

  def initialize(app, provider, redirect_to="/kibana")
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

  get "/" do
    redirect @redirect_to
  end

  get "/auth/logout" do
    session[:authenticated] = false
    redirect @redirect_to
  end

  get "/auth/failure" do
    message = params["message"] || "unknown cause"
    throw(:halt, [401, "Authentication failure: #{ERB::Util.html_escape(message)}\n"])
  end

  get "/auth/unauthorized" do
    throw(:halt, [401, "Not authorized\n"])
  end

  get "/app-graph" do
    erb :app_graph, locals: {
      known_apps: known_apps,
      traffic: traffic,
      traffic_matrix: traffic_matrix,
    }
  end

private

  def known_apps
    known_destination_apps = traffic.keys
    known_source_apps = traffic.map{|_, db| db.keys}.flatten.uniq

    (known_source_apps | known_destination_apps).sort
  end

  def traffic_matrix
    known_apps.map do |destination_app|
      known_apps.map do |source_app|
        traffic[destination_app][source_app]
      end
    end
  end

  def traffic
    return @traffic if @traffic

    @traffic = Hash.new { |hash, key| hash[key] = Hash.new { |hash, key| hash[key] = 0 } }
    aggregations["destination_application_aggregation"]["buckets"].each do |destination_bucket|
      destination_app = destination_bucket["key"]
      total_received = destination_bucket["doc_count"]

      total_received_from_known_sources = 0
      destination_bucket["source_application_aggregation"]["buckets"].each do |source_bucket|
        source_app = source_bucket["key"]
        total_received_from_known_sources += source_bucket["doc_count"]

        @traffic[destination_app][source_app] = source_bucket["doc_count"]
      end

      @traffic[destination_app]["unknown"] = (total_received - total_received_from_known_sources)
    end

    @traffic = resolve_aliases(@traffic, ["whitehall-frontend", "whitehall-admin"], "whitehall")
    @traffic = resolve_aliases(@traffic, ["search"], "rummager")

    @traffic
  end

  def resolve_aliases(traffic_hash, aliases, actual)
    traffic_hash = traffic_hash.dup

    aliases.each do |whitehall_alias|
      traffic_for_alias = traffic_hash.delete(whitehall_alias)
      traffic_for_alias.each do |source, count|
        traffic_hash[actual][source] += count
      end
    end

    traffic_hash
  end

  def aggregations
    @aggregations ||= aggregation_response["aggregations"]
  end

  def aggregation_response
    JSON.parse(call_elasticsearch)
  end

  def call_elasticsearch
    RestClient.post("#{Kibana.elasticsearch_host}:#{Kibana.elasticsearch_port || 9200}/logs-current/_search", %|
        {
          "aggs": {
            "destination_application_aggregation": {
              "terms": {
                "field": "destination_application",
                "size": 0
              },
              "aggs": {
                "source_application_aggregation": {
                  "terms": {
                    "field": "source_application",
                    "size": 0
                  }
                }
              }
            }
          },
          "size": 0
        }
      |,
      content_type: :json,
      accept: :json
    )
  end
end
