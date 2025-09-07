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


require 'pangea/resources/reference'
require 'pangea/resources/aws_api_gateway_integration/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # AWS API Gateway Integration resource function
      # Creates backend integrations for API Gateway methods
      def aws_api_gateway_integration(name, attributes = {})
        # Validate and coerce attributes
        integration_attrs = AWS::Types::Types::ApiGatewayIntegrationAttributes.new(attributes)
        
        # Generate Terraform resource block
        resource(:aws_api_gateway_integration, name) do
          rest_api_id integration_attrs.rest_api_id
          resource_id integration_attrs.resource_id
          http_method integration_attrs.http_method
          type integration_attrs.type
          
          # Integration HTTP method (required for HTTP/AWS integrations)
          if integration_attrs.integration_http_method
            integration_http_method integration_attrs.integration_http_method
          end
          
          # URI (required for non-MOCK integrations)
          if integration_attrs.uri
            uri integration_attrs.uri
          end
          
          # Connection configuration
          connection_type integration_attrs.connection_type
          if integration_attrs.connection_id
            connection_id integration_attrs.connection_id
          end
          
          # Credentials for AWS integrations
          if integration_attrs.credentials
            credentials integration_attrs.credentials
          end
          
          # Caching configuration
          if integration_attrs.cache_key_parameters.any?
            cache_key_parameters integration_attrs.cache_key_parameters
          end
          
          if integration_attrs.cache_namespace
            cache_namespace integration_attrs.cache_namespace
          end
          
          # Request templates
          if integration_attrs.request_templates.any?
            request_templates do
              integration_attrs.request_templates.each do |content_type, template|
                send(content_type.tr('/', '_').tr('-', '_'), template)
              end
            end
          end
          
          # Request parameter mapping
          if integration_attrs.request_parameters.any?
            request_parameters do
              integration_attrs.request_parameters.each do |integration_param, method_param|
                send(integration_param.tr('.', '_').tr('-', '_'), method_param)
              end
            end
          end
          
          # Passthrough behavior
          passthrough_behavior integration_attrs.passthrough_behavior
          
          # Content handling
          if integration_attrs.content_handling
            content_handling integration_attrs.content_handling
          end
          
          # Timeout
          timeout_milliseconds integration_attrs.timeout_milliseconds
        end
        
        # Create ResourceReference with outputs and computed properties
        ref = ResourceReference.new(
          type: 'aws_api_gateway_integration',
          name: name,
          resource_attributes: integration_attrs.to_h,
          outputs: {
            # Standard Terraform outputs
            rest_api_id: "${aws_api_gateway_integration.#{name}.rest_api_id}",
            resource_id: "${aws_api_gateway_integration.#{name}.resource_id}",
            http_method: "${aws_api_gateway_integration.#{name}.http_method}",
            type: "${aws_api_gateway_integration.#{name}.type}",
            integration_http_method: "${aws_api_gateway_integration.#{name}.integration_http_method}",
            uri: "${aws_api_gateway_integration.#{name}.uri}",
            connection_type: "${aws_api_gateway_integration.#{name}.connection_type}",
            connection_id: "${aws_api_gateway_integration.#{name}.connection_id}",
            credentials: "${aws_api_gateway_integration.#{name}.credentials}",
            cache_key_parameters: "${aws_api_gateway_integration.#{name}.cache_key_parameters}",
            cache_namespace: "${aws_api_gateway_integration.#{name}.cache_namespace}",
            request_parameters: "${aws_api_gateway_integration.#{name}.request_parameters}",
            request_templates: "${aws_api_gateway_integration.#{name}.request_templates}",
            passthrough_behavior: "${aws_api_gateway_integration.#{name}.passthrough_behavior}",
            content_handling: "${aws_api_gateway_integration.#{name}.content_handling}",
            timeout_milliseconds: "${aws_api_gateway_integration.#{name}.timeout_milliseconds}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:is_proxy_integration?) { integration_attrs.is_proxy_integration? }
        ref.define_singleton_method(:is_lambda_integration?) { integration_attrs.is_lambda_integration? }
        ref.define_singleton_method(:is_http_integration?) { integration_attrs.is_http_integration? }
        ref.define_singleton_method(:is_aws_service_integration?) { integration_attrs.is_aws_service_integration? }
        ref.define_singleton_method(:is_mock_integration?) { integration_attrs.is_mock_integration? }
        ref.define_singleton_method(:uses_vpc_link?) { integration_attrs.uses_vpc_link? }
        ref.define_singleton_method(:has_caching?) { integration_attrs.has_caching? }
        ref.define_singleton_method(:requires_iam_role?) { integration_attrs.requires_iam_role? }
        ref.define_singleton_method(:lambda_function_name) { integration_attrs.lambda_function_name }
        ref.define_singleton_method(:aws_service_name) { integration_attrs.aws_service_name }
        
        # Add convenience methods
        ref.define_singleton_method(:integration_type) { integration_attrs.type }
        ref.define_singleton_method(:backend_uri) { integration_attrs.uri }
        ref.define_singleton_method(:timeout_seconds) { integration_attrs.timeout_milliseconds / 1000.0 }
        
        # Integration-specific helpers
        ref.define_singleton_method(:cache_configuration) do
          {
            enabled: integration_attrs.has_caching?,
            key_parameters: integration_attrs.cache_key_parameters,
            namespace: integration_attrs.cache_namespace
          }
        end
        
        ref.define_singleton_method(:request_configuration) do
          {
            templates: integration_attrs.request_templates,
            parameters: integration_attrs.request_parameters,
            passthrough: integration_attrs.passthrough_behavior
          }
        end
        
        ref.define_singleton_method(:connection_configuration) do
          {
            type: integration_attrs.connection_type,
            id: integration_attrs.connection_id,
            uses_vpc: integration_attrs.uses_vpc_link?
          }
        end
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)