# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'documents'
require_relative 'redirect'
require_relative 'routing_rules'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS S3 Bucket Website Configuration
        class S3BucketWebsiteConfigurationAttributes < Dry::Struct
          attribute :bucket, Resources::Types::String
          attribute :expected_bucket_owner, Resources::Types::String.optional
          attribute? :error_document, WebsiteErrorDocument.optional
          attribute? :index_document, WebsiteIndexDocument.optional
          attribute? :redirect_all_requests_to, WebsiteRedirectAllRequestsTo.optional
          attribute :routing_rule, Resources::Types::Array.of(WebsiteRoutingRule).constrained(max_size: 50).optional

          def self.new(attributes = {})
            attrs = super(attributes)

            has_website_config = attrs.index_document || attrs.error_document || attrs.routing_rule
            has_redirect_all = attrs.redirect_all_requests_to

            if has_website_config && has_redirect_all
              raise Dry::Struct::Error, "Cannot specify both website hosting configuration and redirect_all_requests_to"
            end

            if !has_website_config && !has_redirect_all
              raise Dry::Struct::Error, "Must specify either website hosting configuration (index_document) or redirect_all_requests_to"
            end

            if has_website_config && !attrs.index_document
              raise Dry::Struct::Error, "index_document is required when using website hosting configuration"
            end

            attrs
          end

          def website_hosting_mode? = !index_document.nil?
          def redirect_all_mode? = !redirect_all_requests_to.nil?
          def has_error_document? = !error_document.nil?
          def has_routing_rules? = !routing_rule.nil? && routing_rule.any?
          def routing_rules_count = routing_rule&.length || 0
          def unconditional_routing_rules = routing_rule&.select(&:unconditional?) || []
          def error_code_routing_rules = routing_rule&.select(&:error_code_rule?) || []
          def prefix_routing_rules = routing_rule&.select(&:prefix_rule?) || []
          def permanent_redirect_rules = routing_rule&.select { |rule| rule.redirect.permanent_redirect? } || []
          def temporary_redirect_rules = routing_rule&.select { |rule| rule.redirect.temporary_redirect? } || []
        end
      end
    end
  end
end
