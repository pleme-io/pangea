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
        # Validate attributes using dry-struct
        node_group_attrs = AWS::Types::Types::EksNodeGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_eks_node_group, name) do
          # Required attributes
          cluster_name node_group_attrs.cluster_name
          node_role_arn node_group_attrs.node_role_arn
          subnet_ids node_group_attrs.subnet_ids
          
          # Optional name
          node_group_name node_group_attrs.node_group_name if node_group_attrs.node_group_name
          
          # Scaling configuration
          scaling_config do
            desired_size node_group_attrs.scaling_config.desired_size
            max_size node_group_attrs.scaling_config.max_size
            min_size node_group_attrs.scaling_config.min_size
          end
          
          # Update configuration
          if node_group_attrs.update_config
            update_config do
              if node_group_attrs.update_config.max_unavailable
                max_unavailable node_group_attrs.update_config.max_unavailable
              elsif node_group_attrs.update_config.max_unavailable_percentage
                max_unavailable_percentage node_group_attrs.update_config.max_unavailable_percentage
              end
            end
          end
          
          # Instance configuration
          instance_types node_group_attrs.instance_types
          capacity_type node_group_attrs.capacity_type
          ami_type node_group_attrs.ami_type
          disk_size node_group_attrs.disk_size
          
          # Version information
          release_version node_group_attrs.release_version if node_group_attrs.release_version
          version node_group_attrs.version if node_group_attrs.version
          force_update_version node_group_attrs.force_update_version if node_group_attrs.force_update_version
          
          # Remote access
          if node_group_attrs.remote_access
            remote_access do
              ec2_ssh_key node_group_attrs.remote_access.ec2_ssh_key if node_group_attrs.remote_access.ec2_ssh_key
              if node_group_attrs.remote_access.source_security_group_ids.any?
                source_security_group_ids node_group_attrs.remote_access.source_security_group_ids
              end
            end
          end
          
          # Launch template
          if node_group_attrs.launch_template
            launch_template do
              id node_group_attrs.launch_template.id if node_group_attrs.launch_template.id
              __send__(:name, node_group_attrs.launch_template.name) if node_group_attrs.launch_template.name
              version node_group_attrs.launch_template.version if node_group_attrs.launch_template.version
            end
          end
          
          # Kubernetes labels
          labels node_group_attrs.labels if node_group_attrs.labels.any?
          
          # Kubernetes taints
          if node_group_attrs.taints.any?
            node_group_attrs.taints.each do |taint_config|
              taint do
                key taint_config.key
                value taint_config.value if taint_config.value
                effect taint_config.effect
              end
            end
          end
          
          # Tags
          tags node_group_attrs.tags if node_group_attrs.tags.any?
        end
        
        # Create resource reference
        ref = ResourceReference.new(
          type: 'aws_eks_node_group',
          name: name,
          resource_attributes: node_group_attrs.to_h,
          outputs: {
            id: "${aws_eks_node_group.#{name}.id}",
            arn: "${aws_eks_node_group.#{name}.arn}",
            cluster_name: "${aws_eks_node_group.#{name}.cluster_name}",
            node_group_name: "${aws_eks_node_group.#{name}.node_group_name}",
            node_role_arn: "${aws_eks_node_group.#{name}.node_role_arn}",
            subnet_ids: "${aws_eks_node_group.#{name}.subnet_ids}",
            status: "${aws_eks_node_group.#{name}.status}",
            capacity_type: "${aws_eks_node_group.#{name}.capacity_type}",
            instance_types: "${aws_eks_node_group.#{name}.instance_types}",
            disk_size: "${aws_eks_node_group.#{name}.disk_size}",
            remote_access: "${aws_eks_node_group.#{name}.remote_access}",
            scaling_config: "${aws_eks_node_group.#{name}.scaling_config}",
            update_config: "${aws_eks_node_group.#{name}.update_config}",
            launch_template: "${aws_eks_node_group.#{name}.launch_template}",
            version: "${aws_eks_node_group.#{name}.version}",
            release_version: "${aws_eks_node_group.#{name}.release_version}",
            resources: "${aws_eks_node_group.#{name}.resources}",
            tags_all: "${aws_eks_node_group.#{name}.tags_all}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:spot_instances?) { node_group_attrs.spot_instances? }
        ref.define_singleton_method(:custom_ami?) { node_group_attrs.custom_ami? }
        ref.define_singleton_method(:has_remote_access?) { node_group_attrs.has_remote_access? }
        ref.define_singleton_method(:has_taints?) { node_group_attrs.has_taints? }
        ref.define_singleton_method(:has_labels?) { node_group_attrs.has_labels? }
        ref.define_singleton_method(:ami_type) { node_group_attrs.ami_type }
        ref.define_singleton_method(:desired_size) { node_group_attrs.scaling_config.desired_size }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)