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
require 'pangea/resources/aws_route53_record/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Route53 Record with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Route53 record attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_route53_record(name, attributes = {})
        # Validate attributes using dry-struct
        record_attrs = AWS::Types::Types::Route53RecordAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_route53_record, name) do
          zone_id record_attrs.zone_id
          name record_attrs.name
          type record_attrs.type
          
          # Simple record configuration
          if !record_attrs.is_alias_record?
            ttl record_attrs.ttl
            records record_attrs.records if record_attrs.records.any?
          end
          
          # Alias record configuration
          if record_attrs.alias
            alias_block = record_attrs.alias
            _alias do  # Use _alias since 'alias' is a Ruby keyword
              name alias_block[:name]
              zone_id alias_block[:zone_id]
              evaluate_target_health alias_block[:evaluate_target_health]
            end
          end
          
          # Routing policies
          if record_attrs.weighted_routing_policy
            weighted_routing_policy do
              weight record_attrs.weighted_routing_policy[:weight]
            end
          end
          
          if record_attrs.latency_routing_policy
            latency_routing_policy do
              region record_attrs.latency_routing_policy[:region]
            end
          end
          
          if record_attrs.failover_routing_policy
            failover_routing_policy do
              type record_attrs.failover_routing_policy[:type]
            end
          end
          
          if record_attrs.geolocation_routing_policy
            geolocation_routing_policy do
              geo_policy = record_attrs.geolocation_routing_policy
              continent geo_policy[:continent] if geo_policy[:continent]
              country geo_policy[:country] if geo_policy[:country]
              subdivision geo_policy[:subdivision] if geo_policy[:subdivision]
            end
          end
          
          if record_attrs.geoproximity_routing_policy
            geoproximity_routing_policy do
              geo_prox = record_attrs.geoproximity_routing_policy
              aws_region geo_prox[:aws_region] if geo_prox[:aws_region]
              bias geo_prox[:bias] if geo_prox[:bias]
              if geo_prox[:coordinates]
                coordinates do
                  latitude geo_prox[:coordinates][:latitude]
                  longitude geo_prox[:coordinates][:longitude]
                end
              end
            end
          end
          
          # Additional configurations
          set_identifier record_attrs.set_identifier if record_attrs.set_identifier
          health_check_id record_attrs.health_check_id if record_attrs.health_check_id
          multivalue_answer record_attrs.multivalue_answer if record_attrs.multivalue_answer
          allow_overwrite record_attrs.allow_overwrite if record_attrs.allow_overwrite
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_route53_record',
          name: name,
          resource_attributes: record_attrs.to_h,
          outputs: {
            id: "${aws_route53_record.#{name}.id}",
            name: "${aws_route53_record.#{name}.name}",
            fqdn: "${aws_route53_record.#{name}.fqdn}",
            type: "${aws_route53_record.#{name}.type}",
            zone_id: "${aws_route53_record.#{name}.zone_id}",
            records: "${aws_route53_record.#{name}.records}",
            ttl: "${aws_route53_record.#{name}.ttl}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:is_alias_record?) { record_attrs.is_alias_record? }
        ref.define_singleton_method(:is_simple_record?) { record_attrs.is_simple_record? }
        ref.define_singleton_method(:routing_policy_type) { record_attrs.routing_policy_type }
        ref.define_singleton_method(:has_routing_policy?) { record_attrs.has_routing_policy? }
        ref.define_singleton_method(:is_wildcard_record?) { record_attrs.is_wildcard_record? }
        ref.define_singleton_method(:record_count) { record_attrs.record_count }
        ref.define_singleton_method(:domain_name) { record_attrs.domain_name }
        ref.define_singleton_method(:estimated_query_cost_per_million) { record_attrs.estimated_query_cost_per_million }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)