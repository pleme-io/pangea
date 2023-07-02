FROM ruby:3.1.0

RUN mkdir -p /app
WORKDIR /app
COPY . .
RUN bundle install
