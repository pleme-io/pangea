module Pangea
  module Quality
    class ResourceAuditor
      REQUIRED_FILES = %w[
        resource.rb
        types.rb
        CLAUDE.md
        README.md
      ].freeze
      
      REQUIRED_PATTERNS = {
        has_types: /class Types::/,
        has_validation: /def validate_/,
        has_yard_docs: /@param|@return|@example/,
        follows_naming: /def aws_[a-z]+_[a-z_]+/,
        returns_reference: /ResourceReference\.new/
      }.freeze
      
      def initialize(resource_path)
        @resource_path = resource_path
        @resource_name = File.basename(resource_path)
      end
      
      def audit
        results = {
          resource: @resource_name,
          score: 0,
          missing: [],
          total_checks: REQUIRED_FILES.length + REQUIRED_PATTERNS.length
        }
        
        # Check required files
        REQUIRED_FILES.each do |file|
          if File.exist?(File.join(@resource_path, file))
            results[:score] += 1
          else
            results[:missing] << "Missing file: #{file}"
          end
        end
        
        # Check patterns in resource.rb
        resource_file = File.join(@resource_path, 'resource.rb')
        if File.exist?(resource_file)
          content = File.read(resource_file)
          
          REQUIRED_PATTERNS.each do |check, pattern|
            if content.match?(pattern)
              results[:score] += 1
            else
              results[:missing] << "Failed check: #{check}"
            end
          end
        end
        
        results[:percentage] = (results[:score].to_f / results[:total_checks] * 100).round
        results
      end
    end
  end
end