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

module Pangea
  class Configuration
    # Handles configuration file loading, setup, and validation
    module ConfigLoader
      CONFIG_PATHS = [
        -> { Dir.pwd },
        -> { File.join(Dir.pwd, '.pangea') },
        -> { File.join(Dir.pwd, 'infrastructure', 'pangea') },
        -> { File.join(Dir.home, '.config', 'pangea') },
        -> { '/etc/pangea' }
      ].freeze

      private

      def setup_config
        @config.tap do |c|
          c.filename = 'pangea'
          c.extname = '.yml'
          c.env_prefix = 'PANGEA'
          CONFIG_PATHS.each { |path_proc| c.append_path(path_proc.call) }
        end
      end

      def load_config
        @config.read
        @loaded_from = find_config_file
        validate_and_load_schema
      rescue TTY::Config::ReadError
        handle_missing_config
      rescue Psych::SyntaxError => e
        handle_yaml_error(e)
      ensure
        set_from_env
      end

      def find_config_file
        @config.location_paths.find { |p| File.exist?(File.join(p, 'pangea.yml')) }
      end

      def validate_and_load_schema
        @schema = ConfigurationTypes::Types::ConfigurationSchema.new(@config.to_h)
        @schema.validate!
        $stderr.puts "[pangea] Loaded configuration from: #{@loaded_from}/pangea.yml" if @loaded_from
      rescue Dry::Struct::Error => e
        $stderr.puts "[pangea] Configuration validation failed: #{e.message}"
        $stderr.puts "[pangea] Using default configuration"
        set_defaults
        @schema = ConfigurationTypes::Types::ConfigurationSchema.new(@config.to_h)
      rescue ConfigurationError => e
        $stderr.puts "[pangea] #{e.message}"
        raise
      end

      def handle_missing_config
        $stderr.puts "[pangea] No configuration file found in search paths"
        $stderr.puts "[pangea] Search paths: #{@config.location_paths.join(', ')}"
        $stderr.puts "[pangea] Using default configuration"
        set_defaults
        @schema = ConfigurationTypes::Types::ConfigurationSchema.new(@config.to_h)
      end

      def handle_yaml_error(error)
        $stderr.puts "[pangea] Invalid YAML syntax in configuration file"
        $stderr.puts "[pangea]   File: #{@loaded_from}/pangea.yml" if @loaded_from
        $stderr.puts "[pangea]   Error: #{error.message}"
        raise ConfigurationError, "Invalid YAML syntax: #{error.message}"
      end
    end
  end
end
