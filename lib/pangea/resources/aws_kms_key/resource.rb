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
require 'pangea/resources/aws_kms_key/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS KMS Key with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] KMS key attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_kms_key(name, attributes = {})
        # Validate attributes using dry-struct
        key_attrs = AWS::Types::Types::KmsKeyAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_kms_key, name) do
          description key_attrs.description
          key_usage key_attrs.key_usage
          key_spec key_attrs.key_spec
          
          # Set key policy if provided
          if key_attrs.policy
            policy key_attrs.policy
          end
          
          # Configure safety check bypass
          if key_attrs.bypass_policy_lockout_safety_check
            bypass_policy_lockout_safety_check key_attrs.bypass_policy_lockout_safety_check
          end
          
          # Set deletion window
          if key_attrs.deletion_window_in_days
            deletion_window_in_days key_attrs.deletion_window_in_days
          end
          
          # Configure key rotation (only for symmetric keys)
          if key_attrs.enable_key_rotation && key_attrs.is_symmetric?
            enable_key_rotation key_attrs.enable_key_rotation
          end
          
          # Configure multi-region
          if key_attrs.multi_region
            multi_region key_attrs.multi_region
          end
          
          # Apply tags if present
          if key_attrs.tags&.any?
            tags do
              key_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_kms_key',
          name: name,
          resource_attributes: key_attrs.to_h,
          outputs: {
            id: "${aws_kms_key.#{name}.id}",
            arn: "${aws_kms_key.#{name}.arn}",
            key_id: "${aws_kms_key.#{name}.key_id}",
            description: "${aws_kms_key.#{name}.description}",
            key_usage: "${aws_kms_key.#{name}.key_usage}",
            key_spec: "${aws_kms_key.#{name}.key_spec}",
            policy: "${aws_kms_key.#{name}.policy}",
            deletion_window_in_days: "${aws_kms_key.#{name}.deletion_window_in_days}",
            enable_key_rotation: "${aws_kms_key.#{name}.enable_key_rotation}",
            multi_region: "${aws_kms_key.#{name}.multi_region}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:supports_encryption?) { key_attrs.supports_encryption? }
        ref.define_singleton_method(:supports_signing?) { key_attrs.supports_signing? }
        ref.define_singleton_method(:is_symmetric?) { key_attrs.is_symmetric? }
        ref.define_singleton_method(:is_asymmetric?) { key_attrs.is_asymmetric? }
        ref.define_singleton_method(:supports_rotation?) { key_attrs.supports_rotation? }
        ref.define_singleton_method(:key_algorithm_family) { key_attrs.key_algorithm_family }
        ref.define_singleton_method(:estimated_monthly_cost) { key_attrs.estimated_monthly_cost }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)