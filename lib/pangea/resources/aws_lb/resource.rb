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
require 'pangea/resources/aws_lb/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Application/Network Load Balancer with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Load balancer attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_lb(name, attributes = {})
        # Validate attributes using dry-struct
        lb_attrs = Types::LoadBalancerAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_lb, name) do
          name lb_attrs.name if lb_attrs.name
          load_balancer_type lb_attrs.load_balancer_type
          internal lb_attrs.internal
          
          # Subnets are required for ALB/NLB
          if lb_attrs.subnet_ids.any?
            subnets lb_attrs.subnet_ids
          end
          
          # Security groups (ALB only)
          if lb_attrs.security_groups.any? && lb_attrs.load_balancer_type == "application"
            security_groups lb_attrs.security_groups
          end
          
          # IP address type
          ip_address_type lb_attrs.ip_address_type if lb_attrs.ip_address_type
          
          # Enable deletion protection
          enable_deletion_protection lb_attrs.enable_deletion_protection
          
          # Enable cross-zone load balancing (NLB only)
          if lb_attrs.load_balancer_type == "network" && !lb_attrs.enable_cross_zone_load_balancing.nil?
            enable_cross_zone_load_balancing lb_attrs.enable_cross_zone_load_balancing
          end
          
          # Access logs configuration
          if lb_attrs.access_logs
            access_logs do
              bucket lb_attrs.access_logs[:bucket]
              enabled lb_attrs.access_logs[:enabled]
              prefix lb_attrs.access_logs[:prefix] if lb_attrs.access_logs[:prefix]
            end
          end
          
          # Apply tags if present
          if lb_attrs.tags.any?
            tags do
              lb_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_lb',
          name: name,
          resource_attributes: lb_attrs.to_h,
          outputs: {
            id: "${aws_lb.#{name}.id}",
            arn: "${aws_lb.#{name}.arn}",
            arn_suffix: "${aws_lb.#{name}.arn_suffix}",
            dns_name: "${aws_lb.#{name}.dns_name}",
            zone_id: "${aws_lb.#{name}.zone_id}",
            canonical_hosted_zone_id: "${aws_lb.#{name}.canonical_hosted_zone_id}",
            vpc_id: "${aws_lb.#{name}.vpc_id}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:is_application_load_balancer?) { lb_attrs.load_balancer_type == 'application' }
        ref.define_singleton_method(:is_network_load_balancer?) { lb_attrs.load_balancer_type == 'network' }
        ref.define_singleton_method(:is_gateway_load_balancer?) { lb_attrs.load_balancer_type == 'gateway' }
        ref.define_singleton_method(:is_internal?) { lb_attrs.internal }
        ref.define_singleton_method(:supports_security_groups?) { lb_attrs.load_balancer_type == 'application' }
        ref.define_singleton_method(:supports_cross_zone_load_balancing?) { lb_attrs.load_balancer_type == 'network' }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)