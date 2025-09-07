# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'
require 'json'
require 'singleton'
require 'ipaddr'

# Load the new registry-based type system
require_relative 'types/registry'
require_relative 'types/base_types'
require_relative 'types/aws_types'
require_relative 'types/computed_types'

module Pangea
  # Type definitions for Pangea domain models
  module Types
    include Dry.Types()
    
    # New registry-based type system for enhanced validation
    def self.registry
      @registry ||= begin
        r = Registry.instance
        BaseTypes.register_all(r)
        AWSTypes.register_all(r)
        ComputedTypes.register_all(r)
        r
      end
    end
    
    def self.[](name)
      registry[name]
    end

    # Basic types with coercion
    StrippedString = Coercible::String.constructor(&:strip)
    SymbolizedString = Coercible::Symbol
    Path = Coercible::String.constrained(min_size: 1)
    
    # JSON/Hash types
    JSONHash = Strict::Hash
    SymbolizedHash = Strict::Hash.constructor do |value|
      case value
      when Hash 
        # Convert string keys to symbols recursively
        value.transform_keys(&:to_sym).transform_values do |v|
          if v.respond_to?(:transform_keys)
            v.transform_keys(&:to_sym) 
          else
            v
          end
        end
      when String then JSON.parse(value, symbolize_names: true)
      else value
      end
    end
    
    # Domain-specific identifiers
    Identifier = Strict::String.constrained(
      format: /\A[a-z][a-z0-9_-]*\z/,
      min_size: 1,
      max_size: 63
    )
    
    NamespaceString = Identifier
    ProjectString = Identifier
    SiteString = Identifier
    ModuleName = Identifier
    
    # File system types
    FilePath = Strict::String.constrained(min_size: 1)
    DirectoryPath = FilePath
    FileName = Strict::String.constrained(
      format: /\A[a-zA-Z0-9._-]+\z/,
      min_size: 1
    )
    
    # AWS-specific types
    AwsRegion = Strict::String.enum(
      'us-east-1', 'us-east-2',
      'us-west-1', 'us-west-2',
      'eu-west-1', 'eu-west-2', 'eu-west-3',
      'eu-central-1', 'eu-north-1',
      'ap-southeast-1', 'ap-southeast-2',
      'ap-northeast-1', 'ap-northeast-2', 'ap-northeast-3',
      'ap-south-1', 'ap-east-1',
      'ca-central-1',
      'sa-east-1'
    )
    
    S3BucketName = Strict::String.constrained(
      format: /\A[a-z0-9][a-z0-9.-]*[a-z0-9]\z/,
      min_size: 3,
      max_size: 63
    )
    
    DynamoTableName = Strict::String.constrained(
      format: /\A[a-zA-Z0-9_.-]+\z/,
      min_size: 3,
      max_size: 255
    )
    
    # State backend configuration
    StateBackendType = Strict::Symbol.enum(:s3, :local)
    
    # Terraform/OpenTofu types
    TerraformAction = Strict::Symbol.enum(:plan, :apply, :destroy, :init)
    TerraformVersion = Strict::String.constrained(
      format: /\A\d+\.\d+\.\d+\z/
    )
    
    # Configuration file types
    ConfigFormat = Strict::Symbol.enum(:yaml, :yml, :json, :toml, :rb)
    
    # Template and synthesis types
    TerraformJSON = Strict::Hash
    ResourceType = Strict::String.constrained(
      format: /\A[a-z][a-z0-9_]*\z/
    )
    ResourceName = Identifier
    
    # Environment variables
    EnvironmentVariable = Strict::String.constrained(
      format: /\A[A-Z][A-Z0-9_]*\z/
    )
    
    # Semantic versioning
    Version = Strict::String.constrained(
      format: /\A\d+\.\d+\.\d+(-[a-z0-9]+)?\z/
    )
    
    # URL types
    HttpUrl = Strict::String.constrained(
      format: %r{\Ahttps?://[^\s]+\z}
    )
    GitUrl = Strict::String.constrained(
      format: %r{\A(https?://|git@|git://)[^\s]+\.git\z}
    )
    
    # Arrays
    StringArray = Strict::Array.of(Strict::String)
    IdentifierArray = Strict::Array.of(Identifier)
    ModuleArray = Strict::Array.of(ModuleName)
    
    # Optional types
    OptionalString = Strict::String.optional
    OptionalIdentifier = Identifier.optional
    OptionalPath = FilePath.optional
  end
end