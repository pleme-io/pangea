# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Common access patterns for different types of groups
        module GroupAccessPatterns
          # Developer access levels
          DEVELOPER_FULL = :developer_full_access
          DEVELOPER_LIMITED = :developer_limited_access
          DEVELOPER_READONLY = :developer_readonly_access

          # Operations access levels
          OPERATIONS_FULL = :operations_full_access
          OPERATIONS_INFRASTRUCTURE = :operations_infrastructure_access
          OPERATIONS_MONITORING = :operations_monitoring_access

          # Department access levels
          DEPARTMENT_STANDARD = :department_standard_access
          DEPARTMENT_ELEVATED = :department_elevated_access
          DEPARTMENT_READONLY = :department_readonly_access

          # Environment access levels
          ENVIRONMENT_ADMIN = :environment_admin_access
          ENVIRONMENT_DEPLOY = :environment_deploy_access
          ENVIRONMENT_READONLY = :environment_readonly_access

          # Service access levels
          SERVICE_OWNER = :service_owner_access
          SERVICE_OPERATOR = :service_operator_access
          SERVICE_VIEWER = :service_viewer_access

          # Cross-functional access levels
          CROSS_FUNCTIONAL_LEAD = :cross_functional_lead_access
          CROSS_FUNCTIONAL_MEMBER = :cross_functional_member_access
          CROSS_FUNCTIONAL_OBSERVER = :cross_functional_observer_access

          def self.access_pattern_for_group_category(category)
            case category
            when :developer
              [DEVELOPER_LIMITED, DEVELOPER_READONLY]
            when :operations
              [OPERATIONS_INFRASTRUCTURE, OPERATIONS_MONITORING]
            when :administrative
              [:full_admin_access]
            when :readonly
              [DEPARTMENT_READONLY, ENVIRONMENT_READONLY, SERVICE_VIEWER]
            when :department
              [DEPARTMENT_STANDARD, DEPARTMENT_READONLY]
            when :environment
              [ENVIRONMENT_DEPLOY, ENVIRONMENT_READONLY]
            else
              [:custom_access]
            end
          end

          def self.recommended_policies_for_pattern(pattern)
            case pattern
            when DEVELOPER_READONLY
              ["ReadOnlyAccess", "DeveloperToolsReadOnly"]
            when DEVELOPER_LIMITED
              ["PowerUserAccess", "DeveloperToolsAccess"]
            when OPERATIONS_MONITORING
              ["CloudWatchReadOnlyAccess", "SystemsManagerReadOnly"]
            when OPERATIONS_INFRASTRUCTURE
              ["EC2FullAccess", "VPCFullAccess", "CloudWatchFullAccess"]
            when ENVIRONMENT_READONLY
              ["ReadOnlyAccess"]
            when ENVIRONMENT_DEPLOY
              ["CodeDeployAccess", "CodeBuildAccess", "S3DeploymentAccess"]
            else
              []
            end
          end
        end
      end
    end
  end
end
