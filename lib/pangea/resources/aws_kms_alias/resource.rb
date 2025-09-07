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
require 'pangea/resources/aws_kms_alias/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS KMS Alias with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] KMS alias attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_kms_alias(name, attributes = {})
        # Validate attributes using dry-struct
        alias_attrs = AWS::Types::Types::KmsAliasAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_kms_alias, name) do
          name alias_attrs.name
          target_key_id alias_attrs.target_key_id
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_kms_alias',
          name: name,
          resource_attributes: alias_attrs.to_h,
          outputs: {
            id: "${aws_kms_alias.#{name}.id}",
            arn: "${aws_kms_alias.#{name}.arn}",
            name: "${aws_kms_alias.#{name}.name}",
            target_key_arn: "${aws_kms_alias.#{name}.target_key_arn}",
            target_key_id: "${aws_kms_alias.#{name}.target_key_id}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:alias_suffix) { alias_attrs.alias_suffix }
        ref.define_singleton_method(:is_service_alias?) { alias_attrs.is_service_alias? }
        ref.define_singleton_method(:estimated_alias_purpose) { alias_attrs.estimated_alias_purpose }
        ref.define_singleton_method(:uses_key_id?) { alias_attrs.uses_key_id? }
        ref.define_singleton_method(:uses_key_arn?) { alias_attrs.uses_key_arn? }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)