FROM appmap-ruby_with_appmap:2.6

RUN mkdir /app
WORKDIR /app

RUN gem install -N bundler

COPY Gemfile .

RUN bundle

COPY . .

EXPOSE 3000

ENV GLI_DEBUG=true

ENTRYPOINT [ "./record_rails" ]

CMD [ "-b", "0.0.0.0", "-s", "webrick" ]

HEALTHCHECK --interval=1s --retries=10 CMD curl --fail http://localhost:3000/health || exit 1
