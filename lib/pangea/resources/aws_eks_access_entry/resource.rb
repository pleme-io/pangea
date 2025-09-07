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
require 'pangea/resources/aws_eks_access_entry/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EKS Access Entry with type-safe attributes
      #
      # EKS Access Entries provide fine-grained access control for EKS clusters.
      # They define which IAM principals can access the cluster and what Kubernetes
      # groups they belong to, replacing the aws-auth ConfigMap for access management.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] EKS access entry attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_eks_access_entry(name, attributes = {})
        # Validate attributes using dry-struct
        entry_attrs = EksAccessEntry::Types::EksAccessEntryAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_eks_access_entry, name) do
          # Required attributes
          cluster_name entry_attrs.cluster_name
          principal_arn entry_attrs.principal_arn
          
          # Optional attributes
          kubernetes_groups entry_attrs.kubernetes_groups if entry_attrs.kubernetes_groups
          type entry_attrs.type if entry_attrs.type
          user_name entry_attrs.user_name if entry_attrs.user_name
          
          # Apply tags
          if entry_attrs.tags.any?
            tags do
              entry_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_eks_access_entry',
          name: name,
          resource_attributes: entry_attrs.to_h,
          outputs: {
            id: "${aws_eks_access_entry.#{name}.id}",
            access_entry_arn: "${aws_eks_access_entry.#{name}.access_entry_arn}",
            cluster_name: "${aws_eks_access_entry.#{name}.cluster_name}",
            created_at: "${aws_eks_access_entry.#{name}.created_at}",
            modified_at: "${aws_eks_access_entry.#{name}.modified_at}",
            principal_arn: "${aws_eks_access_entry.#{name}.principal_arn}",
            tags_all: "${aws_eks_access_entry.#{name}.tags_all}"
          },
          computed: {
            principal_name: entry_attrs.principal_name,
            principal_type: entry_attrs.principal_type,
            account_id: entry_attrs.account_id,
            has_kubernetes_groups: entry_attrs.has_kubernetes_groups?,
            has_custom_username: entry_attrs.has_custom_username?,
            standard_type: entry_attrs.standard_type?,
            fargate_type: entry_attrs.fargate_type?,
            ec2_linux_type: entry_attrs.ec2_linux_type?,
            ec2_windows_type: entry_attrs.ec2_windows_type?,
            kubernetes_groups_count: entry_attrs.kubernetes_groups_count
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)