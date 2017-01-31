FROM phusion/passenger-ruby23:latest
MAINTAINER GOV.UK <govuk-inf-team@digital.cabinet-office.gov.uk>
EXPOSE 5601

#RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
#    apt-get install -y --no-install-recommends moreutils net-tools patch libfontconfig libfreetype6 ruby bundler ruby-dev && \
#    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd --no-create-home --uid 1000 kibana

WORKDIR /usr/share/kibana
RUN curl -Ls https://artifacts.elastic.co/downloads/kibana/kibana-5.2.0-linux-x86_64.tar.gz | tar --strip-components=1 -zxf - && \
    ln -s /usr/share/kibana /opt/kibana

# Set some Kibana configuration defaults.
ADD config/kibana.yml /usr/share/kibana/config/

# Add the launcher/wrapper script. It knows how to interpret environment
# variables and translate them to Kibana CLI options.
ADD bin/kibana-docker /usr/local/bin/

# Add a self-signed SSL certificate for use in examples.
ADD ssl/kibana.example.org.* /usr/share/kibana/config/
ADD kibana-sso/* /usr/share/kibana/
ADD kibana-sso/lib/* /usr/share/kibana/lib/

RUN usermod --home /usr/share/kibana kibana
RUN chown kibana /usr/share/kibana && chmod 775 /usr/share/kibana
USER kibana
ENV PATH=/usr/share/kibana/bin:$PATH
CMD bundle install --path=.bundle && bundle exec rackup config.ru
