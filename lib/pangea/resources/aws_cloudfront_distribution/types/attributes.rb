# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'validation'
require_relative 'instance_methods'

module Pangea
  module Resources
    module AWS
      module Types
        class CloudFrontDistributionAttributes < Dry::Struct
          include CloudFrontDistributionMethods
          transform_keys(&:to_sym)

          attribute :origin, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::Hash).constrained(min_size: 1)
          attribute :default_cache_behavior, Pangea::Resources::Types::Hash
          attribute :ordered_cache_behavior, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::Hash).default([].freeze)
          attribute :comment, Pangea::Resources::Types::String.default('')
          attribute? :default_root_object, Pangea::Resources::Types::String.optional
          attribute :enabled, Pangea::Resources::Types::Bool.default(true)
          attribute :http_version, Pangea::Resources::Types::String.constrained(included_in: %w[http1.1 http2]).default('http2')
          attribute :is_ipv6_enabled, Pangea::Resources::Types::Bool.default(true)
          attribute :price_class, Pangea::Resources::Types::String.constrained(included_in: %w[PriceClass_All PriceClass_200 PriceClass_100]).default('PriceClass_All')
          attribute :custom_error_response, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::Hash).default([].freeze)
          attribute :restrictions, Pangea::Resources::Types::Hash.default({ geo_restriction: { restriction_type: 'none', locations: [] } })
          attribute :viewer_certificate, Pangea::Resources::Types::Hash.default({}.freeze)
          attribute :aliases, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          attribute? :web_acl_id, Pangea::Resources::Types::String.optional
          attribute :retain_on_delete, Pangea::Resources::Types::Bool.default(false)
          attribute :wait_for_deployment, Pangea::Resources::Types::Bool.default(true)
          attribute :tags, Pangea::Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            CloudFrontDistributionValidation.validate_origin_references(attrs)
            CloudFrontDistributionValidation.validate_ssl_configuration(attrs.viewer_certificate, attrs.aliases)
            CloudFrontDistributionValidation.validate_geo_restrictions(attrs.restrictions[:geo_restriction])
            CloudFrontDistributionValidation.validate_custom_error_responses(attrs.custom_error_response)
            CloudFrontDistributionValidation.validate_function_associations(attrs)
            attrs
          end
        end
      end
    end
  end
end
