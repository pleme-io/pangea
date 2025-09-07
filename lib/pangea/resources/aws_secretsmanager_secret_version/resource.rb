# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_secretsmanager_secret_version/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Secrets Manager Secret Version with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Secret version attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_secretsmanager_secret_version(name, attributes = {})
        # Validate attributes using dry-struct
        version_attrs = Types::Types::SecretsManagerSecretVersionAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_secretsmanager_secret_version, name) do
          secret_id version_attrs.secret_id
          
          # Set secret value (string or binary)
          if version_attrs.secret_string
            if version_attrs.secret_string.is_a?(Hash)
              secret_string version_attrs.secret_string.to_json
            else
              secret_string version_attrs.secret_string
            end
          end
          
          if version_attrs.secret_binary
            secret_binary version_attrs.secret_binary
          end
          
          # Configure version stages
          if version_attrs.version_stages&.any?
            version_stages version_attrs.version_stages
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_secretsmanager_secret_version',
          name: name,
          resource_attributes: version_attrs.to_h,
          outputs: {
            id: "${aws_secretsmanager_secret_version.#{name}.id}",
            arn: "${aws_secretsmanager_secret_version.#{name}.arn}",
            secret_id: "${aws_secretsmanager_secret_version.#{name}.secret_id}",
            version_id: "${aws_secretsmanager_secret_version.#{name}.version_id}",
            version_stages: "${aws_secretsmanager_secret_version.#{name}.version_stages}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)