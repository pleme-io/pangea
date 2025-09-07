# frozen_string_literal: true

require 'pangea/types'

module Pangea
  module Compilation
    # Validates input before compilation
    class Validator
      # Validate a file path
      def self.validate_file!(path)
        errors = []
        
        # Check file exists
        unless File.exist?(path)
          errors << "File not found: #{path}"
        end
        
        # Check file is readable
        unless File.readable?(path)
          errors << "File not readable: #{path}"
        end
        
        # Check file extension
        unless path.end_with?('.rb', '.pangea')
          errors << "Invalid file extension: expected .rb or .pangea"
        end
        
        # Check file size (prevent huge files)
        if File.exist?(path) && File.size(path) > 10_000_000 # 10MB
          errors << "File too large: #{path} (max 10MB)"
        end
        
        raise ValidationError, errors.join(", ") unless errors.empty?
        true
      end
      
      # Validate template content
      def self.validate_content!(content)
        errors = []
        
        # Check content is not empty
        if content.nil? || content.strip.empty?
          errors << "Template content cannot be empty"
        end
        
        # Check for suspicious patterns
        if content && contains_suspicious_patterns?(content)
          errors << "Template contains potentially unsafe patterns"
        end
        
        # Basic syntax validation
        begin
          # Try to parse as Ruby to catch syntax errors early
          RubyVM::AbstractSyntaxTree.parse(content) if content
        rescue SyntaxError => e
          errors << "Syntax error: #{e.message}"
        end
        
        raise ValidationError, errors.join(", ") unless errors.empty?
        true
      end
      
      # Validate namespace name
      def self.validate_namespace!(name)
        return true if name.nil? # Optional
        
        # Use dry-types for validation
        Types::NamespaceString[name]
        true
      rescue Dry::Types::CoercionError => e
        raise ValidationError, "Invalid namespace name: #{e.message}"
      end
      
      # Validate terraform JSON output
      def self.validate_terraform_json!(json)
        errors = []
        
        # Check it's a hash
        unless json.is_a?(Hash)
          errors << "Terraform JSON must be a Hash"
        end
        
        # Check for required top-level keys
        if json.is_a?(Hash)
          valid_keys = %w[terraform provider resource data module output variable locals]
          invalid_keys = json.keys - valid_keys
          
          unless invalid_keys.empty?
            errors << "Invalid top-level keys: #{invalid_keys.join(', ')}"
          end
        end
        
        raise ValidationError, errors.join(", ") unless errors.empty?
        true
      end
      
      private
      
      # Check for patterns that might indicate code injection attempts
      def self.contains_suspicious_patterns?(content)
        suspicious_patterns = [
          /`.*`/,                    # Backticks (command execution)
          /system\s*\(/,            # system() calls
          /exec\s*\(/,              # exec() calls
          /eval\s*\(/,              # eval() calls
          /%x\{/,                   # %x{} command execution
          /File\s*\.\s*delete/,     # File deletion
          /FileUtils\s*\.\s*rm/,    # File removal
          /require\s+['"]open3/,    # Process execution library
        ]
        
        suspicious_patterns.any? { |pattern| content.match?(pattern) }
      end
    end
    
    # Validation errors
    class ValidationError < StandardError; end
  end
end