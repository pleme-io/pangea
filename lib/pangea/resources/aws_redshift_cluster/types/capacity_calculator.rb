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

module Pangea
  module Resources
    module AWS
      module Types
        # Capacity calculation methods for Redshift clusters
        module RedshiftCapacityCalculator
          # Storage capacity per node type (GB), nil for managed storage
          STORAGE_PER_NODE = {
            'dc2.large' => 160,
            'dc2.8xlarge' => 2560,
            'ra3.xlplus' => nil,
            'ra3.4xlarge' => nil,
            'ra3.16xlarge' => nil
          }.freeze

          # vCPUs per node type
          VCPUS_PER_NODE = {
            'dc2.large' => 2,
            'dc2.8xlarge' => 32,
            'ra3.xlplus' => 4,
            'ra3.4xlarge' => 12,
            'ra3.16xlarge' => 48
          }.freeze

          # Memory per node type (GB)
          MEMORY_PER_NODE = {
            'dc2.large' => 15,
            'dc2.8xlarge' => 244,
            'ra3.xlplus' => 32,
            'ra3.4xlarge' => 96,
            'ra3.16xlarge' => 384
          }.freeze

          # Check if cluster is multi-node
          def multi_node?
            cluster_type == 'multi-node'
          end

          # Check if cluster uses RA3 nodes (with managed storage)
          def uses_ra3_nodes?
            node_type.start_with?('ra3.')
          end

          # Check if cluster uses DC2 nodes (with local storage)
          def uses_dc2_nodes?
            node_type.start_with?('dc2.')
          end

          # Calculate storage capacity based on node type and count
          def total_storage_capacity_gb
            storage_per_node = STORAGE_PER_NODE[node_type] || 0
            return nil if storage_per_node.nil? || storage_per_node.zero?

            storage_per_node * number_of_nodes
          end

          # Calculate compute capacity
          def total_vcpus
            vcpus_per_node = VCPUS_PER_NODE[node_type] || 0
            vcpus_per_node * number_of_nodes
          end

          # Calculate memory capacity
          def total_memory_gb
            memory_per_node = MEMORY_PER_NODE[node_type] || 0
            memory_per_node * number_of_nodes
          end
        end
      end
    end
  end
end
