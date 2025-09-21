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
      # Type-safe attributes for AwsNeptuneCluster resources
      # Provides a Neptune Cluster resource for graph database workloads.
      class NeptuneClusterAttributes < Dry::Struct
        attribute :cluster_identifier, Resources::Types::String
        attribute :engine, Resources::Types::String.optional
        attribute :engine_version, Resources::Types::String.optional
        attribute :backup_retention_period, Resources::Types::Integer.optional
        attribute :preferred_backup_window, Resources::Types::String.optional
        attribute :preferred_maintenance_window, Resources::Types::String.optional
        attribute :port, Resources::Types::Integer.optional
        attribute :vpc_security_group_ids, Resources::Types::Array.of(Types::String).default([].freeze).optional
        attribute :neptune_subnet_group_name, Resources::Types::String.optional
        attribute :neptune_cluster_parameter_group_name, Resources::Types::String.optional
        attribute :storage_encrypted, Resources::Types::Bool.optional
        attribute :kms_key_id, Resources::Types::String.optional
        attribute :iam_database_authentication_enabled, Resources::Types::Bool.optional
        attribute :iam_roles, Resources::Types::Array.of(Types::String).default([].freeze).optional
        attribute :enable_cloudwatch_logs_exports, Resources::Types::Array.of(Types::String).default([].freeze).optional
        attribute :deletion_protection, Resources::Types::Bool.optional
        attribute :skip_final_snapshot, Resources::Types::Bool.optional
        attribute :final_snapshot_identifier, Resources::Types::String.optional
        attribute :apply_immediately, Resources::Types::Bool.optional
        attribute :availability_zones, Resources::Types::Array.of(Types::String).default([].freeze).optional
        attribute :copy_tags_to_snapshot, Resources::Types::Bool.optional
        attribute :enable_global_write_forwarding, Resources::Types::Bool.optional
        attributeserverless_v2_scaling_configuration :, Resources::Types::Hash.default({}.freeze).optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_neptune_cluster

      end
    end
      end
    end
  end
end