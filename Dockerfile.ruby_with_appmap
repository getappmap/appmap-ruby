FROM ruby:2.5

ARG GEM_VERSION

COPY pkg/appmap-$GEM_VERSION.gem /tmp

RUN cd /tmp && gem unpack appmap-$GEM_VERSION.gem --target appmap
