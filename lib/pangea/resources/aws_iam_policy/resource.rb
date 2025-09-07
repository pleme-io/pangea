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
require 'pangea/resources/aws_iam_policy/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS IAM Policy with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] IAM policy attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_iam_policy(name, attributes = {})
        # Validate attributes using dry-struct
        policy_attrs = Types::IamPolicyAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_iam_policy, name) do
          name policy_attrs.name
          path policy_attrs.path
          description policy_attrs.description if policy_attrs.description
          
          # Policy document (required)
          policy JSON.pretty_generate(policy_attrs.policy)
          
          # Apply tags if present
          if policy_attrs.tags.any?
            tags do
              policy_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_iam_policy',
          name: name,
          resource_attributes: policy_attrs.to_h,
          outputs: {
            id: "${aws_iam_policy.#{name}.id}",
            arn: "${aws_iam_policy.#{name}.arn}",
            name: "${aws_iam_policy.#{name}.name}",
            path: "${aws_iam_policy.#{name}.path}",
            policy: "${aws_iam_policy.#{name}.policy}",
            policy_id: "${aws_iam_policy.#{name}.policy_id}",
            tags_all: "${aws_iam_policy.#{name}.tags_all}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:all_actions) { policy_attrs.all_actions }
        ref.define_singleton_method(:all_resources) { policy_attrs.all_resources }
        ref.define_singleton_method(:security_level) { policy_attrs.security_level }
        ref.define_singleton_method(:complexity_score) { policy_attrs.complexity_score }
        ref.define_singleton_method(:has_wildcard_permissions?) { policy_attrs.has_wildcard_permissions? }
        ref.define_singleton_method(:uses_reserved_name?) { policy_attrs.uses_reserved_name? }
        ref.define_singleton_method(:service_role_policy?) { policy_attrs.service_role_policy? }
        ref.define_singleton_method(:allows_action?) { |action| policy_attrs.allows_action?(action) }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)