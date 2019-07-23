FROM ruby:2.5

COPY pkg/appmap-0.5.1.gem /tmp
RUN cd /tmp && gem unpack appmap-0.5.1.gem
