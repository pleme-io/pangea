FROM ruby:3.3.6-slim

# Install only essential packages
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy only files needed for bundle install
COPY Gemfile Gemfile.lock pangea.gemspec ./
COPY lib/pangea/version.rb ./lib/pangea/version.rb

# Install dependencies
RUN bundle config set --local path '/usr/local/bundle' && \
    bundle install --jobs=4 --retry=3

# Don't copy source code - it will be mounted

# Run tests by default
CMD ["bundle", "exec", "rspec"]