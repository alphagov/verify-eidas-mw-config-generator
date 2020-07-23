FROM ruby:2.5.8

WORKDIR /mw-config-generator

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN gem install bundler && bundler update --bundler && bundle install

COPY generate generate
COPY templates templates

ENTRYPOINT ["bundle", "exec", "generate"]
