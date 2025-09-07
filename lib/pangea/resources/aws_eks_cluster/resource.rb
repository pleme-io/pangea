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
require 'pangea/resources/aws_eks_cluster/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EKS Cluster with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] EKS cluster attributes
      # @option attributes [String] :name Custom cluster name (optional, defaults to resource name)
      # @option attributes [String] :role_arn IAM role ARN for the cluster (required)
      # @option attributes [Hash] :vpc_config VPC configuration (required)
      # @option attributes [String] :version Kubernetes version (defaults to 1.28)
      # @option attributes [Array<String>] :enabled_cluster_log_types Log types to enable
      # @option attributes [Array<Hash>] :encryption_config Encryption configuration
      # @option attributes [Hash] :kubernetes_network_config Kubernetes network config
      # @option attributes [Hash] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Basic EKS cluster
      #   cluster = aws_eks_cluster(:main, {
      #     role_arn: eks_cluster_role.arn,
      #     version: "1.28",
      #     vpc_config: {
      #       subnet_ids: [subnet_a.id, subnet_b.id],
      #       endpoint_private_access: true,
      #       endpoint_public_access: true,
      #       public_access_cidrs: ["10.0.0.0/8"]
      #     }
      #   })
      #
      # @example EKS cluster with logging and encryption
      #   cluster = aws_eks_cluster(:production, {
      #     role_arn: cluster_role.arn,
      #     version: "1.29",
      #     vpc_config: {
      #       subnet_ids: private_subnet_ids,
      #       security_group_ids: [cluster_sg.id],
      #       endpoint_private_access: true,
      #       endpoint_public_access: false
      #     },
      #     enabled_cluster_log_types: ["api", "audit", "authenticator"],
      #     encryption_config: [{
      #       resources: ["secrets"],
      #       provider: { key_arn: kms_key.arn }
      #     }],
      #     kubernetes_network_config: {
      #       service_ipv4_cidr: "172.20.0.0/16",
      #       ip_family: "ipv4"
      #     },
      #     tags: {
      #       Environment: "production",
      #       ManagedBy: "terraform"
      #     }
      #   })
      def aws_eks_cluster(name, attributes = {})
        # Validate attributes using dry-struct
        cluster_attrs = AWS::Types::Types::EksClusterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_eks_cluster, name) do
          # Use custom name if provided, otherwise use resource name
          __send__(:name, cluster_attrs.name) if cluster_attrs.name
          
          # Required attributes
          role_arn cluster_attrs.role_arn
          version cluster_attrs.version
          
          # VPC configuration block
          vpc_config do
            subnet_ids cluster_attrs.vpc_config.subnet_ids
            security_group_ids cluster_attrs.vpc_config.security_group_ids if cluster_attrs.vpc_config.security_group_ids.any?
            endpoint_private_access cluster_attrs.vpc_config.endpoint_private_access
            endpoint_public_access cluster_attrs.vpc_config.endpoint_public_access
            public_access_cidrs cluster_attrs.vpc_config.public_access_cidrs if cluster_attrs.vpc_config.endpoint_public_access
          end
          
          # Logging configuration
          if cluster_attrs.enabled_cluster_log_types.any?
            enabled_cluster_log_types cluster_attrs.enabled_cluster_log_types
          end
          
          # Encryption configuration
          if cluster_attrs.encryption_config.any?
            cluster_attrs.encryption_config.each do |enc_config|
              encryption_config do
                resources enc_config.resources
                provider do
                  key_arn enc_config.provider.key_arn
                end
              end
            end
          end
          
          # Kubernetes network configuration
          if cluster_attrs.kubernetes_network_config
            kubernetes_network_config do
              service_ipv4_cidr cluster_attrs.kubernetes_network_config.service_ipv4_cidr if cluster_attrs.kubernetes_network_config.service_ipv4_cidr
              ip_family cluster_attrs.kubernetes_network_config.ip_family
            end
          end
          
          # Tags
          if cluster_attrs.tags.any?
            tags cluster_attrs.tags
          end
        end
        
        # Return resource reference with available outputs
        # Create resource reference
        ref = ResourceReference.new(
          type: 'aws_eks_cluster',
          name: name,
          resource_attributes: cluster_attrs.to_h,
          outputs: {
            id: "${aws_eks_cluster.#{name}.id}",
            arn: "${aws_eks_cluster.#{name}.arn}",
            name: "${aws_eks_cluster.#{name}.name}",
            endpoint: "${aws_eks_cluster.#{name}.endpoint}",
            platform_version: "${aws_eks_cluster.#{name}.platform_version}",
            version: "${aws_eks_cluster.#{name}.version}",
            status: "${aws_eks_cluster.#{name}.status}",
            role_arn: "${aws_eks_cluster.#{name}.role_arn}",
            vpc_config: "${aws_eks_cluster.#{name}.vpc_config}",
            identity: "${aws_eks_cluster.#{name}.identity}",
            certificate_authority: "${aws_eks_cluster.#{name}.certificate_authority}",
            certificate_authority_data: "${aws_eks_cluster.#{name}.certificate_authority[0].data}",
            created_at: "${aws_eks_cluster.#{name}.created_at}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:encryption_enabled?) { cluster_attrs.encryption_enabled? }
        ref.define_singleton_method(:logging_enabled?) { cluster_attrs.logging_enabled? }
        ref.define_singleton_method(:private_endpoint?) { cluster_attrs.private_endpoint? }
        ref.define_singleton_method(:public_endpoint?) { cluster_attrs.public_endpoint? }
        ref.define_singleton_method(:log_types) { cluster_attrs.enabled_cluster_log_types }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)