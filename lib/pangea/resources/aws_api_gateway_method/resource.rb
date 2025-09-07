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
require_relative 'types'

module Pangea
  module Resources
    module AWS
      # AWS API Gateway Method implementation
      # Provides type-safe function for creating HTTP methods on API resources
      def aws_api_gateway_method(name, attributes = {})
        # Validate attributes using dry-struct
        validated_attrs = Types::Types::ApiGatewayMethodAttributes.new(attributes)
        
        # Synthesize the Terraform resource
        resource :aws_api_gateway_method, name do
          # Core configuration
          rest_api_id validated_attrs.rest_api_id
          resource_id validated_attrs.resource_id
          http_method validated_attrs.http_method
          
          # Authorization
          authorization validated_attrs.authorization
          authorizer_id validated_attrs.authorizer_id if validated_attrs.authorizer_id
          authorization_scopes validated_attrs.authorization_scopes unless validated_attrs.authorization_scopes.empty?
          
          # API Key
          api_key_required validated_attrs.api_key_required
          
          # Request configuration
          request_parameters validated_attrs.request_parameters unless validated_attrs.request_parameters.empty?
          request_models validated_attrs.request_models unless validated_attrs.request_models.empty?
          request_validator_id validated_attrs.request_validator_id if validated_attrs.request_validator_id
          
          # Operation name
          operation_name validated_attrs.operation_name if validated_attrs.operation_name
        end
        
        # Create and return ResourceReference
        ref = ResourceReference.new(
          type: 'aws_api_gateway_method',
          name: name,
          resource_attributes: validated_attrs.to_h,
          outputs: {
            id: "${aws_api_gateway_method.#{name}.id}",
            rest_api_id: "${aws_api_gateway_method.#{name}.rest_api_id}",
            resource_id: "${aws_api_gateway_method.#{name}.resource_id}",
            http_method: "${aws_api_gateway_method.#{name}.http_method}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:requires_authorization?) { validated_attrs.requires_authorization? }
        ref.define_singleton_method(:is_cognito_authorized?) { validated_attrs.is_cognito_authorized? }
        ref.define_singleton_method(:is_iam_authorized?) { validated_attrs.is_iam_authorized? }
        ref.define_singleton_method(:is_custom_authorized?) { validated_attrs.is_custom_authorized? }
        ref.define_singleton_method(:has_request_validation?) { validated_attrs.has_request_validation? }
        ref.define_singleton_method(:cors_enabled?) { validated_attrs.cors_enabled? }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)