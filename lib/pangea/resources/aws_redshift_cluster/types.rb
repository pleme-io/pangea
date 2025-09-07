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

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Redshift Cluster resources
      class RedshiftClusterAttributes < Dry::Struct
        # Cluster identifier (required)
        attribute :cluster_identifier, Resources::Types::String
        
        # Database name
        attribute :database_name, Resources::Types::String.default("dev")
        
        # Master username
        attribute :master_username, Resources::Types::String.default("awsuser")
        
        # Master password (required for new clusters)
        attribute :master_password, Resources::Types::String.optional
        
        # Node type (required)
        attribute :node_type, Resources::Types::String.enum(
          "dc2.large", "dc2.8xlarge",
          "ra3.xlplus", "ra3.4xlarge", "ra3.16xlarge"
        )
        
        # Cluster type
        attribute :cluster_type, Resources::Types::String.enum("single-node", "multi-node").default("single-node")
        
        # Number of nodes (required for multi-node)
        attribute :number_of_nodes, Resources::Types::Integer.default(1)
        
        # Port number
        attribute :port, Resources::Types::Integer.default(5439)
        
        # Cluster subnet group name
        attribute :cluster_subnet_group_name, Resources::Types::String.optional
        
        # Cluster parameter group name
        attribute :cluster_parameter_group_name, Resources::Types::String.optional
        
        # VPC security group IDs
        attribute :vpc_security_group_ids, Resources::Types::Array.of(Types::String).default([].freeze)
        
        # Availability zone
        attribute :availability_zone, Resources::Types::String.optional
        
        # Preferred maintenance window
        attribute :preferred_maintenance_window, Resources::Types::String.default("sun:05:00-sun:06:00")
        
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
        attribute :cluster_version, Resources::Types::String.default("1.0")
        
        # Logging configuration
        attribute :logging, Resources::Types::Hash.schema(
          enable: Types::Bool.default(false),
          bucket_name?: Types::String.optional,
          s3_key_prefix?: Types::String.optional
        ).optional
        
        # Snapshot copy configuration
        attribute :snapshot_copy, Resources::Types::Hash.schema(
          destination_region: Types::String,
          retention_period?: Types::Integer.optional,
          grant_name?: Types::String.optional
        ).optional
        
        # IAM roles
        attribute :iam_roles, Resources::Types::Array.of(Types::String).default([].freeze)
        
        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate cluster identifier format
          unless attrs.cluster_identifier =~ /\A[a-z][a-z0-9\-]*\z/
            raise Dry::Struct::Error, "Cluster identifier must start with lowercase letter and contain only lowercase letters, numbers, and hyphens"
          end
          
          # Validate cluster identifier length
          if attrs.cluster_identifier.length > 63
            raise Dry::Struct::Error, "Cluster identifier must be 63 characters or less"
          end
          
          # Validate multi-node configuration
          if attrs.cluster_type == "multi-node" && attrs.number_of_nodes < 2
            raise Dry::Struct::Error, "Multi-node clusters must have at least 2 nodes"
          end
          
          # Validate single-node configuration
          if attrs.cluster_type == "single-node" && attrs.number_of_nodes != 1
            raise Dry::Struct::Error, "Single-node clusters must have exactly 1 node"
          end
          
          # Validate encryption configuration
          if attrs.encrypted && attrs.kms_key_id.nil?
            raise Dry::Struct::Error, "KMS key ID must be provided when encryption is enabled"
          end
          
          # Validate snapshot configuration
          if !attrs.skip_final_snapshot && attrs.final_snapshot_identifier.nil?
            raise Dry::Struct::Error, "Final snapshot identifier must be provided when skip_final_snapshot is false"
          end
          
          # Validate logging configuration
          if attrs.logging && attrs.logging[:enable] && attrs.logging[:bucket_name].nil?
            raise Dry::Struct::Error, "Bucket name must be provided when logging is enabled"
          end

          attrs
        end

        # Check if cluster is multi-node
        def multi_node?
          cluster_type == "multi-node"
        end

        # Check if cluster uses RA3 nodes (with managed storage)
        def uses_ra3_nodes?
          node_type.start_with?("ra3.")
        end

        # Check if cluster uses DC2 nodes (with local storage)
        def uses_dc2_nodes?
          node_type.start_with?("dc2.")
        end

        # Calculate storage capacity based on node type and count
        def total_storage_capacity_gb
          storage_per_node = case node_type
                            when "dc2.large" then 160
                            when "dc2.8xlarge" then 2560
                            when "ra3.xlplus" then nil # Managed storage
                            when "ra3.4xlarge" then nil # Managed storage
                            when "ra3.16xlarge" then nil # Managed storage
                            else 0
                            end
          
          return nil if storage_per_node.nil? # RA3 has managed storage
          storage_per_node * number_of_nodes
        end

        # Calculate compute capacity
        def total_vcpus
          vcpus_per_node = case node_type
                          when "dc2.large" then 2
                          when "dc2.8xlarge" then 32
                          when "ra3.xlplus" then 4
                          when "ra3.4xlarge" then 12
                          when "ra3.16xlarge" then 48
                          else 0
                          end
          
          vcpus_per_node * number_of_nodes
        end

        # Calculate memory capacity
        def total_memory_gb
          memory_per_node = case node_type
                           when "dc2.large" then 15
                           when "dc2.8xlarge" then 244
                           when "ra3.xlplus" then 32
                           when "ra3.4xlarge" then 96
                           when "ra3.16xlarge" then 384
                           else 0
                           end
          
          memory_per_node * number_of_nodes
        end

        # Estimate monthly cost
        def estimated_monthly_cost_usd
          hourly_rate = case node_type
                       when "dc2.large" then 0.25
                       when "dc2.8xlarge" then 4.80
                       when "ra3.xlplus" then 1.086
                       when "ra3.4xlarge" then 3.26
                       when "ra3.16xlarge" then 13.04
                       else 0
                       end
          
          # Base compute cost
          compute_cost = hourly_rate * number_of_nodes * 730 # hours per month
          
          # Add managed storage cost for RA3
          storage_cost = 0
          if uses_ra3_nodes?
            # Estimate 1TB per node for RA3 at $0.024/GB/month
            storage_cost = number_of_nodes * 1024 * 0.024
          end
          
          # Add snapshot storage cost
          snapshot_cost = 0
          if automated_snapshot_retention_period > 0
            # Estimate 10% of data size for incremental snapshots
            snapshot_gb = (total_storage_capacity_gb || 1024) * 0.1
            snapshot_cost = snapshot_gb * 0.023 # S3 standard pricing
          end
          
          compute_cost + storage_cost + snapshot_cost
        end

        # Check if cluster has high availability features
        def high_availability?
          multi_node? && automated_snapshot_retention_period > 0
        end

        # Check if cluster has audit logging enabled
        def audit_logging_enabled?
          logging && logging[:enable] == true
        end

        # Check if cluster has cross-region snapshot copy
        def cross_region_backup?
          !snapshot_copy.nil?
        end

        # Generate connection string
        def jdbc_connection_string
          "jdbc:redshift://#{cluster_identifier}.region.redshift.amazonaws.com:#{port}/#{database_name}"
        end

        # Default cluster parameter group settings by workload
        def self.default_parameters_for_workload(workload)
          case workload.to_s
          when "etl"
            {
              "max_concurrency_scaling_clusters" => "1",
              "enable_user_activity_logging" => "true",
              "statement_timeout" => "0",
              "wlm_json_configuration" => JSON.generate([{
                "query_group" => "etl",
                "memory_percent_to_use" => 70,
                "max_execution_time" => 0
              }])
            }
          when "analytics"
            {
              "max_concurrency_scaling_clusters" => "3",
              "enable_user_activity_logging" => "true",
              "statement_timeout" => "600000",
              "search_path" => "analytics,public",
              "wlm_json_configuration" => JSON.generate([{
                "query_group" => "analytics",
                "memory_percent_to_use" => 50,
                "max_execution_time" => 300000
              }])
            }
          when "mixed"
            {
              "max_concurrency_scaling_clusters" => "2",
              "enable_user_activity_logging" => "true",
              "auto_analyze" => "true",
              "datestyle" => "ISO, MDY"
            }
          else
            {}
          end
        end
      end
    end
      end
    end
  end
end