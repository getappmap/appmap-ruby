FROM ruby-with-appmap:2.5

RUN mkdir /app
WORKDIR /app

RUN gem install -N bundler

COPY Gemfile .

RUN bundle

COPY lib/app.rb ./lib/
COPY appmap.yml config.ru ./

EXPOSE 9292

ENV GLI_DEBUG=true

ENTRYPOINT [ "bundle", "exec", "/tmp/appmap-0.5.1/exe/appmap", "record", "-o", "./tmp/appmap.json" ]

CMD [ "/usr/local/bundle/gems/rack-2.0.7/bin/rackup", "-o", "0.0.0.0", "-s", "webrick" ]

HEALTHCHECK --interval=1s --retries=10 CMD curl --fail http://localhost:9292/health || exit 1
