FROM appmap-ruby_with_appmap:2.6

RUN mkdir /app
WORKDIR /app

RUN gem install -N bundler

COPY Gemfile .

RUN bundle

COPY lib/app.rb ./lib/
COPY record_rackup appmap.yml config.ru ./
COPY tmp/.keep ./tmp/

EXPOSE 9292

ENV GLI_DEBUG=true

ENTRYPOINT [ "./record_rackup" ]

CMD [ "-o", "0.0.0.0", "-s", "webrick" ]

HEALTHCHECK --interval=1s --retries=10 CMD curl --fail http://localhost:9292/health || exit 1
