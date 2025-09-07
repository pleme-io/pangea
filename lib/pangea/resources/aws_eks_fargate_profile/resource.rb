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
require 'pangea/resources/aws_eks_fargate_profile/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EKS Fargate Profile with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] EKS Fargate profile attributes
      # @option attributes [String] :cluster_name EKS cluster name (required)
      # @option attributes [String] :fargate_profile_name Custom profile name
      # @option attributes [String] :pod_execution_role_arn IAM role for pods (required)
      # @option attributes [Array<Hash>] :selectors Pod selectors (required, 1-5 selectors)
      # @option attributes [Array<String>] :subnet_ids Private subnet IDs
      # @option attributes [Hash] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Basic Fargate profile for default namespace
      #   fargate_default = aws_eks_fargate_profile(:default, {
      #     cluster_name: cluster.name,
      #     pod_execution_role_arn: fargate_role.arn,
      #     selectors: [{
      #       namespace: "default"
      #     }]
      #   })
      #
      # @example Fargate profile with multiple selectors and labels
      #   fargate_apps = aws_eks_fargate_profile(:apps, {
      #     cluster_name: cluster.name,
      #     pod_execution_role_arn: fargate_role.arn,
      #     subnet_ids: private_subnet_ids,
      #     selectors: [
      #       {
      #         namespace: "production",
      #         labels: { compute: "fargate", tier: "web" }
      #       },
      #       {
      #         namespace: "staging",
      #         labels: { compute: "fargate" }
      #       },
      #       {
      #         namespace: "kube-system",
      #         labels: { k8s_app: "kube-dns" }
      #       }
      #     ],
      #     tags: {
      #       Environment: "production",
      #       ManagedBy: "terraform"
      #     }
      #   })
      #
      # @example System workloads on Fargate
      #   fargate_system = aws_eks_fargate_profile(:system, {
      #     fargate_profile_name: "system-workloads",
      #     cluster_name: cluster.name,
      #     pod_execution_role_arn: fargate_role.arn,
      #     selectors: [
      #       { namespace: "kube-system", labels: { k8s_app: "kube-dns" } },
      #       { namespace: "cert-manager" },
      #       { namespace: "external-dns" }
      #     ]
      #   })
      #
      # @example Batch processing workloads
      #   fargate_batch = aws_eks_fargate_profile(:batch, {
      #     cluster_name: cluster.name,
      #     pod_execution_role_arn: fargate_role.arn,
      #     subnet_ids: private_subnet_ids,
      #     selectors: [{
      #       namespace: "batch-jobs",
      #       labels: {
      #         workload: "batch",
      #         compute: "serverless"
      #       }
      #     }]
      #   })
      def aws_eks_fargate_profile(name, attributes = {})
        # Validate attributes using dry-struct
        profile_attrs = Types::Types::EksFargateProfileAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_eks_fargate_profile, name) do
          # Required attributes
          cluster_name profile_attrs.cluster_name
          pod_execution_role_arn profile_attrs.pod_execution_role_arn
          
          # Optional custom name
          fargate_profile_name profile_attrs.fargate_profile_name if profile_attrs.fargate_profile_name
          
          # Subnet IDs (optional - uses cluster subnets if not specified)
          subnet_ids profile_attrs.subnet_ids if profile_attrs.subnet_ids
          
          # Selectors - convert array of selectors to blocks
          profile_attrs.selectors.each do |selector_config|
            selector do
              namespace selector_config.namespace
              labels selector_config.labels if selector_config.labels.any?
            end
          end
          
          # Tags
          tags profile_attrs.tags if profile_attrs.tags.any?
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_eks_fargate_profile',
          name: name,
          resource_attributes: profile_attrs.to_h,
          outputs: {
            id: "${aws_eks_fargate_profile.#{name}.id}",
            arn: "${aws_eks_fargate_profile.#{name}.arn}",
            cluster_name: "${aws_eks_fargate_profile.#{name}.cluster_name}",
            fargate_profile_name: "${aws_eks_fargate_profile.#{name}.fargate_profile_name}",
            pod_execution_role_arn: "${aws_eks_fargate_profile.#{name}.pod_execution_role_arn}",
            subnet_ids: "${aws_eks_fargate_profile.#{name}.subnet_ids}",
            status: "${aws_eks_fargate_profile.#{name}.status}",
            tags_all: "${aws_eks_fargate_profile.#{name}.tags_all}"
          },
          computed_properties: {
            namespaces: profile_attrs.namespaces,
            has_labels: profile_attrs.has_labels?,
            selector_count: profile_attrs.selector_count,
            selectors: profile_attrs.selectors.map(&:to_h)
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)