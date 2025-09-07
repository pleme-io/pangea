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
require 'pangea/resources/aws_route53_zone/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Route53 Hosted Zone with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Route53 hosted zone attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_route53_zone(name, attributes = {})
        # Validate attributes using dry-struct
        zone_attrs = AWS::Types::Route53ZoneAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_route53_zone, name) do
          name zone_attrs.name
          comment zone_attrs.comment if zone_attrs.comment
          delegation_set_id zone_attrs.delegation_set_id if zone_attrs.delegation_set_id
          force_destroy zone_attrs.force_destroy if zone_attrs.force_destroy
          
          # VPC configuration for private hosted zones
          if zone_attrs.vpc.any?
            zone_attrs.vpc.each do |vpc_config|
              vpc do
                vpc_id vpc_config[:vpc_id]
                vpc_region vpc_config[:vpc_region] if vpc_config[:vpc_region]
              end
            end
          end
          
          # Apply tags if present
          if zone_attrs.tags.any?
            tags do
              zone_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_route53_zone',
          name: name,
          resource_attributes: zone_attrs.to_h,
          outputs: {
            id: "${aws_route53_zone.#{name}.id}",
            zone_id: "${aws_route53_zone.#{name}.zone_id}",
            arn: "${aws_route53_zone.#{name}.arn}",
            name: "${aws_route53_zone.#{name}.name}",
            name_servers: "${aws_route53_zone.#{name}.name_servers}",
            primary_name_server: "${aws_route53_zone.#{name}.primary_name_server}",
            comment: "${aws_route53_zone.#{name}.comment}",
            tags_all: "${aws_route53_zone.#{name}.tags_all}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:is_private?) { zone_attrs.is_private? }
        ref.define_singleton_method(:is_public?) { zone_attrs.is_public? }
        ref.define_singleton_method(:zone_type) { zone_attrs.zone_type }
        ref.define_singleton_method(:vpc_count) { zone_attrs.vpc_count }
        ref.define_singleton_method(:domain_parts) { zone_attrs.domain_parts }
        ref.define_singleton_method(:top_level_domain) { zone_attrs.top_level_domain }
        ref.define_singleton_method(:subdomain?) { zone_attrs.subdomain? }
        ref.define_singleton_method(:root_domain?) { zone_attrs.root_domain? }
        ref.define_singleton_method(:aws_service_domain?) { zone_attrs.aws_service_domain? }
        ref.define_singleton_method(:parent_domain) { zone_attrs.parent_domain }
        ref.define_singleton_method(:configuration_warnings) { zone_attrs.validate_configuration }
        ref.define_singleton_method(:estimated_monthly_cost) { zone_attrs.estimated_monthly_cost }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)