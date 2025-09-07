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
require 'pangea/resources/aws_secretsmanager_secret/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Secrets Manager Secret with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Secret attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_secretsmanager_secret(name, attributes = {})
        # Validate attributes using dry-struct
        secret_attrs = Types::Types::SecretsManagerSecretAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_secretsmanager_secret, name) do
          # Set secret name if provided (otherwise AWS generates one)
          if secret_attrs.name
            name secret_attrs.name
          end
          
          # Set description if provided
          if secret_attrs.description
            description secret_attrs.description
          end
          
          # Configure KMS encryption key
          if secret_attrs.kms_key_id
            kms_key_id secret_attrs.kms_key_id
          end
          
          # Set resource policy if provided
          if secret_attrs.policy
            policy secret_attrs.policy
          end
          
          # Configure recovery window
          if secret_attrs.recovery_window_in_days
            recovery_window_in_days secret_attrs.recovery_window_in_days
          end
          
          # Force overwrite replica secret setting
          if secret_attrs.force_overwrite_replica_secret
            force_overwrite_replica_secret secret_attrs.force_overwrite_replica_secret
          end
          
          # Configure cross-region replicas
          if secret_attrs.replica&.any?
            secret_attrs.replica.each do |replica_config|
              replica do
                region replica_config[:region]
                if replica_config[:kms_key_id]
                  kms_key_id replica_config[:kms_key_id]
                end
              end
            end
          end
          
          # Apply tags if present
          if secret_attrs.tags&.any?
            tags do
              secret_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_secretsmanager_secret',
          name: name,
          resource_attributes: secret_attrs.to_h,
          outputs: {
            id: "${aws_secretsmanager_secret.#{name}.id}",
            arn: "${aws_secretsmanager_secret.#{name}.arn}",
            name: "${aws_secretsmanager_secret.#{name}.name}",
            description: "${aws_secretsmanager_secret.#{name}.description}",
            kms_key_id: "${aws_secretsmanager_secret.#{name}.kms_key_id}",
            policy: "${aws_secretsmanager_secret.#{name}.policy}",
            recovery_window_in_days: "${aws_secretsmanager_secret.#{name}.recovery_window_in_days}",
            tags_all: "${aws_secretsmanager_secret.#{name}.tags_all}",
            replica: "${aws_secretsmanager_secret.#{name}.replica}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)