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
require 'pangea/resources/aws_api_gateway_api_key/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS API Gateway API Key with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] API Gateway API key attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_api_gateway_api_key(name, attributes = {})
        # Validate attributes using dry-struct
        api_key_attrs = Types::ApiGatewayApiKeyAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_api_gateway_api_key, name) do
          name api_key_attrs.name
          description api_key_attrs.description if api_key_attrs.description
          enabled api_key_attrs.enabled
          value api_key_attrs.value if api_key_attrs.value
          
          # Apply tags if present
          if api_key_attrs.tags.any?
            tags do
              api_key_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_api_gateway_api_key',
          name: name,
          resource_attributes: api_key_attrs.to_h,
          outputs: {
            id: "${aws_api_gateway_api_key.#{name}.id}",
            arn: "${aws_api_gateway_api_key.#{name}.arn}",
            name: "${aws_api_gateway_api_key.#{name}.name}",
            description: "${aws_api_gateway_api_key.#{name}.description}",
            enabled: "${aws_api_gateway_api_key.#{name}.enabled}",
            value: "${aws_api_gateway_api_key.#{name}.value}",
            created_date: "${aws_api_gateway_api_key.#{name}.created_date}",
            last_updated_date: "${aws_api_gateway_api_key.#{name}.last_updated_date}",
            tags_all: "${aws_api_gateway_api_key.#{name}.tags_all}"
          },
          computed_properties: {
            active: api_key_attrs.active?,
            disabled: api_key_attrs.disabled?,
            custom_value: api_key_attrs.custom_value?,
            auto_generated_value: api_key_attrs.auto_generated_value?,
            security_level: api_key_attrs.security_level,
            production_ready: api_key_attrs.production_ready?,
            status: api_key_attrs.status,
            key_type: api_key_attrs.key_type,
            configuration_warnings: api_key_attrs.validate_configuration,
            estimated_monthly_cost: api_key_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)