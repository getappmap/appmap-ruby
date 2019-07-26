FROM appmap-ruby_with_appmap:2.6

RUN apt-get update && apt-get install -y postgresql-client

RUN mkdir /app
WORKDIR /app

RUN gem install -N bundler

COPY Gemfile .

RUN bundle

COPY . .

RUN bundle binstubs bundler --force
RUN bundle binstubs appmap rspec-core

EXPOSE 3000

HEALTHCHECK --interval=1s --retries=10 CMD curl --fail http://localhost:3000/health || exit 1
