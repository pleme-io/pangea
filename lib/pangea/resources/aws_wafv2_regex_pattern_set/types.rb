# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS WAFv2 Regex Pattern Set resources
      class WafV2RegexPatternSetAttributes < Dry::Struct
        # Name for the regex pattern set
        attribute :name, Resources::Types::String

        # Description of the regex pattern set
        attribute :description, Resources::Types::String.optional

        # Scope of the regex pattern set (CLOUDFRONT or REGIONAL)
        attribute :scope, Resources::Types::String.enum('CLOUDFRONT', 'REGIONAL')

        # List of regular expression patterns
        attribute :regular_expression, Resources::Types::Array.of(
          Types::Hash.schema(
            regex_string: Types::String
          )
        )

        # Tags to apply to the regex pattern set
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate name format
          unless attrs.name.match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)
            raise Dry::Struct::Error, "Regex pattern set name must be 1-128 characters and contain only alphanumeric, hyphens, and underscores"
          end

          # Validate that at least one regex pattern is provided
          if attrs.regular_expression.empty?
            raise Dry::Struct::Error, "Regex pattern set must contain at least one regular expression"
          end

          # Validate maximum number of patterns (AWS limit is typically 10)
          if attrs.regular_expression.length > 10
            raise Dry::Struct::Error, "Regex pattern set cannot contain more than 10 regular expressions"
          end

          # Validate each regex pattern
          attrs.regular_expression.each_with_index do |pattern, index|
            begin
              # Test if the regex is valid
              Regexp.new(pattern[:regex_string])
            rescue RegexpError => e
              raise Dry::Struct::Error, "Invalid regex pattern at index #{index}: #{e.message}"
            end
            
            # Check for overly broad patterns
            if pattern[:regex_string] == '.*' || pattern[:regex_string] == '.+'
              raise Dry::Struct::Error, "Overly broad regex pattern at index #{index} - avoid .* or .+ patterns"
            end
          end

          # Set default description if not provided
          unless attrs.description
            attrs = attrs.copy_with(description: "Regex pattern set #{attrs.name} with #{attrs.regular_expression.length} pattern(s)")
          end

          attrs
        end

        # Helper methods
        def pattern_count
          regular_expression.length
        end

        def cloudfront_scope?
          scope == 'CLOUDFRONT'
        end

        def regional_scope?
          scope == 'REGIONAL'
        end

        def get_patterns
          regular_expression.map { |p| p[:regex_string] }
        end

        def estimated_monthly_cost
          "$1.00/month per regex pattern set + $0.60 per million requests evaluated"
        end

        def validate_configuration
          warnings = []
          
          get_patterns.each_with_index do |pattern, index|
            if pattern.length > 200
              warnings << "Very long regex pattern at index #{index} - may impact performance"
            end
            
            if pattern.include?('*') && !pattern.include?('\\*')
              warnings << "Unescaped wildcard in pattern at index #{index} - ensure this is intentional"
            end
            
            # Check for potentially expensive patterns
            if pattern.include?('.*.*') || pattern.include?('.+.+')
              warnings << "Potentially expensive nested quantifiers in pattern at index #{index}"
            end
          end
          
          if pattern_count == 1
            warnings << "Pattern set contains only one regex - consider consolidating with other sets"
          end
          
          warnings
        end

        # Analyze pattern complexity
        def pattern_complexity
          complex_patterns = get_patterns.count do |pattern|
            pattern.include?('(?') || pattern.include?('[') || pattern.length > 50
          end
          
          case complex_patterns
          when 0
            'simple'
          when 1..2
            'moderate'
          else
            'complex'
          end
        end

        # Check if patterns are security-focused
        def security_patterns?
          security_indicators = get_patterns.any? do |pattern|
            pattern.downcase.include?('script') ||
            pattern.include?('<') ||
            pattern.include?('sql') ||
            pattern.include?('union') ||
            pattern.include?('eval')
          end
          
          security_indicators
        end

        # Get primary use case based on patterns
        def primary_use_case
          patterns = get_patterns.join(' ').downcase
          
          return 'xss_protection' if patterns.include?('script') || patterns.include?('<')
          return 'sql_injection_protection' if patterns.include?('sql') || patterns.include?('union')
          return 'path_validation' if patterns.include?('/')
          return 'input_validation' if patterns.include?('[a-z')
          return 'general_filtering'
        end
      end

      # Common WAFv2 regex pattern set configurations
      module WafV2RegexPatternSetConfigs
        # XSS protection patterns
        def self.xss_protection_patterns(scope = 'REGIONAL')
          {
            name: 'xss-protection-patterns',
            description: 'Regex patterns to detect XSS attempts',
            scope: scope,
            regular_expression: [
              { regex_string: '<script[^>]*>.*</script>' },
              { regex_string: 'javascript:' },
              { regex_string: 'on\w+\s*=' },
              { regex_string: '<iframe[^>]*>' },
              { regex_string: 'eval\s*\(' }
            ],
            tags: {
              Purpose: 'XSS Protection',
              SecurityType: 'input_validation'
            }
          }
        end

        # SQL injection protection patterns
        def self.sql_injection_patterns(scope = 'REGIONAL')
          {
            name: 'sql-injection-patterns',
            description: 'Regex patterns to detect SQL injection attempts',
            scope: scope,
            regular_expression: [
              { regex_string: '(\bUNION\b|\bSELECT\b|\bINSERT\b|\bDELETE\b|\bUPDATE\b)\s' },
              { regex_string: '(\bOR\b|\bAND\b)\s+\d+\s*=\s*\d+' },
              { regex_string: '(\bDROP\b|\bALTER\b|\bTRUNCATE\b)\s+\bTABLE\b' },
              { regex_string: '--\s' },
              { regex_string: '/\*.*\*/' }
            ],
            tags: {
              Purpose: 'SQL Injection Protection',
              SecurityType: 'database_security'
            }
          }
        end

        # Path traversal protection patterns
        def self.path_traversal_patterns(scope = 'REGIONAL')
          {
            name: 'path-traversal-patterns',
            description: 'Regex patterns to detect path traversal attempts',
            scope: scope,
            regular_expression: [
              { regex_string: '\.\./.*\.\.' },
              { regex_string: '\.\.\\.*\.\.' },
              { regex_string: '/etc/passwd' },
              { regex_string: '/proc/self/' },
              { regex_string: 'WEB-INF/' }
            ],
            tags: {
              Purpose: 'Path Traversal Protection',
              SecurityType: 'file_system_security'
            }
          }
        end

        # User agent filtering patterns
        def self.user_agent_filtering_patterns(scope = 'REGIONAL')
          {
            name: 'user-agent-filtering-patterns',
            description: 'Regex patterns to filter suspicious user agents',
            scope: scope,
            regular_expression: [
              { regex_string: 'sqlmap/' },
              { regex_string: 'nikto/' },
              { regex_string: 'nmap/' },
              { regex_string: 'masscan/' },
              { regex_string: 'python-requests/' }
            ],
            tags: {
              Purpose: 'User Agent Filtering',
              SecurityType: 'bot_protection'
            }
          }
        end

        # Custom application patterns
        def self.custom_application_patterns(application_name, patterns, scope = 'REGIONAL')
          {
            name: "#{application_name.downcase.gsub(/[^a-z0-9]/, '-')}-custom-patterns",
            description: "Custom regex patterns for #{application_name}",
            scope: scope,
            regular_expression: patterns.map { |pattern| { regex_string: pattern } },
            tags: {
              Application: application_name,
              Purpose: 'Custom Application Protection',
              SecurityType: 'application_specific'
            }
          }
        end
      end
    end
      end
    end
  end
end