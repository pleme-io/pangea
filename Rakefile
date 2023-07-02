# frozen_string_literal: true

require %(bundler/gem_tasks)
require %(rubocop/rake_task)
require %(rspec/core/rake_task)

require_relative %(./lib/pangea/docker)

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = [%(--display-cop-names)]
end

task :bundix do
  sh %(bundle lock --update)
  sh %(bundix)
end

namespace :container do
  task :build do
    image = Image.new(:pangea)
    image.build
  end

  task :create do
    container = Container.new(:pangea, :pangea)
    container.create
  end

  task :start do
    container = Container.new(:pangea, :pangea)
    container.start
  end

  task :login do
    container = Container.new(:pangea, :pangea)
    container.login
  end
end
