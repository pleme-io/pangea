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

module Pangea
  module Resources
    module AWS
      # Type-safe resource function for AWS DRS Replication Configuration Template
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/drs_replication_configuration_template
      #
      # @example Standard replication template for production workloads
      #   aws_drs_replication_configuration_template(:production_template, {
      #     associate_default_security_group: false,
      #     bandwidth_throttling: 50,
      #     create_public_ip: false,
      #     data_plane_routing: "PRIVATE_IP",
      #     default_large_staging_disk_type: "GP3",
      #     ebs_encryption: "DEFAULT",
      #     replication_server_instance_type: "m5.large",
      #     replication_servers_security_groups_ids: [
      #       security_group.id
      #     ],
      #     staging_area_subnet_id: private_subnet.id,
      #     staging_area_tags: {
      #       "Purpose" => "DRS-Staging",
      #       "Environment" => "production"
      #     },
      #     use_dedicated_replication_server: false,
      #     tags: {
      #       "Template" => "production-replication",
      #       "CostCenter" => "infrastructure"
      #     }
      #   })
      #
      # @example High-performance replication template
      #   aws_drs_replication_configuration_template(:high_performance, {
      #     associate_default_security_group: false,
      #     bandwidth_throttling: 0,
      #     create_public_ip: false,
      #     data_plane_routing: "PRIVATE_IP",
      #     default_large_staging_disk_type: "GP3",
      #     ebs_encryption: "CUSTOMER_MANAGED_CMK",
      #     ebs_encryption_key_arn: kms_key.arn,
      #     replication_server_instance_type: "c5.xlarge",
      #     replication_servers_security_groups_ids: [dr_security_group.id],
      #     staging_area_subnet_id: dr_subnet.id,
      #     use_dedicated_replication_server: true
      #   })
      def aws_drs_replication_configuration_template(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          associate_default_security_group: {
            description: "Whether to associate default security group",
            type: :boolean,
            default: true
          },
          bandwidth_throttling: {
            description: "Bandwidth throttling for replication (Mbps, 0 = unlimited)",
            type: :integer,
            default: 0
          },
          create_public_ip: {
            description: "Whether to create public IP for replication servers",
            type: :boolean,
            default: false
          },
          data_plane_routing: {
            description: "Data plane routing (PUBLIC_IP or PRIVATE_IP)",
            type: :string,
            default: "PRIVATE_IP",
            enum: ["PUBLIC_IP", "PRIVATE_IP"]
          },
          default_large_staging_disk_type: {
            description: "Default large staging disk type",
            type: :string,
            default: "GP2",
            enum: ["GP2", "GP3", "ST1"]
          },
          ebs_encryption: {
            description: "EBS encryption type",
            type: :string,
            default: "DEFAULT",
            enum: ["DEFAULT", "CUSTOMER_MANAGED_CMK", "NONE"]
          },
          ebs_encryption_key_arn: {
            description: "ARN of EBS encryption key (required if ebs_encryption is CUSTOMER_MANAGED_CMK)",
            type: :string
          },
          replication_server_instance_type: {
            description: "Instance type for replication servers",
            type: :string,
            default: "m5.large"
          },
          replication_servers_security_groups_ids: {
            description: "Security group IDs for replication servers",
            type: :array
          },
          staging_area_subnet_id: {
            description: "Subnet ID for staging area",
            type: :string,
            required: true
          },
          staging_area_tags: {
            description: "Tags for staging area resources",
            type: :map
          },
          use_dedicated_replication_server: {
            description: "Whether to use dedicated replication server",
            type: :boolean,
            default: false
          },
          tags: {
            description: "Resource tags",
            type: :map
          }
        })

        resource_block = resource(:aws_drs_replication_configuration_template, name, transformed)
        
        Reference.new(
          type: :aws_drs_replication_configuration_template,
          name: name,
          attributes: {
            arn: "#{resource_block}.arn",
            id: "#{resource_block}.id",
            template_id: "#{resource_block}.template_id",
            tags_all: "#{resource_block}.tags_all"
          },
          resource: resource_block
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)