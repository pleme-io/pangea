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
      # Type-safe attributes for AwsDocdbCluster resources
      # Manages a DocumentDB cluster, providing a MongoDB-compatible database service.
      class DocdbClusterAttributes < Dry::Struct
        attribute :cluster_identifier, Resources::Types::String
        attribute :engine, Resources::Types::String.optional
        attribute :engine_version, Resources::Types::String.optional
        attribute :master_username, Resources::Types::String.optional
        attribute :master_password, Resources::Types::String.optional
        attribute :backup_retention_period, Resources::Types::Integer.optional
        attribute :preferred_backup_window, Resources::Types::String.optional
        attribute :preferred_maintenance_window, Resources::Types::String.optional
        attribute :port, Resources::Types::Integer.optional
        attribute :vpc_security_group_ids, Resources::Types::Array.of(Types::String).default([].freeze).optional
        attribute :db_subnet_group_name, Resources::Types::String.optional
        attribute :db_cluster_parameter_group_name, Resources::Types::String.optional
        attribute :storage_encrypted, Resources::Types::Bool.optional
        attribute :kms_key_id, Resources::Types::String.optional
        attribute :enabled_cloudwatch_logs_exports, Resources::Types::Array.of(Types::String).default([].freeze).optional
        attribute :deletion_protection, Resources::Types::Bool.optional
        attribute :skip_final_snapshot, Resources::Types::Bool.optional
        attribute :final_snapshot_identifier, Resources::Types::String.optional
        attribute :apply_immediately, Resources::Types::Bool.optional
        attribute :availability_zones, Resources::Types::Array.of(Types::String).default([].freeze).optional
        attribute :enable_global_write_forwarding, Resources::Types::Bool.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # cluster_identifier must be lowercase and start with a letter
          # master_username and master_password required for new clusters
          # backup_retention_period must be between 0 and 35 days
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_docdb_cluster

      end
    end
      end
    end
  end
end