# frozen_string_literal: true

# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'tty-config'
require 'pangea/types'
require 'pangea/entities'
require 'pangea/configuration/types'
require 'pangea/configuration/namespace_manager'
require 'pangea/configuration/config_loader'
require 'pangea/configuration/defaults'
require 'pangea/ui'

module Pangea
  # Configuration loading error
  class ConfigurationError < StandardError; end

  # Configuration management using TTY::Config
  class Configuration
    include NamespaceManager
    include ConfigLoader
    include Defaults

    attr_reader :config

    def initialize
      @config = TTY::Config.new
      @schema = nil
      @loaded_from = nil
      @ui = UI.new
      @namespaces = nil
      setup_config
      load_config
    end

    # Access configuration values
    def fetch(*keys, default: nil)
      @config.fetch(*keys, default: default)
    end

    # Set configuration values
    def set(*keys, value:)
      @config.set(*keys, value: value)
    end

    # Get the validated configuration schema
    def schema
      @schema
    end

    # Get configuration loading details
    def debug_info
      {
        loaded_from: @loaded_from,
        search_paths: @config.location_paths,
        namespace_count: namespaces.count,
        default_namespace: default_namespace,
        terraform_binary: fetch(:terraform, :binary, default: 'terraform'),
        valid: @schema ? true : false
      }
    end

    # Write configuration to file
    def write(force: false)
      @config.write(force: force)
    end

    # Reload configuration from files
    def reload!
      %i[@namespaces @schema @loaded_from].each { |var| instance_variable_set(var, nil) }
      load_config
    end

    # Get configuration search paths
    def search_paths
      @config.location_paths
    end
  end

  # Global configuration instance
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end
    alias config configuration

    def configure
      yield(configuration) if block_given?
      configuration
    end

    def reset!
      @configuration = nil
    end
  end
end
