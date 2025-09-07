# frozen_string_literal: true

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
      @namespaces ||= begin
        if @schema
          # Use validated schema namespaces
          @schema.namespace_configs.values.map do |ns_config|
            # Convert config keys to symbols for entity validation
            config_with_symbols = ns_config.state.config.transform_keys(&:to_sym)
            
            Entities::Namespace.new(
              name: ns_config.name,
              description: ns_config.description,
              state: {
                type: ns_config.state.type,
                config: config_with_symbols
              },
              tags: {} # Schema doesn't have tags yet
            )
          end
        else
          # Fallback to old loading method
          namespace_configs = fetch(:namespaces, default: {})
          
          namespace_configs.map do |name, config|
            # Transform flatter YAML state structure to expected nested structure
            state_config = config[:state] || config['state'] || {}
            state_type = state_config[:type] || state_config['type']
            
            # Extract state config fields (everything except type)
            config_fields = state_config.dup
            config_fields.delete(:type)
            config_fields.delete('type')
            
            # Convert config field keys to symbols for StateConfig entity
            symbolized_config = config_fields.transform_keys { |key| key.to_sym }
            
            # Create properly nested state structure
            nested_state = {
              type: state_type&.to_sym,
              config: symbolized_config
            }
            
            Entities::Namespace.new(
              name: name.to_s,
              state: nested_state,
              description: config[:description],
              tags: config[:tags] || {}
            )
          rescue Dry::Struct::Error => e
            raise ConfigurationError, "Invalid namespace '#{name}': #{e.message}"
          end
        end
      end
    end
    
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
      @namespaces = nil
      @schema = nil
      @loaded_from = nil
      load_config
    end
    
    # Get configuration search paths
    def search_paths
      @config.location_paths
    end
    
    private
    
    def setup_config
      # Set up configuration file properties
      @config.filename = 'pangea'
      @config.extname = '.yml'
      @config.env_prefix = 'PANGEA'
      
      # Configuration search paths (in order of precedence)
      @config.append_path Dir.pwd                                    # Current directory
      @config.append_path File.join(Dir.pwd, '.pangea')            # .pangea/ subdirectory
      @config.append_path File.join(Dir.pwd, 'infrastructure', 'pangea') # infrastructure/pangea subdirectory
      @config.append_path File.join(Dir.home, '.config', 'pangea') # User config
      @config.append_path '/etc/pangea'                            # System config
      
      # TTY::Config automatically supports yml/yaml formats
    end
    
    def load_config
      begin
        @config.read
        @loaded_from = @config.location_paths.select { |p| File.exist?(File.join(p, 'pangea.yml')) }.first
        
        # Validate configuration using schema
        begin
          config_hash = @config.to_h
          @schema = ConfigurationTypes::Types::ConfigurationSchema.new(config_hash)
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
      rescue TTY::Config::ReadError => e
        @ui.warn "No configuration file found in search paths"
        @ui.info "Search paths: #{@config.location_paths.join(', ')}"
        @ui.info "Using default configuration"
        set_defaults
        @schema = ConfigurationTypes::Types::ConfigurationSchema.new(@config.to_h)
      rescue Psych::SyntaxError => e
        @ui.error "Invalid YAML syntax in configuration file"
        @ui.error "  File: #{@loaded_from}/pangea.yml" if @loaded_from
        @ui.error "  Error: #{e.message}"
        raise ConfigurationError, "Invalid YAML syntax: #{e.message}"
      ensure
        set_from_env
      end
    end
    
    def set_defaults
      # Default configuration structure
      @config.set(:namespaces, value: {})
      @config.set(:modules, :path, value: 'modules')
      @config.set(:cache, :directory, value: File.join(Dir.home, '.pangea', 'cache'))
      @config.set(:terraform, :binary, value: ENV['TERRAFORM_BIN'] || 'tofu')
    end
    
    def set_from_env
      # Override configuration from environment variables
      if ENV['PANGEA_NAMESPACE']
        @config.set(:default_namespace, value: ENV['PANGEA_NAMESPACE'])
      end
      
      if ENV['TERRAFORM_BIN']
        @config.set(:terraform, :binary, value: ENV['TERRAFORM_BIN'])
      end
      
      if ENV['PANGEA_CACHE_DIR']
        @config.set(:cache, :directory, value: ENV['PANGEA_CACHE_DIR'])
      end
    end
  end
  
  # Global configuration instance
  class << self
    def configuration
      @configuration ||= Configuration.new
    end
    
    def config
      configuration
    end
    
    def configure
      yield(configuration) if block_given?
      configuration
    end
  end
end