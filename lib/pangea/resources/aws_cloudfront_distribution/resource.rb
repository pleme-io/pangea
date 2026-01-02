# frozen_string_literal: true

# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cloudfront_distribution/types'
require 'pangea/resource_registry'
require_relative 'builders/origin_builder'
require_relative 'builders/cache_behavior_builder'
require_relative 'builders/settings_builder'
require_relative 'builders/reference_builder'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudFront Distribution with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudFront distribution attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cloudfront_distribution(name, attributes = {})
        distribution_attrs = AWS::Types::Types::CloudFrontDistributionAttributes.new(attributes)

        resource(:aws_cloudfront_distribution, name) do
          build_distribution(self, distribution_attrs)
        end

        CloudFrontDistribution::ReferenceBuilder.build_reference(name, distribution_attrs)
      end

      private

      def build_distribution(context, attrs)
        CloudFrontDistribution::OriginBuilder.build_origins(context, attrs.origin)
        CloudFrontDistribution::CacheBehaviorBuilder.build_default_cache_behavior(context, attrs.default_cache_behavior)
        CloudFrontDistribution::CacheBehaviorBuilder.build_ordered_cache_behaviors(context, attrs.ordered_cache_behavior)
        CloudFrontDistribution::SettingsBuilder.build_basic_settings(context, attrs)
        CloudFrontDistribution::SettingsBuilder.build_custom_error_responses(context, attrs.custom_error_response)
        CloudFrontDistribution::SettingsBuilder.build_restrictions(context, attrs.restrictions)
        CloudFrontDistribution::SettingsBuilder.build_viewer_certificate(context, attrs.viewer_certificate)
        CloudFrontDistribution::SettingsBuilder.build_tags(context, attrs.tags)
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
