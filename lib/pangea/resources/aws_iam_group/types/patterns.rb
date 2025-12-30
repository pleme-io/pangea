# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
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
      end
    end
  end
end
