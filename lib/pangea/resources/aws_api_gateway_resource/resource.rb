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
      # AWS API Gateway Resource implementation
      # Provides type-safe function for creating API resources/paths
      def aws_api_gateway_resource(name, attributes = {})
        # Validate attributes using dry-struct
        validated_attrs = Types::Types::ApiGatewayResourceAttributes.new(attributes)
        
        # Synthesize the Terraform resource
        resource :aws_api_gateway_resource, name do
          rest_api_id validated_attrs.rest_api_id
          parent_id validated_attrs.parent_id
          path_part validated_attrs.path_part
        end
        
        # Create and return ResourceReference
        ref = ResourceReference.new(
          type: 'aws_api_gateway_resource',
          name: name,
          resource_attributes: validated_attrs.to_h,
          outputs: {
            id: "${aws_api_gateway_resource.#{name}.id}",
            path: "${aws_api_gateway_resource.#{name}.path}",
            execution_arn: "${aws_api_gateway_resource.#{name}.execution_arn}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:is_path_parameter?) { validated_attrs.is_path_parameter? }
        ref.define_singleton_method(:is_greedy_parameter?) { validated_attrs.is_greedy_parameter? }
        ref.define_singleton_method(:parameter_name) { validated_attrs.parameter_name }
        ref.define_singleton_method(:requires_request_validator?) { validated_attrs.requires_request_validator? }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)