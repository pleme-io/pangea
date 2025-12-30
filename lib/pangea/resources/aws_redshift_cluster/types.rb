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

require 'pangea/resources/types'
require_relative 'types/validators'
require_relative 'types/capacity_calculator'
require_relative 'types/cost_estimator'
require_relative 'types/feature_checks'
require_relative 'types/workload_parameters'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Redshift Cluster resources
        class RedshiftClusterAttributes < Dry::Struct
          include RedshiftCapacityCalculator
          include RedshiftCostEstimator
          include RedshiftFeatureChecks

          # Cluster identifier (required)
          attribute :cluster_identifier, Resources::Types::String

          # Database name
          attribute :database_name, Resources::Types::String.default('dev')

          # Master username
          attribute :master_username, Resources::Types::String.default('awsuser')

          # Master password (required for new clusters)
          attribute :master_password, Resources::Types::String.optional

          # Node type (required)
          attribute :node_type, Resources::Types::String.enum(
            'dc2.large', 'dc2.8xlarge',
            'ra3.xlplus', 'ra3.4xlarge', 'ra3.16xlarge'
          )

          # Cluster type
          attribute :cluster_type, Resources::Types::String.default('single-node').enum('single-node', 'multi-node')

          # Number of nodes (required for multi-node)
          attribute :number_of_nodes, Resources::Types::Integer.default(1)

          # Port number
          attribute :port, Resources::Types::Integer.default(5439)

          # Cluster subnet group name
          attribute :cluster_subnet_group_name, Resources::Types::String.optional

          # Cluster parameter group name
          attribute :cluster_parameter_group_name, Resources::Types::String.optional

          # VPC security group IDs
          attribute :vpc_security_group_ids, Resources::Types::Array.of(Resources::Types::String).default([].freeze)

          # Availability zone
          attribute :availability_zone, Resources::Types::String.optional

          # Preferred maintenance window
          attribute :preferred_maintenance_window, Resources::Types::String.default('sun:05:00-sun:06:00')

          # Automated snapshot retention period
          attribute :automated_snapshot_retention_period, Resources::Types::Integer.default(1)

          # Manual snapshot retention period
          attribute :manual_snapshot_retention_period, Resources::Types::Integer.default(-1)

          # Encryption
          attribute :encrypted, Resources::Types::Bool.default(false)

          # KMS key ID for encryption
          attribute :kms_key_id, Resources::Types::String.optional

          # Enhanced VPC routing
          attribute :enhanced_vpc_routing, Resources::Types::Bool.default(false)

          # Publicly accessible
          attribute :publicly_accessible, Resources::Types::Bool.default(false)

          # Elastic IP
          attribute :elastic_ip, Resources::Types::String.optional

          # Skip final snapshot
          attribute :skip_final_snapshot, Resources::Types::Bool.default(true)

          # Final snapshot identifier
          attribute :final_snapshot_identifier, Resources::Types::String.optional

          # Snapshot identifier to restore from
          attribute :snapshot_identifier, Resources::Types::String.optional

          # Snapshot cluster identifier
          attribute :snapshot_cluster_identifier, Resources::Types::String.optional

          # Owner account for snapshot
          attribute :owner_account, Resources::Types::String.optional

          # Allow version upgrade
          attribute :allow_version_upgrade, Resources::Types::Bool.default(true)

          # Cluster version
          attribute :cluster_version, Resources::Types::String.default('1.0')

          # Logging configuration
          attribute :logging, Resources::Types::Hash.schema(
            enable: Resources::Types::Bool.default(false),
            bucket_name?: Resources::Types::String.optional,
            s3_key_prefix?: Resources::Types::String.optional
          ).optional

          # Snapshot copy configuration
          attribute :snapshot_copy, Resources::Types::Hash.schema(
            destination_region: Resources::Types::String,
            retention_period?: Resources::Types::Integer.optional,
            grant_name?: Resources::Types::String.optional
          ).optional

          # IAM roles
          attribute :iam_roles, Resources::Types::Array.of(Resources::Types::String).default([].freeze)

          # Tags
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            RedshiftClusterValidators.validate!(attrs)
            attrs
          end

          # Default cluster parameter group settings by workload
          def self.default_parameters_for_workload(workload)
            RedshiftWorkloadParameters.for_workload(workload)
          end
        end
      end
    end
  end
end
