ARG GEM_VERSION
ARG RUBY_VERSION

FROM appmap:${GEM_VERSION} as appmap
FROM ruby:${RUBY_VERSION}

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y vim less
RUN apt-get install -y postgresql-client

RUN mkdir /app
WORKDIR /app

RUN gem install -N bundler

COPY Gemfile .

RUN bundle

COPY . .

COPY --from=appmap /pkg/appmap.gem /tmp/
RUN gem install /tmp/appmap.gem && \
    bundle update --local appmap && \
    bundle binstubs appmap --force

EXPOSE 3000

HEALTHCHECK --interval=1s --retries=10 CMD curl --fail http://localhost:3000/health || exit 1
