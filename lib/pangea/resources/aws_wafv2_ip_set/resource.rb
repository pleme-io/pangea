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
require 'pangea/resources/aws_wafv2_ip_set/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS WAF v2 IP Set for IP-based allow/deny lists
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] WAF v2 IP Set attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_wafv2_ip_set(name, attributes = {})
        # Validate attributes using dry-struct
        ip_set_attrs = Types::WafV2IpSetAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_wafv2_ip_set, name) do
          name ip_set_attrs.name
          scope ip_set_attrs.scope.downcase
          ip_address_version ip_set_attrs.ip_address_version
          
          # Description if provided
          if ip_set_attrs.description
            description ip_set_attrs.description
          end
          
          # IP addresses
          addresses ip_set_attrs.addresses
          
          # Apply tags if present
          if ip_set_attrs.tags.any?
            tags do
              ip_set_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_wafv2_ip_set',
          name: name,
          resource_attributes: ip_set_attrs.to_h,
          outputs: {
            id: "${aws_wafv2_ip_set.#{name}.id}",
            arn: "${aws_wafv2_ip_set.#{name}.arn}",
            lock_token: "${aws_wafv2_ip_set.#{name}.lock_token}"
          },
          computed: {
            address_count: ip_set_attrs.address_count,
            has_cidr_blocks: ip_set_attrs.has_cidr_blocks?,
            has_individual_ips: ip_set_attrs.has_individual_ips?,
            estimated_ip_count: ip_set_attrs.estimated_ip_count,
            ip_version: ip_set_attrs.ip_address_version,
            scope: ip_set_attrs.scope
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)