module Shell
  class << self
    def run(bin, cmd)
      final = []
      final << bin
      final.concat(cmd)
      system final.join(%( ))
    end
  end
end

module Compose
  BIN = ENV[%(COMPOSE_BIN)] || %(docker-compose).freeze

  class << self
    def run(cmd)
      Shell.run(BIN, cmd)
    end
  end
end

module Docker
  BIN = ENV[%(DOCKER_BIN)] || %(docker).freeze

  class << self
    def run(cmd)
      Shell.run(BIN, cmd)
    end

    def build(image)
      cmd = []
      cmd << %(build)
      cmd << %(-t)
      cmd << %(#{image}:latest)
      cmd << %(.)
      run cmd
    end

    def tag(image)
      sha = `git rev-parse --short HEAD`
      cmd = []
      cmd << %(tag)
      cmd << %(#{image}:latest)
      cmd << %(#{image}:#{sha})
      run cmd
    end

    def create(name, image)
      cmd = []
      cmd << %(create)
      cmd << %(-it)
      cmd << %(--name #{name})
      cmd << image
      cmd << %(/bin/bash)
      run cmd
    end

    def start(name)
      cmd = []
      cmd << %(start)
      cmd << %(-i -a)
      cmd << name
    end
  end
end

class Image
  def initialize(name)
    @name = name
  end

  def build
    Docker.build(@name)
    Docker.tag(@name)
  end
end

class Container
  def initialize(name, image)
    @name   = name
    @image  = image
  end

  def create
    Docker.create(@name, @image)
  end

  def start
    Docker.start(@name)
  end
end
