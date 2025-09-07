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
require 'pangea/resources/aws_lambda_permission/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Lambda permission for function invocation
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Lambda permission attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_lambda_permission(name, attributes = {})
        # Validate attributes using dry-struct
        permission_attrs = AWS::Types::Types::LambdaPermissionAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_lambda_permission, name) do
          action permission_attrs.action
          function_name permission_attrs.function_name
          principal permission_attrs.principal
          statement_id permission_attrs.statement_id
          
          # Optional attributes
          qualifier permission_attrs.qualifier if permission_attrs.qualifier
          source_arn permission_attrs.source_arn if permission_attrs.source_arn
          source_account permission_attrs.source_account if permission_attrs.source_account
          event_source_token permission_attrs.event_source_token if permission_attrs.event_source_token
          principal_org_id permission_attrs.principal_org_id if permission_attrs.principal_org_id
          function_url_auth_type permission_attrs.function_url_auth_type if permission_attrs.function_url_auth_type
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_lambda_permission',
          name: name,
          resource_attributes: permission_attrs.to_h,
          outputs: {
            # Core outputs
            id: "${aws_lambda_permission.#{name}.id}",
            statement_id: "${aws_lambda_permission.#{name}.statement_id}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:is_service_principal?) { permission_attrs.is_service_principal? }
        ref.define_singleton_method(:service_name) { permission_attrs.service_name }
        ref.define_singleton_method(:allows_all_actions?) { permission_attrs.allows_all_actions? }
        ref.define_singleton_method(:is_cross_account?) { permission_attrs.is_cross_account? }
        ref.define_singleton_method(:requires_source_arn?) { permission_attrs.requires_source_arn? }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)