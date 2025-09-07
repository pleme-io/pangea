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
require 'pangea/resources/aws_eks_addon/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EKS Add-on with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] EKS add-on attributes
      # @option attributes [String] :cluster_name EKS cluster name (required)
      # @option attributes [String] :addon_name Add-on name (required)
      # @option attributes [String] :addon_version Specific add-on version
      # @option attributes [String] :service_account_role_arn IAM role for service account
      # @option attributes [String] :resolve_conflicts Conflict resolution strategy
      # @option attributes [String] :resolve_conflicts_on_create Create-time conflict resolution
      # @option attributes [String] :resolve_conflicts_on_update Update-time conflict resolution
      # @option attributes [String] :configuration_values JSON configuration values
      # @option attributes [Boolean] :preserve Preserve add-on on deletion
      # @option attributes [Hash] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Basic VPC CNI add-on
      #   vpc_cni = aws_eks_addon(:vpc_cni, {
      #     cluster_name: cluster.name,
      #     addon_name: "vpc-cni",
      #     addon_version: "v1.12.6-eksbuild.2"
      #   })
      #
      # @example EBS CSI driver with IAM role
      #   ebs_csi = aws_eks_addon(:ebs_csi, {
      #     cluster_name: cluster.name,
      #     addon_name: "aws-ebs-csi-driver",
      #     addon_version: "v1.28.0-eksbuild.1",
      #     service_account_role_arn: ebs_csi_role.arn,
      #     resolve_conflicts_on_create: "OVERWRITE",
      #     tags: {
      #       Purpose: "persistent-storage"
      #     }
      #   })
      #
      # @example CoreDNS with custom configuration
      #   coredns = aws_eks_addon(:coredns, {
      #     cluster_name: cluster.name,
      #     addon_name: "coredns",
      #     configuration_values: JSON.generate({
      #       computeType: "Fargate",
      #       replicaCount: 3,
      #       resources: {
      #         limits: {
      #           cpu: "100m",
      #           memory: "150Mi"
      #         }
      #       }
      #     })
      #   })
      #
      # @example GuardDuty agent for security monitoring
      #   guardduty = aws_eks_addon(:guardduty, {
      #     cluster_name: cluster.name,
      #     addon_name: "aws-guardduty-agent",
      #     service_account_role_arn: guardduty_role.arn,
      #     resolve_conflicts: "OVERWRITE",
      #     preserve: false
      #   })
      def aws_eks_addon(name, attributes = {})
        # Validate attributes using dry-struct
        addon_attrs = AWS::Types::Types::EksAddonAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_eks_addon, name) do
          # Required attributes
          cluster_name addon_attrs.cluster_name
          addon_name addon_attrs.addon_name
          
          # Optional version
          addon_version addon_attrs.addon_version if addon_attrs.addon_version
          
          # Service account IAM role
          service_account_role_arn addon_attrs.service_account_role_arn if addon_attrs.service_account_role_arn
          
          # Conflict resolution strategy
          if addon_attrs.resolve_conflicts_on_create || addon_attrs.resolve_conflicts_on_update
            resolve_conflicts_on_create addon_attrs.resolve_conflicts_on_create if addon_attrs.resolve_conflicts_on_create
            resolve_conflicts_on_update addon_attrs.resolve_conflicts_on_update if addon_attrs.resolve_conflicts_on_update
          elsif addon_attrs.resolve_conflicts != 'NONE'
            resolve_conflicts addon_attrs.resolve_conflicts
          end
          
          # Configuration values
          configuration_values addon_attrs.configuration_values if addon_attrs.configuration_values
          
          # Preservation setting
          preserve addon_attrs.preserve if addon_attrs.preserve != true
          
          # Tags
          tags addon_attrs.tags if addon_attrs.tags.any?
        end
        
        # Create resource reference
        ref = ResourceReference.new(
          type: 'aws_eks_addon',
          name: name,
          resource_attributes: addon_attrs.to_h,
          outputs: {
            id: "${aws_eks_addon.#{name}.id}",
            arn: "${aws_eks_addon.#{name}.arn}",
            addon_version: "${aws_eks_addon.#{name}.addon_version}",
            created_at: "${aws_eks_addon.#{name}.created_at}",
            modified_at: "${aws_eks_addon.#{name}.modified_at}",
            status: "${aws_eks_addon.#{name}.status}",
            configuration_values: "${aws_eks_addon.#{name}.configuration_values}",
            tags_all: "${aws_eks_addon.#{name}.tags_all}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:addon_name) { addon_attrs.addon_name }
        ref.define_singleton_method(:service_account) { addon_attrs.service_account_name }
        ref.define_singleton_method(:namespace) { addon_attrs.namespace }
        ref.define_singleton_method(:requires_iam_role?) { addon_attrs.requires_iam_role? }
        ref.define_singleton_method(:is_compute_addon?) { addon_attrs.is_compute_addon? }
        ref.define_singleton_method(:is_storage_addon?) { addon_attrs.is_storage_addon? }
        ref.define_singleton_method(:is_networking_addon?) { addon_attrs.is_networking_addon? }
        ref.define_singleton_method(:is_observability_addon?) { addon_attrs.is_observability_addon? }
        ref.define_singleton_method(:addon_description) { addon_attrs.addon_info[:description] }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)