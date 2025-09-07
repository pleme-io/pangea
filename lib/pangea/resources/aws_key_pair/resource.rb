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
require 'pangea/resources/aws_key_pair/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Key Pair with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_key_pair(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::KeyPairAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_key_pair, name) do
          # Key name or prefix (one is required)
          if attrs.key_name
            key_name attrs.key_name
          else
            key_name_prefix attrs.key_name_prefix
          end
          
          # Public key (required)
          public_key attrs.public_key
          
          # Apply tags if present
          if attrs.tags.any?
            tags do
              attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_key_pair',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            arn: "${aws_key_pair.#{name}.arn}",
            fingerprint: "${aws_key_pair.#{name}.fingerprint}",
            id: "${aws_key_pair.#{name}.id}",
            key_name: "${aws_key_pair.#{name}.key_name}",
            key_pair_id: "${aws_key_pair.#{name}.key_pair_id}",
            key_type: "${aws_key_pair.#{name}.key_type}",
            public_key: "${aws_key_pair.#{name}.public_key}",
            tags_all: "${aws_key_pair.#{name}.tags_all}"
          },
          computed_properties: {
            uses_prefix: attrs.uses_prefix?,
            uses_explicit_name: attrs.uses_explicit_name?,
            key_identifier: attrs.key_identifier,
            detected_key_type: attrs.key_type,
            rsa_key: attrs.rsa_key?,
            ecdsa_key: attrs.ecdsa_key?,
            ed25519_key: attrs.ed25519_key?,
            estimated_key_size: attrs.estimated_key_size
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)