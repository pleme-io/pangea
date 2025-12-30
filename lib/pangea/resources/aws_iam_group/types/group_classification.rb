# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Group classification methods for IAM groups
        # Include this module in classes that have `name` and `path` attributes
        module GroupClassification
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
