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
require 'pangea/resources/aws_iam_role/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS IAM Role with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] IAM role attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_iam_role(name, attributes = {})
        # Validate attributes using dry-struct
        role_attrs = Types::IamRoleAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_iam_role, name) do
          name role_attrs.name if role_attrs.name
          name_prefix role_attrs.name_prefix if role_attrs.name_prefix
          path role_attrs.path if role_attrs.path
          description role_attrs.description if role_attrs.description
          
          # Assume role policy (required)
          assume_role_policy JSON.pretty_generate(role_attrs.assume_role_policy)
          
          # Optional configurations
          force_detach_policies role_attrs.force_detach_policies
          max_session_duration role_attrs.max_session_duration
          
          # Permissions boundary
          permissions_boundary role_attrs.permissions_boundary if role_attrs.permissions_boundary
          
          # Inline policies
          if role_attrs.inline_policies.any?
            role_attrs.inline_policies.each do |policy_name, policy_doc|
              inline_policy do
                name policy_name
                policy JSON.pretty_generate(policy_doc)
              end
            end
          end
          
          # Apply tags if present
          if role_attrs.tags.any?
            tags do
              role_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_iam_role',
          name: name,
          resource_attributes: role_attrs.to_h,
          outputs: {
            id: "${aws_iam_role.#{name}.id}",
            arn: "${aws_iam_role.#{name}.arn}",
            name: "${aws_iam_role.#{name}.name}",
            unique_id: "${aws_iam_role.#{name}.unique_id}",
            create_date: "${aws_iam_role.#{name}.create_date}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:service_principal) { role_attrs.service_principal }
        ref.define_singleton_method(:is_service_role?) { role_attrs.is_service_role? }
        ref.define_singleton_method(:is_federated_role?) { role_attrs.is_federated_role? }
        ref.define_singleton_method(:trust_policy_type) { role_attrs.trust_policy_type }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)