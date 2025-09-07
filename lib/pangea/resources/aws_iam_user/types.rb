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
      # Type-safe attributes for AWS IAM User resources
      class IamUserAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # User name (required)
        attribute :name, Resources::Types::String

        # Path for the user (default: "/")
        attribute :path, Resources::Types::String.default("/")

        # Permissions boundary ARN
        attribute :permissions_boundary, Resources::Types::String.optional

        # Force destroy user on deletion (removes dependencies)
        attribute :force_destroy, Resources::Types::Bool.default(false)

        # Tags to apply to the user
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate user name meets IAM requirements
          unless attrs.name.match?(/\A[a-zA-Z0-9+=,.@_-]+\z/)
            raise Dry::Struct::Error, "User name must contain only alphanumeric characters and +=,.@_-"
          end

          if attrs.name.length > 64
            raise Dry::Struct::Error, "User name cannot exceed 64 characters"
          end

          # Validate path format
          unless attrs.path.match?(/\A\/[\w+=,.@-]*\/?\z/)
            raise Dry::Struct::Error, "Path must start with '/' and contain only valid characters"
          end

          if attrs.path.length > 512
            raise Dry::Struct::Error, "Path cannot exceed 512 characters"
          end

          # Validate permissions boundary ARN format if provided
          if attrs.permissions_boundary && 
             !attrs.permissions_boundary.match?(/\Aarn:aws:iam::[0-9]{12}:policy\/.*\z/)
            raise Dry::Struct::Error, "permissions_boundary must be a valid IAM policy ARN"
          end

          # Check for potentially risky user names
          attrs.validate_user_security!

          attrs
        end

        # Check if user name suggests administrative access
        def administrative_user?
          name.downcase.include?('admin') || 
          name.downcase.include?('root') || 
          name.downcase.include?('super')
        end

        # Check if user name suggests service account
        def service_user?
          name.downcase.include?('service') || 
          name.downcase.include?('svc') || 
          name.downcase.include?('app') ||
          name.downcase.include?('system')
        end

        # Check if user name suggests human user
        def human_user?
          !service_user? && !administrative_user? && name.include?('.')
        end

        # Check if user is in a specific organizational path
        def organizational_path?
          path != "/" && path.include?("/")
        end

        # Extract organizational unit from path
        def organizational_unit
          return nil unless organizational_path?
          path.split('/').reject(&:empty?).first
        end

        # Generate user ARN
        def user_arn(account_id = "123456789012")
          "arn:aws:iam::#{account_id}:user#{path}#{name}"
        end

        # Check if user has permissions boundary
        def has_permissions_boundary?
          !permissions_boundary.nil?
        end

        # Extract permissions boundary policy name
        def permissions_boundary_policy_name
          return nil unless has_permissions_boundary?
          permissions_boundary.split('/').last
        end

        # Categorize user by type
        def user_category
          if administrative_user?
            :administrative
          elsif service_user?
            :service_account
          elsif human_user?
            :human_user
          else
            :generic
          end
        end

        # Assess security risk level for user
        def security_risk_level
          if administrative_user? && !has_permissions_boundary?
            :high
          elsif service_user? && !has_permissions_boundary?
            :medium
          elsif has_permissions_boundary?
            :low
          else
            :medium
          end
        end

        # Validate user for security best practices
        def validate_user_security!
          warnings = []

          # Check for admin users without permissions boundary
          if administrative_user? && !has_permissions_boundary?
            warnings << "Administrative user '#{name}' should have a permissions boundary"
          end

          # Check for users with potentially unsafe names
          unsafe_names = ['root', 'admin', 'administrator', 'sa', 'service']
          if unsafe_names.any? { |unsafe| name.downcase == unsafe }
            warnings << "User name '#{name}' matches common attack targets - consider more specific naming"
          end

          # Check for users in root path for organizational accounts
          if path == "/" && !name.include?('.')
            warnings << "User '#{name}' is in root path - consider organizational path structure"
          end

          # Log warnings but don't fail validation
          unless warnings.empty?
            puts "IAM User Security Warnings for '#{name}':"
            warnings.each { |warning| puts "  - #{warning}" }
          end
        end

        # Generate secure random password
        def self.generate_secure_password(length = 16)
          # Password with uppercase, lowercase, numbers, and symbols
          charset = [
            ('A'..'Z').to_a,
            ('a'..'z').to_a, 
            ('0'..'9').to_a,
            ['!', '@', '#', '$', '%', '^', '&', '*']
          ].flatten
          
          Array.new(length) { charset.sample }.join
        end
      end

      # IAM user access patterns for different use cases
      module UserPatterns
        # Developer user with limited access
        def self.developer_user(name, organizational_unit = "developers")
          {
            name: name,
            path: "/#{organizational_unit}/",
            permissions_boundary: "arn:aws:iam::123456789012:policy/DeveloperPermissionsBoundary",
            tags: {
              UserType: "Developer",
              Department: organizational_unit.capitalize,
              AccessLevel: "Limited"
            }
          }
        end

        # Service account user
        def self.service_account_user(service_name, environment = "production")
          {
            name: "#{service_name}-service",
            path: "/service-accounts/#{environment}/",
            permissions_boundary: "arn:aws:iam::123456789012:policy/ServiceAccountPermissionsBoundary",
            force_destroy: true, # Service accounts can be safely destroyed
            tags: {
              UserType: "ServiceAccount",
              Service: service_name,
              Environment: environment,
              AutomationManaged: "true"
            }
          }
        end

        # CI/CD pipeline user
        def self.cicd_user(pipeline_name, repository = nil)
          {
            name: "#{pipeline_name}-cicd",
            path: "/cicd/",
            permissions_boundary: "arn:aws:iam::123456789012:policy/CICDPermissionsBoundary",
            force_destroy: true,
            tags: {
              UserType: "CICD",
              Pipeline: pipeline_name,
              Repository: repository,
              AutomationManaged: "true"
            }.compact
          }
        end

        # Administrative user with strict boundary
        def self.admin_user(name, department = "infrastructure")
          {
            name: "#{name}.admin",
            path: "/admins/#{department}/",
            permissions_boundary: "arn:aws:iam::123456789012:policy/AdminPermissionsBoundary",
            tags: {
              UserType: "Administrator",
              Department: department.capitalize,
              AccessLevel: "Elevated",
              RequiresApproval: "true"
            }
          }
        end

        # Read-only user for monitoring/auditing
        def self.readonly_user(name, purpose = "monitoring")
          {
            name: "#{name}.readonly",
            path: "/readonly/",
            permissions_boundary: "arn:aws:iam::123456789012:policy/ReadOnlyPermissionsBoundary",
            tags: {
              UserType: "ReadOnly",
              Purpose: purpose.capitalize,
              AccessLevel: "ReadOnly"
            }
          }
        end

        # Emergency break-glass user
        def self.emergency_user(name)
          {
            name: "#{name}.emergency",
            path: "/emergency/",
            # No permissions boundary for true emergency access
            tags: {
              UserType: "Emergency",
              AccessLevel: "BreakGlass",
              RequiresApproval: "true",
              AuditRequired: "true"
            }
          }
        end

        # Cross-account access user
        def self.cross_account_user(name, target_account_id)
          {
            name: "#{name}.crossaccount",
            path: "/cross-account/",
            permissions_boundary: "arn:aws:iam::123456789012:policy/CrossAccountPermissionsBoundary",
            tags: {
              UserType: "CrossAccount",
              TargetAccount: target_account_id,
              AccessPattern: "AssumeRole"
            }
          }
        end
      end

      # Common permissions boundaries for different user types
      module PermissionsBoundaries
        # Developer permissions boundary - limits to development resources
        DEVELOPER_BOUNDARY = "arn:aws:iam::123456789012:policy/DeveloperPermissionsBoundary"

        # Service account boundary - limits to application resources
        SERVICE_ACCOUNT_BOUNDARY = "arn:aws:iam::123456789012:policy/ServiceAccountPermissionsBoundary"

        # CI/CD boundary - limits to deployment and testing resources
        CICD_BOUNDARY = "arn:aws:iam::123456789012:policy/CICDPermissionsBoundary"

        # Admin boundary - prevents privilege escalation while allowing admin tasks
        ADMIN_BOUNDARY = "arn:aws:iam::123456789012:policy/AdminPermissionsBoundary"

        # Read-only boundary - ensures only read access
        READONLY_BOUNDARY = "arn:aws:iam::123456789012:policy/ReadOnlyPermissionsBoundary"

        # Cross-account boundary - limits to assume role permissions
        CROSS_ACCOUNT_BOUNDARY = "arn:aws:iam::123456789012:policy/CrossAccountPermissionsBoundary"

        # Helper methods
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
          else nil
          end
        end
      end
    end
      end
    end
  end
end