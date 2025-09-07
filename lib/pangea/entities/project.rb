# frozen_string_literal: true

require 'dry-struct'
require 'pangea/types'

module Pangea
  module Entities
    # Project represents a single instance of Terraform state within a namespace
    # Projects are the smallest runnable unit in Pangea
    class Project < Dry::Struct
      # Project metadata
      attribute :name, Types::ProjectString
      attribute :namespace, Types::NamespaceString
      attribute :site, Types::SiteString.optional.default(nil)
      attribute :description, Types::OptionalString.default(nil)
      
      # Project configuration
      attribute :modules, Types::ModuleArray.default([].freeze)
      attribute :variables, Types::SymbolizedHash.default({}.freeze)
      attribute :outputs, Types::StringArray.default([].freeze)
      attribute :depends_on, Types::IdentifierArray.default([].freeze)
      
      # Additional settings
      attribute :terraform_version, Types::TerraformVersion.optional.default(nil)
      attribute :tags, Types::SymbolizedHash.default({}.freeze)
      
      # Get the full project identifier (namespace.site.project)
      def full_name
        [namespace, site, name].compact.join('.')
      end
      
      # Get the state key path for this project
      def state_key
        parts = [namespace]
        parts << site if site
        parts << name
        parts.join('/')
      end
      
      # Check if project has modules configured
      def has_modules?
        !modules.empty?
      end
      
      # Check if project has dependencies
      def has_dependencies?
        !depends_on.empty?
      end
      
      # Get module configuration by name
      def module_config(module_name)
        modules.find { |m| m == module_name }
      end
      
      # Convert to hash suitable for Terraform backend key
      def to_backend_config(prefix: nil)
        key_parts = [prefix, state_key].compact
        {
          key: key_parts.join('/'),
          workspace_key_prefix: "workspaces"
        }
      end
      
      # Validate project configuration
      def validate!
        errors = []
        
        # Check for circular dependencies
        if depends_on.include?(name)
          errors << "Project cannot depend on itself"
        end
        
        # Check module names are valid
        modules.each do |mod|
          unless mod.match?(/\A[a-z][a-z0-9_-]*\z/)
            errors << "Invalid module name: #{mod}"
          end
        end
        
        raise ValidationError, errors.join(", ") unless errors.empty?
        true
      end
    end
  end
end