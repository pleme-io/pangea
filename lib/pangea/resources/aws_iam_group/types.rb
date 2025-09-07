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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS IAM Group resources
      class IamGroupAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Group name (required)
        attribute :name, Resources::Types::String

        # Path for the group (default: "/")
        attribute :path, Resources::Types::String.default("/")

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate group name meets IAM requirements
          unless attrs.name.match?(/\A[a-zA-Z0-9+=,.@_-]+\z/)
            raise Dry::Struct::Error, "Group name must contain only alphanumeric characters and +=,.@_-"
          end

          if attrs.name.length > 128
            raise Dry::Struct::Error, "Group name cannot exceed 128 characters"
          end

          # Validate path format
          unless attrs.path.match?(/\A\/[\w+=,.@\/-]*\z/)
            raise Dry::Struct::Error, "Path must start with '/' and contain only valid characters"
          end

          if attrs.path.length > 512
            raise Dry::Struct::Error, "Path cannot exceed 512 characters"
          end

          # Validate group security
          attrs.validate_group_security!

          attrs
        end

        # Check if group name suggests administrative access
        def administrative_group?
          name.downcase.include?('admin') || 
          name.downcase.include?('root') || 
          name.downcase.include?('super') ||
          name.downcase.include?('power')
        end

        # Check if group is for developers
        def developer_group?
          name.downcase.include?('dev') || 
          name.downcase.include?('engineer') ||
          name.downcase.include?('programmer')
        end

        # Check if group is for operations
        def operations_group?
          name.downcase.include?('ops') || 
          name.downcase.include?('sre') ||
          name.downcase.include?('infrastructure') ||
          name.downcase.include?('platform')
        end

        # Check if group is for read-only access
        def readonly_group?
          name.downcase.include?('read') || 
          name.downcase.include?('view') ||
          name.downcase.include?('audit') ||
          name.downcase.include?('monitor')
        end

        # Check if group is department-specific
        def department_group?
          departments = ['engineering', 'finance', 'hr', 'marketing', 'sales', 'legal', 'security']
          departments.any? { |dept| name.downcase.include?(dept) }
        end

        # Check if group is environment-specific
        def environment_group?
          environments = ['dev', 'test', 'staging', 'prod', 'development', 'production']
          environments.any? { |env| name.downcase.include?(env) }
        end

        # Check if group is in organizational path
        def organizational_path?
          path != "/" && path.include?("/")
        end

        # Extract organizational unit from path
        def organizational_unit
          return nil unless organizational_path?
          path.split('/').reject(&:empty?).first
        end

        # Generate group ARN
        def group_arn(account_id = "123456789012")
          "arn:aws:iam::#{account_id}:group#{path}#{name}"
        end

        # Categorize group by purpose
        def group_category
          if administrative_group?
            :administrative
          elsif developer_group?
            :developer
          elsif operations_group?
            :operations
          elsif readonly_group?
            :readonly
          elsif department_group?
            :department
          elsif environment_group?
            :environment
          else
            :functional
          end
        end

        # Assess security risk level for group
        def security_risk_level
          case group_category
          when :administrative
            :high
          when :operations
            :high
          when :developer
            :medium
          when :department
            :medium
          when :environment
            :medium
          when :readonly
            :low
          else
            :medium
          end
        end

        # Get suggested access level for group
        def suggested_access_level
          case group_category
          when :administrative
            :full_admin
          when :operations
            :infrastructure_admin
          when :developer
            :development_access
          when :readonly
            :read_only
          when :department
            :department_specific
          when :environment
            :environment_specific
          else
            :custom
          end
        end

        # Validate group for security best practices
        def validate_group_security!
          warnings = []

          # Check for overly broad group names
          broad_names = ['users', 'all', 'everyone', 'default']
          if broad_names.any? { |broad| name.downcase.include?(broad) }
            warnings << "Group name '#{name}' is very broad - consider more specific grouping"
          end

          # Check for admin groups without organizational structure
          if administrative_group? && path == "/"
            warnings << "Administrative group '#{name}' should be in organized path structure"
          end

          # Check for environment groups without proper paths
          if environment_group? && !path.include?(extract_environment_from_name)
            warnings << "Environment group '#{name}' should be in environment-specific path"
          end

          # Log warnings but don't fail validation
          unless warnings.empty?
            puts "IAM Group Security Warnings for '#{name}':"
            warnings.each { |warning| puts "  - #{warning}" }
          end
        end

        # Extract environment name from group name
        def extract_environment_from_name
          environments = ['development', 'dev', 'testing', 'test', 'staging', 'stage', 'production', 'prod']
          environments.find { |env| name.downcase.include?(env) }
        end

        # Extract department name from group name
        def extract_department_from_name
          departments = ['engineering', 'finance', 'hr', 'marketing', 'sales', 'legal', 'security']
          departments.find { |dept| name.downcase.include?(dept) }
        end

        # Check if group name follows naming conventions
        def follows_naming_convention?
          # Expect format like: Department-Role-Environment or Role-Environment
          name.include?('-') && !name.start_with?('-') && !name.end_with?('-')
        end

        # Get naming convention score (0-100)
        def naming_convention_score
          score = 0
          
          # Points for including environment
          score += 20 if environment_group?
          
          # Points for including department/function
          score += 20 if department_group? || developer_group? || operations_group?
          
          # Points for following hyphen convention
          score += 20 if follows_naming_convention?
          
          # Points for appropriate length
          score += 20 if name.length.between?(5, 30)
          
          # Points for organizational path
          score += 20 if organizational_path?
          
          score
        end
      end

      # Group patterns for common organizational structures
      module GroupPatterns
        # Development teams
        def self.development_team_group(team_name, department = "engineering")
          {
            name: "#{department}-#{team_name}-developers",
            path: "/teams/#{department}/#{team_name}/"
          }
        end

        # Environment-based access groups
        def self.environment_access_group(environment, access_level = "deploy")
          {
            name: "#{environment}-#{access_level}",
            path: "/environments/#{environment}/"
          }
        end

        # Department-based groups
        def self.department_group(department, access_level = "standard")
          {
            name: "#{department}-#{access_level}",
            path: "/departments/#{department}/"
          }
        end

        # Administrative groups
        def self.admin_group(scope = "infrastructure", department = "platform")
          {
            name: "#{department}-#{scope}-admins",
            path: "/admins/#{department}/"
          }
        end

        # Read-only access groups
        def self.readonly_group(scope, purpose = "monitoring")
          {
            name: "#{scope}-readonly-#{purpose}",
            path: "/readonly/"
          }
        end

        # Service-specific groups
        def self.service_group(service_name, access_level = "operator")
          {
            name: "#{service_name}-#{access_level}",
            path: "/services/#{service_name}/"
          }
        end

        # Cross-functional groups
        def self.cross_functional_group(function, stakeholders = nil)
          path_suffix = stakeholders ? "/#{stakeholders.join('-')}/" : "/"
          {
            name: "#{function}-cross-functional",
            path: "/cross-functional#{path_suffix}"
          }
        end

        # Compliance and audit groups
        def self.compliance_group(framework, access_level = "auditor")
          {
            name: "#{framework}-#{access_level}",
            path: "/compliance/#{framework}/"
          }
        end

        # CI/CD groups
        def self.cicd_group(pipeline_scope, environment = nil)
          env_suffix = environment ? "-#{environment}" : ""
          {
            name: "cicd-#{pipeline_scope}#{env_suffix}",
            path: "/cicd/"
          }
        end

        # Emergency access groups
        def self.emergency_group(scope = "breakglass")
          {
            name: "emergency-#{scope}",
            path: "/emergency/"
          }
        end
      end

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
end