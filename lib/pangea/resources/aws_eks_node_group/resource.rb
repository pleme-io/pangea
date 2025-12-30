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
require 'pangea/resources/aws_eks_node_group/types'
require 'pangea/resource_registry'
require_relative 'builders/dsl_builder'
require_relative 'builders/reference_builder'

module Pangea
  module Resources
    module AWS
      # Create an AWS EKS Node Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] EKS node group attributes
      # @option attributes [String] :cluster_name EKS cluster name (required)
      # @option attributes [String] :node_role_arn IAM role ARN for nodes (required)
      # @option attributes [Array<String>] :subnet_ids Subnet IDs for nodes (required)
      # @option attributes [String] :node_group_name Custom node group name
      # @option attributes [Hash] :scaling_config Scaling configuration
      # @option attributes [Hash] :update_config Update configuration
      # @option attributes [Array<String>] :instance_types EC2 instance types
      # @option attributes [String] :capacity_type ON_DEMAND or SPOT
      # @option attributes [String] :ami_type AMI type for nodes
      # @option attributes [String] :release_version AMI release version
      # @option attributes [Integer] :disk_size Root device disk size in GB
      # @option attributes [Hash] :remote_access SSH access configuration
      # @option attributes [Hash] :launch_template Custom launch template
      # @option attributes [Hash] :labels Kubernetes labels
      # @option attributes [Array<Hash>] :taints Kubernetes taints
      # @option attributes [Hash] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Basic node group
      #   node_group = aws_eks_node_group(:workers, {
      #     cluster_name: cluster.name,
      #     node_role_arn: node_role.arn,
      #     subnet_ids: private_subnet_ids,
      #     scaling_config: {
      #       desired_size: 3,
      #       min_size: 2,
      #       max_size: 5
      #     }
      #   })
      #
      # @example Spot instance node group with labels and taints
      #   spot_nodes = aws_eks_node_group(:spot_workers, {
      #     cluster_name: cluster.name,
      #     node_role_arn: node_role.arn,
      #     subnet_ids: private_subnet_ids,
      #     capacity_type: "SPOT",
      #     instance_types: ["t3.large", "t3a.large", "t3.xlarge"],
      #     scaling_config: {
      #       desired_size: 5,
      #       min_size: 3,
      #       max_size: 10
      #     },
      #     labels: {
      #       workload: "batch",
      #       lifecycle: "spot"
      #     },
      #     taints: [{
      #       key: "spot",
      #       value: "true",
      #       effect: "NO_SCHEDULE"
      #     }],
      #     tags: {
      #       CostCenter: "engineering",
      #       Type: "spot-compute"
      #     }
      #   })
      #
      # @example GPU node group for ML workloads
      #   gpu_nodes = aws_eks_node_group(:gpu_workers, {
      #     cluster_name: cluster.name,
      #     node_role_arn: node_role.arn,
      #     subnet_ids: private_subnet_ids,
      #     ami_type: "AL2_x86_64_GPU",
      #     instance_types: ["g4dn.xlarge", "g4dn.2xlarge"],
      #     scaling_config: { desired_size: 2, min_size: 1, max_size: 4 },
      #     disk_size: 100,
      #     labels: { workload: "ml", gpu: "nvidia" },
      #     taints: [{
      #       key: "nvidia.com/gpu",
      #       effect: "NO_SCHEDULE"
      #     }]
      #   })
      def aws_eks_node_group(name, attributes = {})
        node_group_attrs = AWS::Types::Types::EksNodeGroupAttributes.new(attributes)

        resource(:aws_eks_node_group, name) do
          EksNodeGroup::DslBuilder.build_resource(self, node_group_attrs)
        end

        EksNodeGroup::ReferenceBuilder.build_reference(name, node_group_attrs)
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
