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
require 'pangea/ui'

module Pangea
  # Configuration loading error
  class ConfigurationError < StandardError; end
  # Configuration management using TTY::Config
  class Configuration
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
    
    # Get all namespaces as entities
    def namespaces
      @namespaces ||= @schema ? load_schema_namespaces : load_fallback_namespaces
    end
    
    private
    
    def load_schema_namespaces
      @schema.namespace_configs.values.map do |ns_config|
        build_namespace_from_schema(ns_config)
      end
    end
    
    def load_fallback_namespaces
      fetch(:namespaces, default: {}).map do |name, config|
        build_namespace_from_config(name, config)
      end
    end
    
    def build_namespace_from_schema(ns_config)
      Entities::Namespace.new(
        name: ns_config.name,
        description: ns_config.description,
        state: {
          type: ns_config.state.type,
          config: ns_config.state.config.transform_keys(&:to_sym)
        },
        tags: {} # Schema doesn't have tags yet
      )
    end
    
    def build_namespace_from_config(name, config)
      state_config = extract_state_config(config)
      
      Entities::Namespace.new(
        name: name.to_s,
        state: prepare_state(state_config),
        description: config[:description],
        tags: config[:tags] || {}
      )
    rescue Dry::Struct::Error => e
      raise ConfigurationError, "Invalid namespace '#{name}': #{e.message}"
    end
    
    def extract_state_config(config)
      config[:state] || config['state'] || {}
    end
    
    def prepare_state(state_config)
      state_type = state_config[:type] || state_config['type']
      config_fields = state_config.reject { |k, _| k.to_s == 'type' }
      
      {
        type: state_type&.to_sym,
        config: config_fields.transform_keys(&:to_sym)
      }
    end
    
    public
    
    # Get a specific namespace
    def namespace(name)
      namespaces.find { |ns| ns.name == name.to_s }
    end
    
    # Check if a namespace exists
    def namespace?(name)
      !namespace(name).nil?
    end
    
    # Get the default namespace (from env or config)
    def default_namespace
      ENV['PANGEA_NAMESPACE'] || fetch(:default_namespace)
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
    
    private
    
    CONFIG_PATHS = [
      -> { Dir.pwd },
      -> { File.join(Dir.pwd, '.pangea') },
      -> { File.join(Dir.pwd, 'infrastructure', 'pangea') },
      -> { File.join(Dir.home, '.config', 'pangea') },
      -> { '/etc/pangea' }
    ].freeze
    
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
      @ui.success "Loaded configuration from: #{@loaded_from}/pangea.yml" if @loaded_from
    rescue Dry::Struct::Error => e
      @ui.error "Configuration validation failed: #{e.message}"
      @ui.warn "Using default configuration"
      set_defaults
      @schema = ConfigurationTypes::Types::ConfigurationSchema.new(@config.to_h)
    rescue ConfigurationError => e
      @ui.error e.message
      raise
    end
    
    def handle_missing_config
      @ui.warn "No configuration file found in search paths"
      @ui.info "Search paths: #{@config.location_paths.join(', ')}"
      @ui.info "Using default configuration"
      set_defaults
      @schema = ConfigurationTypes::Types::ConfigurationSchema.new(@config.to_h)
    end
    
    def handle_yaml_error(error)
      @ui.error "Invalid YAML syntax in configuration file"
      @ui.error "  File: #{@loaded_from}/pangea.yml" if @loaded_from
      @ui.error "  Error: #{error.message}"
      raise ConfigurationError, "Invalid YAML syntax: #{error.message}"
    end
    
    DEFAULT_CONFIG = {
      namespaces: {},
      modules: { path: 'modules' },
      cache: { directory: -> { File.join(Dir.home, '.pangea', 'cache') } },
      terraform: { binary: -> { ENV['TERRAFORM_BIN'] || 'tofu' } }
    }.freeze
    
    def set_defaults
      DEFAULT_CONFIG.each do |key, value|
        set_config_value(key, value)
      end
    end
    
    def set_config_value(key, value)
      if value.is_a?(Hash)
        value.each { |k, v| @config.set(key, k, value: v.is_a?(Proc) ? v.call : v) }
      else
        @config.set(key, value: value.is_a?(Proc) ? value.call : value)
      end
    end
    
    ENV_OVERRIDES = {
      'PANGEA_NAMESPACE' => [:default_namespace],
      'TERRAFORM_BIN' => [:terraform, :binary],
      'PANGEA_CACHE_DIR' => [:cache, :directory]
    }.freeze
    
    def set_from_env
      ENV_OVERRIDES.each do |env_var, config_path|
        value = ENV[env_var]
        @config.set(*config_path, value: value) if value
      end
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