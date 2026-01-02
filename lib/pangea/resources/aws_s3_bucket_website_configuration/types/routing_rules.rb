# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # S3 website routing rule condition
        class WebsiteRoutingRuleCondition < Dry::Struct
          attribute :http_error_code_returned_equals, Resources::Types::String.optional
          attribute :key_prefix_equals, Resources::Types::String.optional

          def self.new(attributes = {})
            attrs = super(attributes)

            if !attrs.http_error_code_returned_equals && !attrs.key_prefix_equals
              raise Dry::Struct::Error, "Must specify at least one routing rule condition"
            end

            if attrs.http_error_code_returned_equals
              unless attrs.http_error_code_returned_equals.match?(/^[1-5]\d{2}$/)
                raise Dry::Struct::Error, "Invalid HTTP error code: #{attrs.http_error_code_returned_equals}"
              end
            end

            if attrs.key_prefix_equals && attrs.key_prefix_equals.start_with?('/')
              raise Dry::Struct::Error, "Key prefix should not start with '/': #{attrs.key_prefix_equals}"
            end

            attrs
          end

          def matches_error_code? = !http_error_code_returned_equals.nil?
          def matches_key_prefix? = !key_prefix_equals.nil?
          def error_code = http_error_code_returned_equals&.to_i
          def client_error? = error_code && error_code >= 400 && error_code < 500
          def server_error? = error_code && error_code >= 500 && error_code < 600
        end

        # S3 website routing rule redirect
        class WebsiteRoutingRuleRedirect < Dry::Struct
          attribute :host_name, Resources::Types::String.optional
          attribute :http_redirect_code, Resources::Types::String.optional
          attribute :protocol, Resources::Types::String.enum("http", "https").optional
          attribute :replace_key_prefix_with, Resources::Types::String.optional
          attribute :replace_key_with, Resources::Types::String.optional

          def self.new(attributes = {})
            attrs = super(attributes)

            if attrs.replace_key_prefix_with && attrs.replace_key_with
              raise Dry::Struct::Error, "Cannot specify both 'replace_key_prefix_with' and 'replace_key_with'"
            end

            if attrs.http_redirect_code
              unless %w[301 302 303 307 308].include?(attrs.http_redirect_code)
                raise Dry::Struct::Error, "Invalid HTTP redirect code: #{attrs.http_redirect_code}. Use 301, 302, 303, 307, or 308"
              end
            end

            if attrs.host_name && !attrs.host_name.match?(/^[a-zA-Z0-9][a-zA-Z0-9\-\.]*[a-zA-Z0-9]$/)
              raise Dry::Struct::Error, "Invalid hostname format: #{attrs.host_name}"
            end

            if attrs.replace_key_prefix_with&.start_with?('/')
              raise Dry::Struct::Error, "Replace key prefix should not start with '/': #{attrs.replace_key_prefix_with}"
            end

            if attrs.replace_key_with&.start_with?('/')
              raise Dry::Struct::Error, "Replace key should not start with '/': #{attrs.replace_key_with}"
            end

            attrs
          end

          def permanent_redirect? = http_redirect_code == "301"
          def temporary_redirect? = %w[302 303 307 308].include?(http_redirect_code)
          def replaces_key_prefix? = !replace_key_prefix_with.nil?
          def replaces_entire_key? = !replace_key_with.nil?
          def changes_host? = !host_name.nil?
          def changes_protocol? = !protocol.nil?
          def redirect_code_number = http_redirect_code&.to_i
        end

        # S3 website routing rule
        class WebsiteRoutingRule < Dry::Struct
          attribute? :condition, WebsiteRoutingRuleCondition.optional
          attribute :redirect, WebsiteRoutingRuleRedirect

          def has_condition? = !condition.nil?
          def unconditional? = condition.nil?
          def error_code_rule? = condition&.matches_error_code?
          def prefix_rule? = condition&.matches_key_prefix?
        end
      end
    end
  end
end
