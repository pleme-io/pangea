# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # S3 website error document configuration
      class WebsiteErrorDocument < Dry::Struct
        # Error document key in S3 bucket
        attribute :key, Resources::Types::String

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate that key doesn't start with /
          if attrs.key.start_with?('/')
            raise Dry::Struct::Error, "Error document key should not start with '/': #{attrs.key}"
          end
          
          # Validate that key looks like an HTML file for common cases
          unless attrs.key.match?(/\.(html|htm)$/i) || attrs.key == 'error.html' || attrs.key.include?('error')
            warn "Error document key '#{attrs.key}' doesn't appear to be an HTML file. Consider using .html extension."
          end
          
          attrs
        end

        # Helper methods
        def html_file?
          key.match?(/\.(html|htm)$/i)
        end

        def in_subdirectory?
          key.include?('/')
        end

        def filename
          key.split('/').last
        end

        def directory
          parts = key.split('/')
          parts.length > 1 ? parts[0..-2].join('/') : ''
        end
      end

      # S3 website index document configuration
      class WebsiteIndexDocument < Dry::Struct
        # Index document suffix (typically "index.html")
        attribute :suffix, Resources::Types::String

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate that suffix doesn't start with /
          if attrs.suffix.start_with?('/')
            raise Dry::Struct::Error, "Index document suffix should not start with '/': #{attrs.suffix}"
          end
          
          # Warn if not using common index file names
          unless %w[index.html index.htm default.html default.htm].include?(attrs.suffix.downcase)
            warn "Index document suffix '#{attrs.suffix}' is not a common index file name. Consider 'index.html'."
          end
          
          attrs
        end

        # Helper methods
        def html_file?
          suffix.match?(/\.(html|htm)$/i)
        end

        def common_index_file?
          %w[index.html index.htm default.html default.htm].include?(suffix.downcase)
        end

        def filename
          suffix.split('/').last
        end
      end

      # S3 website redirect all requests configuration
      class WebsiteRedirectAllRequestsTo < Dry::Struct
        # Target hostname for redirects
        attribute :host_name, Resources::Types::String
        
        # Protocol for redirects (optional, defaults to same protocol)
        attribute :protocol, Resources::Types::String.enum("http", "https").optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate hostname format
          unless attrs.host_name.match?(/^[a-zA-Z0-9][a-zA-Z0-9\-\.]*[a-zA-Z0-9]$/)
            raise Dry::Struct::Error, "Invalid hostname format: #{attrs.host_name}"
          end
          
          # Warn if using HTTP in production-like hostname
          if attrs.protocol == "http" && !attrs.host_name.match?(/^(localhost|127\.0\.0\.1|.*\.local|.*\.dev)/)
            warn "Using HTTP protocol for production hostname '#{attrs.host_name}' may be insecure. Consider HTTPS."
          end
          
          attrs
        end

        # Helper methods
        def uses_https?
          protocol == "https"
        end

        def uses_http?
          protocol == "http"
        end

        def same_protocol?
          protocol.nil?
        end

        def localhost?
          host_name.match?(/^(localhost|127\.0\.0\.1|.*\.local|.*\.dev)/)
        end

        def target_url(path = "")
          protocol_part = protocol ? "#{protocol}://" : "//"
          "#{protocol_part}#{host_name}#{path}"
        end
      end

      # S3 website routing rule condition
      class WebsiteRoutingRuleCondition < Dry::Struct
        # HTTP error code to match (optional)
        attribute :http_error_code_returned_equals, Resources::Types::String.optional
        
        # Key prefix to match (optional)
        attribute :key_prefix_equals, Resources::Types::String.optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Must specify at least one condition
          if !attrs.http_error_code_returned_equals && !attrs.key_prefix_equals
            raise Dry::Struct::Error, "Must specify at least one routing rule condition"
          end
          
          # Validate HTTP error code format
          if attrs.http_error_code_returned_equals
            unless attrs.http_error_code_returned_equals.match?(/^[1-5]\d{2}$/)
              raise Dry::Struct::Error, "Invalid HTTP error code: #{attrs.http_error_code_returned_equals}"
            end
          end
          
          # Validate key prefix format
          if attrs.key_prefix_equals && attrs.key_prefix_equals.start_with?('/')
            raise Dry::Struct::Error, "Key prefix should not start with '/': #{attrs.key_prefix_equals}"
          end
          
          attrs
        end

        # Helper methods
        def matches_error_code?
          !http_error_code_returned_equals.nil?
        end

        def matches_key_prefix?
          !key_prefix_equals.nil?
        end

        def error_code
          http_error_code_returned_equals&.to_i
        end

        def client_error?
          error_code && error_code >= 400 && error_code < 500
        end

        def server_error?
          error_code && error_code >= 500 && error_code < 600
        end
      end

      # S3 website routing rule redirect
      class WebsiteRoutingRuleRedirect < Dry::Struct
        # Target hostname (optional)
        attribute :host_name, Resources::Types::String.optional
        
        # HTTP redirect code (optional)
        attribute :http_redirect_code, Resources::Types::String.optional
        
        # Protocol (optional)
        attribute :protocol, Resources::Types::String.enum("http", "https").optional
        
        # Replace key prefix with this value (optional)
        attribute :replace_key_prefix_with, Resources::Types::String.optional
        
        # Replace entire key with this value (optional)
        attribute :replace_key_with, Resources::Types::String.optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Cannot specify both replace_key_prefix_with and replace_key_with
          if attrs.replace_key_prefix_with && attrs.replace_key_with
            raise Dry::Struct::Error, "Cannot specify both 'replace_key_prefix_with' and 'replace_key_with'"
          end
          
          # Validate HTTP redirect code
          if attrs.http_redirect_code
            unless %w[301 302 303 307 308].include?(attrs.http_redirect_code)
              raise Dry::Struct::Error, "Invalid HTTP redirect code: #{attrs.http_redirect_code}. Use 301, 302, 303, 307, or 308"
            end
          end
          
          # Validate hostname format if present
          if attrs.host_name && !attrs.host_name.match?(/^[a-zA-Z0-9][a-zA-Z0-9\-\.]*[a-zA-Z0-9]$/)
            raise Dry::Struct::Error, "Invalid hostname format: #{attrs.host_name}"
          end
          
          # Validate key replacements don't start with /
          if attrs.replace_key_prefix_with&.start_with?('/')
            raise Dry::Struct::Error, "Replace key prefix should not start with '/': #{attrs.replace_key_prefix_with}"
          end
          
          if attrs.replace_key_with&.start_with?('/')
            raise Dry::Struct::Error, "Replace key should not start with '/': #{attrs.replace_key_with}"
          end
          
          attrs
        end

        # Helper methods
        def permanent_redirect?
          http_redirect_code == "301"
        end

        def temporary_redirect?
          %w[302 303 307 308].include?(http_redirect_code)
        end

        def replaces_key_prefix?
          !replace_key_prefix_with.nil?
        end

        def replaces_entire_key?
          !replace_key_with.nil?
        end

        def changes_host?
          !host_name.nil?
        end

        def changes_protocol?
          !protocol.nil?
        end

        def redirect_code_number
          http_redirect_code&.to_i
        end
      end

      # S3 website routing rule
      class WebsiteRoutingRule < Dry::Struct
        # Condition for when this rule applies (optional)
        attribute? :condition, WebsiteRoutingRuleCondition.optional
        
        # Redirect configuration for this rule
        attribute :redirect, WebsiteRoutingRuleRedirect

        # Helper methods
        def has_condition?
          !condition.nil?
        end

        def unconditional?
          condition.nil?
        end

        def error_code_rule?
          condition&.matches_error_code?
        end

        def prefix_rule?
          condition&.matches_key_prefix?
        end
      end

      # Type-safe attributes for AWS S3 Bucket Website Configuration
      class S3BucketWebsiteConfigurationAttributes < Dry::Struct
        # S3 bucket to configure for static website hosting
        attribute :bucket, Resources::Types::String
        
        # Expected bucket owner (optional)
        attribute :expected_bucket_owner, Resources::Types::String.optional
        
        # Error document configuration (optional)
        attribute? :error_document, WebsiteErrorDocument.optional
        
        # Index document configuration (optional)
        attribute? :index_document, WebsiteIndexDocument.optional
        
        # Redirect all requests configuration (optional)
        attribute? :redirect_all_requests_to, WebsiteRedirectAllRequestsTo.optional
        
        # Routing rules (optional, max 50 rules)
        attribute :routing_rule, Resources::Types::Array.of(WebsiteRoutingRule).constrained(max_size: 50).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Must specify either website hosting OR redirect all requests, not both
          has_website_config = attrs.index_document || attrs.error_document || attrs.routing_rule
          has_redirect_all = attrs.redirect_all_requests_to
          
          if has_website_config && has_redirect_all
            raise Dry::Struct::Error, "Cannot specify both website hosting configuration and redirect_all_requests_to"
          end
          
          if !has_website_config && !has_redirect_all
            raise Dry::Struct::Error, "Must specify either website hosting configuration (index_document) or redirect_all_requests_to"
          end
          
          # If using website hosting, index_document is required
          if has_website_config && !attrs.index_document
            raise Dry::Struct::Error, "index_document is required when using website hosting configuration"
          end
          
          attrs
        end

        # Helper methods
        def website_hosting_mode?
          !index_document.nil?
        end

        def redirect_all_mode?
          !redirect_all_requests_to.nil?
        end

        def has_error_document?
          !error_document.nil?
        end

        def has_routing_rules?
          !routing_rule.nil? && routing_rule.any?
        end

        def routing_rules_count
          routing_rule&.length || 0
        end

        def unconditional_routing_rules
          routing_rule&.select(&:unconditional?) || []
        end

        def error_code_routing_rules
          routing_rule&.select(&:error_code_rule?) || []
        end

        def prefix_routing_rules
          routing_rule&.select(&:prefix_rule?) || []
        end

        def permanent_redirect_rules
          routing_rule&.select { |rule| rule.redirect.permanent_redirect? } || []
        end

        def temporary_redirect_rules
          routing_rule&.select { |rule| rule.redirect.temporary_redirect? } || []
        end
      end
    end
      end
    end
  end
end