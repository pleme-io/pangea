# frozen_string_literal: true

require 'dry-struct'
require 'pangea/types'

module Pangea
  module Entities
    # Template represents a Pangea infrastructure template
    # Templates are compiled into Terraform JSON
    class Template < Dry::Struct
      # Template metadata
      attribute :name, Types::Identifier
      attribute :content, Types::Strict::String
      attribute :file_path, Types::FilePath.optional.default(nil)
      
      # Template configuration
      attribute :namespace, Types::NamespaceString.optional.default(nil)
      attribute :project, Types::ProjectString.optional.default(nil)
      attribute :variables, Types::SymbolizedHash.default({}.freeze)
      
      # Compilation settings
      attribute :target_version, Types::TerraformVersion.optional.default(nil)
      attribute :strict_mode, Types::Strict::Bool.default(false)
      
      # Get template source location
      def source
        file_path || "<inline:#{name}>"
      end
      
      # Check if template has a file path
      def from_file?
        !file_path.nil?
      end
      
      # Get the cache key for this template
      def cache_key
        parts = [namespace, project, name].compact
        parts.join('/')
      end
      
      # Validate template content
      def validate!
        errors = []
        
        # Check content is not empty
        if content.strip.empty?
          errors << "Template content cannot be empty"
        end
        
        # Basic syntax check (look for common issues)
        if content.include?("<%") || content.include?("{{")
          errors << "Template appears to contain ERB or Mustache syntax (not supported)"
        end
        
        raise ValidationError, errors.join(", ") unless errors.empty?
        true
      end
      
      # Extract metadata from content (if present)
      def metadata
        return {} unless content.start_with?("# @")
        
        metadata = {}
        content.lines.each do |line|
          break unless line.start_with?("# @")
          
          if line =~ /# @(\w+):\s*(.+)$/
            key = $1.to_sym
            value = $2.strip
            metadata[key] = value
          end
        end
        
        metadata
      end
      
      # Get template content without metadata comments
      def content_without_metadata
        return content unless content.start_with?("# @")
        
        lines = content.lines
        lines.drop_while { |line| line.start_with?("# @") }.join
      end
    end
    
    # Compilation result from a template
    class CompilationResult < Dry::Struct
      attribute :success, Types::Strict::Bool
      attribute :terraform_json, Types::Strict::String.optional.default(nil)  # Changed to String
      attribute :errors, Types::StringArray.default([].freeze)
      attribute :warnings, Types::StringArray.default([].freeze)
      attribute :template_name, Types::Strict::String.optional.default(nil)  # Made strict string
      attribute :template_count, Types::Strict::Integer.optional.default(nil)
      
      # Check if compilation was successful
      def success?
        success && errors.empty?
      end
      
      # Check if compilation failed
      def failure?
        !success?
      end
      
    end
  end
end