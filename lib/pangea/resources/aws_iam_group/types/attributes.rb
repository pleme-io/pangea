# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

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
            when :administrative then :high
            when :operations then :high
            when :developer then :medium
            when :department then :medium
            when :environment then :medium
            when :readonly then :low
            else :medium
            end
          end

          # Get suggested access level for group
          def suggested_access_level
            case group_category
            when :administrative then :full_admin
            when :operations then :infrastructure_admin
            when :developer then :development_access
            when :readonly then :read_only
            when :department then :department_specific
            when :environment then :environment_specific
            else :custom
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
            score += 20 if environment_group?
            score += 20 if department_group? || developer_group? || operations_group?
            score += 20 if follows_naming_convention?
            score += 20 if name.length.between?(5, 30)
            score += 20 if organizational_path?
            score
          end
        end
      end
    end
  end
end
