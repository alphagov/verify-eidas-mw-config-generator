FROM ruby:2.4.4

WORKDIR /mw-config-generator

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN bundle install

COPY generate generate
COPY templates templates

ENTRYPOINT ["bundle", "exec", "generate"]
