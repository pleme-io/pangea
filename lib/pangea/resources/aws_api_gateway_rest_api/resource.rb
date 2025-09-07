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
require 'pangea/resources/aws_api_gateway_rest_api/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # AWS API Gateway REST API resource implementation
      # Provides type-safe function for creating REST APIs with API Gateway
      def aws_api_gateway_rest_api(name, attributes = {})
        # Validate attributes using dry-struct
        validated_attrs = AWS::Types::Types::ApiGatewayRestApiAttributes.new(attributes)
        
        # Synthesize the Terraform resource
        resource :aws_api_gateway_rest_api, name do
          # Core configuration
          name validated_attrs.name
          description validated_attrs.description if validated_attrs.description
          
          # Endpoint configuration
          if validated_attrs.endpoint_configuration
            endpoint_configuration do
              types validated_attrs.endpoint_configuration[:types]
              vpc_endpoint_ids validated_attrs.endpoint_configuration[:vpc_endpoint_ids] if validated_attrs.endpoint_configuration[:vpc_endpoint_ids]
            end
          end
          
          # API settings
          version validated_attrs.version if validated_attrs.version
          clone_from validated_attrs.clone_from if validated_attrs.clone_from
          binary_media_types validated_attrs.binary_media_types unless validated_attrs.binary_media_types.empty?
          minimum_compression_size validated_attrs.minimum_compression_size if validated_attrs.minimum_compression_size
          api_key_source validated_attrs.api_key_source
          disable_execute_api_endpoint validated_attrs.disable_execute_api_endpoint
          
          # Security
          policy validated_attrs.policy if validated_attrs.policy
          minimum_tls_version validated_attrs.minimum_tls_version
          
          # OpenAPI/Swagger
          body validated_attrs.body if validated_attrs.body
          
          # Tags
          tags validated_attrs.tags unless validated_attrs.tags.empty?
        end
        
        # Create reference that will be returned
        ref = ResourceReference.new(
          type: 'aws_api_gateway_rest_api',
          name: name,
          resource_attributes: validated_attrs.to_h,
          outputs: {
            id: "${aws_api_gateway_rest_api.#{name}.id}",
            root_resource_id: "${aws_api_gateway_rest_api.#{name}.root_resource_id}",
            created_date: "${aws_api_gateway_rest_api.#{name}.created_date}",
            execution_arn: "${aws_api_gateway_rest_api.#{name}.execution_arn}",
            arn: "${aws_api_gateway_rest_api.#{name}.arn}",
            tags_all: "${aws_api_gateway_rest_api.#{name}.tags_all}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:is_edge_optimized?) { validated_attrs.is_edge_optimized? }
        ref.define_singleton_method(:is_regional?) { validated_attrs.is_regional? }
        ref.define_singleton_method(:is_private?) { validated_attrs.is_private? }
        ref.define_singleton_method(:supports_binary_content?) { validated_attrs.supports_binary_content? }
        ref.define_singleton_method(:has_custom_domain?) { validated_attrs.has_custom_domain? }
        ref.define_singleton_method(:estimated_monthly_cost) { validated_attrs.estimated_monthly_cost }
        
        # Return the reference
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)