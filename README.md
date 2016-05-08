# kibana-gds

This is a wrapper that initialises [Kibana][] behind GOV.UK's [Signon][].

## Development

To get this running on your local machine:

- Run the [Signon][] app
- Generate an OAuth client ID and secret in Signon and pass them to this
  app as environment variables
- Run this app with `rackup config.ru`

[Kibana]: https://www.elastic.co/products/kibana
[Signon]: https://github.com/alphagov/signonotron2/
