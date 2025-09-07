# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/aws_efs_file_system/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Creates an AWS EFS (Elastic File System) file system
      # 
      # @param name [Symbol] The resource name
      # @param attributes [Hash] EFS file system configuration
      # @return [ResourceReference] Reference to the created file system
      def aws_efs_file_system(name, attributes = {})
        validated_attrs = AWS::Types::Types::EfsFileSystemAttributes.new(attributes)
        
        resource_attributes = {
          creation_token: validated_attrs.creation_token,
          performance_mode: validated_attrs.performance_mode,
          throughput_mode: validated_attrs.throughput_mode,
          encrypted: validated_attrs.encrypted,
          tags: validated_attrs.tags
        }
        
        # Add optional attributes
        resource_attributes[:provisioned_throughput_in_mibps] = validated_attrs.provisioned_throughput_in_mibps if validated_attrs.provisioned_throughput_in_mibps
        resource_attributes[:kms_key_id] = validated_attrs.kms_key_id if validated_attrs.kms_key_id
        resource_attributes[:availability_zone_name] = validated_attrs.availability_zone_name if validated_attrs.availability_zone_name
        
        # Add lifecycle policy if specified
        if validated_attrs.lifecycle_policy
          resource_attributes[:lifecycle_policy] = [validated_attrs.lifecycle_policy]
        end
        
        resource(:aws_efs_file_system, name, resource_attributes)
        
        ResourceReference.new(
          type: :aws_efs_file_system,
          name: name,
          attributes: validated_attrs,
          outputs: {
            id: "${aws_efs_file_system.#{name}.id}",
            arn: "${aws_efs_file_system.#{name}.arn}",
            dns_name: "${aws_efs_file_system.#{name}.dns_name}",
            availability_zone_id: "${aws_efs_file_system.#{name}.availability_zone_id}",
            availability_zone_name: "${aws_efs_file_system.#{name}.availability_zone_name}",
            creation_token: "${aws_efs_file_system.#{name}.creation_token}",
            encrypted: "${aws_efs_file_system.#{name}.encrypted}",
            kms_key_id: "${aws_efs_file_system.#{name}.kms_key_id}",
            number_of_mount_targets: "${aws_efs_file_system.#{name}.number_of_mount_targets}",
            owner_id: "${aws_efs_file_system.#{name}.owner_id}",
            performance_mode: "${aws_efs_file_system.#{name}.performance_mode}",
            size_in_bytes: "${aws_efs_file_system.#{name}.size_in_bytes}",
            throughput_mode: "${aws_efs_file_system.#{name}.throughput_mode}",
            provisioned_throughput_in_mibps: "${aws_efs_file_system.#{name}.provisioned_throughput_in_mibps}",
            tags_all: "${aws_efs_file_system.#{name}.tags_all}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)