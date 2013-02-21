# Generate the client id and secret for your local dev machine signonotron2 using rake applications:create
# and passing in name, redirect_uri, description, home_uri.
# e.g. rake applications:create name=kibana redirect_uri=http://localhost:9292/auth/gds/callback description="Kibana" home_uri=http://localhost:9292
ENV["SIGNON_ROOT"] = "http://localhost:3000"
ENV["SIGNON_CLIENT_ID"] = "3a31c225f7e7589991477da6fcf3df7eb5a060572d32ceb91ccf4b73f51717a6"
ENV["SIGNON_CLIENT_SECRET"] ="0324d981ffd8b1422fb51a453e22b4e08255d5920e841ea4ebdfc8e29e7a1e1a"
