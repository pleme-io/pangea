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
        # IAM user access patterns for different use cases
        module UserPatterns
          def self.developer_user(name, organizational_unit = 'developers')
            {
              name: name,
              path: "/#{organizational_unit}/",
              permissions_boundary: 'arn:aws:iam::123456789012:policy/DeveloperPermissionsBoundary',
              tags: {
                UserType: 'Developer',
                Department: organizational_unit.capitalize,
                AccessLevel: 'Limited'
              }
            }
          end

          def self.service_account_user(service_name, environment = 'production')
            {
              name: "#{service_name}-service",
              path: "/service-accounts/#{environment}/",
              permissions_boundary: 'arn:aws:iam::123456789012:policy/ServiceAccountPermissionsBoundary',
              force_destroy: true,
              tags: {
                UserType: 'ServiceAccount',
                Service: service_name,
                Environment: environment,
                AutomationManaged: 'true'
              }
            }
          end

          def self.cicd_user(pipeline_name, repository = nil)
            {
              name: "#{pipeline_name}-cicd",
              path: '/cicd/',
              permissions_boundary: 'arn:aws:iam::123456789012:policy/CICDPermissionsBoundary',
              force_destroy: true,
              tags: {
                UserType: 'CICD',
                Pipeline: pipeline_name,
                Repository: repository,
                AutomationManaged: 'true'
              }.compact
            }
          end

          def self.admin_user(name, department = 'infrastructure')
            {
              name: "#{name}.admin",
              path: "/admins/#{department}/",
              permissions_boundary: 'arn:aws:iam::123456789012:policy/AdminPermissionsBoundary',
              tags: {
                UserType: 'Administrator',
                Department: department.capitalize,
                AccessLevel: 'Elevated',
                RequiresApproval: 'true'
              }
            }
          end

          def self.readonly_user(name, purpose = 'monitoring')
            {
              name: "#{name}.readonly",
              path: '/readonly/',
              permissions_boundary: 'arn:aws:iam::123456789012:policy/ReadOnlyPermissionsBoundary',
              tags: {
                UserType: 'ReadOnly',
                Purpose: purpose.capitalize,
                AccessLevel: 'ReadOnly'
              }
            }
          end

          def self.emergency_user(name)
            {
              name: "#{name}.emergency",
              path: '/emergency/',
              tags: {
                UserType: 'Emergency',
                AccessLevel: 'BreakGlass',
                RequiresApproval: 'true',
                AuditRequired: 'true'
              }
            }
          end

          def self.cross_account_user(name, target_account_id)
            {
              name: "#{name}.crossaccount",
              path: '/cross-account/',
              permissions_boundary: 'arn:aws:iam::123456789012:policy/CrossAccountPermissionsBoundary',
              tags: {
                UserType: 'CrossAccount',
                TargetAccount: target_account_id,
                AccessPattern: 'AssumeRole'
              }
            }
          end
        end

        # Common permissions boundaries for different user types
        module PermissionsBoundaries
          DEVELOPER_BOUNDARY = 'arn:aws:iam::123456789012:policy/DeveloperPermissionsBoundary'
          SERVICE_ACCOUNT_BOUNDARY = 'arn:aws:iam::123456789012:policy/ServiceAccountPermissionsBoundary'
          CICD_BOUNDARY = 'arn:aws:iam::123456789012:policy/CICDPermissionsBoundary'
          ADMIN_BOUNDARY = 'arn:aws:iam::123456789012:policy/AdminPermissionsBoundary'
          READONLY_BOUNDARY = 'arn:aws:iam::123456789012:policy/ReadOnlyPermissionsBoundary'
          CROSS_ACCOUNT_BOUNDARY = 'arn:aws:iam::123456789012:policy/CrossAccountPermissionsBoundary'

          def self.all_boundaries
            constants.map { |const| const_get(const) }.select { |val| val.is_a?(String) }
          end

          def self.boundary_for_user_type(user_type)
            case user_type
            when :developer then DEVELOPER_BOUNDARY
            when :service_account then SERVICE_ACCOUNT_BOUNDARY
            when :cicd then CICD_BOUNDARY
            when :administrator then ADMIN_BOUNDARY
            when :readonly then READONLY_BOUNDARY
            when :cross_account then CROSS_ACCOUNT_BOUNDARY
            end
          end
        end
      end
    end
  end
end
