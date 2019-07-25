FROM appmap-ruby_with_appmap:2.6

RUN mkdir /app
WORKDIR /app

RUN gem install -N bundler

COPY Gemfile .

COPY . .

RUN bundle
RUN bundle binstubs appmap rack

EXPOSE 9292

ENV GLI_DEBUG=true

ENTRYPOINT [ "./bin/appmap", "record", "-o", "tmp/appmap.json" ]

HEALTHCHECK --interval=1s --retries=10 CMD curl --fail http://localhost:9292/health || exit 1
