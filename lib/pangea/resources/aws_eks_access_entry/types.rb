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


require 'dry-struct'

module Pangea
  module Resources
    module AWS
      module EksAccessEntry
        # Common types for EKS Access Entry configurations
        class Types < Dry::Types::Module
          include Dry.Types()

          # EKS Cluster Name constraint
          ClusterName = String.constrained(
            min_size: 1,
            max_size: 100,
            format: /\A[a-zA-Z0-9\-_]+\z/
          )
          
          # IAM Principal ARN constraint
          PrincipalArn = String.constrained(
            format: /\Aarn:aws:iam::[0-9]{12}:(user|role)\/[a-zA-Z0-9+=,.@\-_\/]+\z/
          )
          
          # Access entry type
          AccessEntryType = String.enum('STANDARD', 'FARGATE_LINUX', 'EC2_LINUX', 'EC2_WINDOWS')
          
          # Kubernetes groups
          KubernetesGroup = String.constrained(min_size: 1, max_size: 63)
        end

        # EKS Access Entry attributes with comprehensive validation
        class EksAccessEntryAttributes < Dry::Struct
          include Types[self]
          
          # Required attributes
          attribute :cluster_name, ClusterName
          attribute :principal_arn, PrincipalArn
          
          # Optional attributes
          attribute? :kubernetes_groups, Array.of(KubernetesGroup).optional
          attribute? :type, AccessEntryType.optional
          attribute? :user_name, String.optional
          attribute? :tags, Hash.map(String, String).default({}.freeze)
          
          # Computed properties
          def principal_name
            principal_arn.split('/')[-1]
          end
          
          def principal_type
            if principal_arn.include?('user/')
              'user'
            elsif principal_arn.include?('role/')
              'role'
            else
              'unknown'
            end
          end
          
          def account_id
            principal_arn.split(':')[4]
          end
          
          def has_kubernetes_groups?
            kubernetes_groups && kubernetes_groups.any?
          end
          
          def has_custom_username?
            !user_name.nil?
          end
          
          def standard_type?
            type == 'STANDARD' || type.nil?
          end
          
          def fargate_type?
            type == 'FARGATE_LINUX'
          end
          
          def ec2_linux_type?
            type == 'EC2_LINUX'
          end
          
          def ec2_windows_type?
            type == 'EC2_WINDOWS'
          end
          
          def kubernetes_groups_count
            kubernetes_groups&.length || 0
          end
        end
      end
    end
  end
end