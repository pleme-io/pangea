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
require 'pangea/resources/aws_route53_delegation_set/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Route53 Delegation Set with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Route53 delegation set attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_route53_delegation_set(name, attributes = {})
        # Validate attributes using dry-struct
        delegation_set_attrs = Types::Route53DelegationSetAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_route53_delegation_set, name) do
          reference_name delegation_set_attrs.reference_name if delegation_set_attrs.reference_name
          
          # Apply tags if present
          if delegation_set_attrs.tags.any?
            tags do
              delegation_set_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_route53_delegation_set',
          name: name,
          resource_attributes: delegation_set_attrs.to_h,
          outputs: {
            id: "${aws_route53_delegation_set.#{name}.id}",
            arn: "${aws_route53_delegation_set.#{name}.arn}",
            reference_name: "${aws_route53_delegation_set.#{name}.reference_name}",
            name_servers: "${aws_route53_delegation_set.#{name}.name_servers}",
            tags_all: "${aws_route53_delegation_set.#{name}.tags_all}"
          },
          computed_properties: {
            custom_delegation_set: delegation_set_attrs.custom_delegation_set?,
            delegation_set_type: delegation_set_attrs.delegation_set_type,
            configuration_warnings: delegation_set_attrs.validate_configuration,
            estimated_monthly_cost: delegation_set_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)