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
      # Type-safe attributes for AWS RDS Proxy Target resources
      class RdsProxyTargetAttributes < Dry::Struct
        # DB proxy name this target belongs to
        attribute :db_proxy_name, Resources::Types::String

        # Target group name within the proxy
        attribute :target_group_name, Resources::Types::String

        # DB instance identifier (for RDS instances)
        attribute :db_instance_identifier, Resources::Types::String.optional

        # DB cluster identifier (for Aurora clusters)
        attribute :db_cluster_identifier, Resources::Types::String.optional

        def self.new(attributes = {})
          attrs = super(attributes)

          # Must specify either db_instance_identifier or db_cluster_identifier, but not both
          has_instance = !attrs.db_instance_identifier.nil?
          has_cluster = !attrs.db_cluster_identifier.nil?

          unless has_instance ^ has_cluster
            raise Dry::Struct::Error, "Must specify exactly one of db_instance_identifier or db_cluster_identifier"
          end

          # Validate proxy name format
          unless attrs.db_proxy_name.match?(/^[a-zA-Z][a-zA-Z0-9-]*$/)
            raise Dry::Struct::Error, "db_proxy_name must start with a letter and contain only letters, numbers, and hyphens"
          end

          # Validate target group name format
          unless attrs.target_group_name.match?(/^[a-zA-Z][a-zA-Z0-9-]*$/)
            raise Dry::Struct::Error, "target_group_name must start with a letter and contain only letters, numbers, and hyphens"
          end

          attrs
        end

        # Check if this targets an RDS instance
        def targets_instance?
          !db_instance_identifier.nil?
        end

        # Check if this targets an Aurora cluster
        def targets_cluster?
          !db_cluster_identifier.nil?
        end

        # Get the target identifier
        def target_identifier
          db_instance_identifier || db_cluster_identifier
        end

        # Get the target type
        def target_type
          targets_instance? ? "instance" : "cluster"
        end
      end

      # Common RDS Proxy Target configurations
      module RdsProxyTargetConfigs
        # Instance target
        def self.instance_target(proxy_name:, target_group_name:, instance_id:)
          {
            db_proxy_name: proxy_name,
            target_group_name: target_group_name,
            db_instance_identifier: instance_id
          }
        end

        # Cluster target
        def self.cluster_target(proxy_name:, target_group_name:, cluster_id:)
          {
            db_proxy_name: proxy_name,
            target_group_name: target_group_name,
            db_cluster_identifier: cluster_id
          }
        end
      end
    end
      end
    end
  end
end