# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module SsmPatchBaselineConfigs
          def self.critical_patches_baseline(name, operating_system)
            {
              name: name, operating_system: operating_system, description: 'Critical patches only baseline',
              approved_patches_compliance_level: 'CRITICAL',
              approval_rule: [{
                approve_after_days: 0, compliance_level: 'CRITICAL',
                patch_filter: [{ key: operating_system == 'WINDOWS' ? 'CLASSIFICATION' : 'SEVERITY',
                                 values: operating_system == 'WINDOWS' ? %w[CriticalUpdates SecurityUpdates] : ['Critical'] }]
              }]
            }
          end

          def self.security_patches_baseline(name, operating_system, approve_after_days: 7)
            filters = security_filters_for_os(operating_system)
            {
              name: name, operating_system: operating_system, description: 'Security patches baseline',
              approved_patches_compliance_level: 'HIGH',
              approval_rule: [{ approve_after_days: approve_after_days, compliance_level: 'HIGH', patch_filter: filters }]
            }
          end

          def self.all_patches_baseline(name, operating_system, approve_after_days: 30)
            {
              name: name, operating_system: operating_system,
              description: "All patches baseline with #{approve_after_days} day approval delay",
              approved_patches_compliance_level: 'MEDIUM', approved_patches_enable_non_security: true,
              approval_rule: [{
                approve_after_days: approve_after_days, compliance_level: 'MEDIUM', enable_non_security: true,
                patch_filter: [{ key: 'PATCH_SET', values: ['OS'] }]
              }]
            }
          end

          def self.custom_patches_baseline(name, operating_system, approved_patches: [], rejected_patches: [])
            {
              name: name, operating_system: operating_system, description: 'Custom patch list baseline',
              approved_patches: approved_patches, rejected_patches: rejected_patches, approved_patches_compliance_level: 'MEDIUM'
            }
          end

          def self.development_baseline(name, operating_system)
            {
              name: name, operating_system: operating_system,
              description: 'Development environment baseline - all patches approved immediately',
              approved_patches_compliance_level: 'LOW', approved_patches_enable_non_security: true,
              approval_rule: [{
                approve_after_days: 0, compliance_level: 'LOW', enable_non_security: true,
                patch_filter: [{ key: 'PATCH_SET', values: ['OS'] }]
              }]
            }
          end

          def self.production_baseline(name, operating_system, approve_after_days: 14)
            filters = production_filters_for_os(operating_system)
            {
              name: name, operating_system: operating_system,
              description: "Production environment baseline - security patches with #{approve_after_days} day delay",
              approved_patches_compliance_level: 'HIGH', approved_patches_enable_non_security: false,
              rejected_patches_action: 'BLOCK',
              approval_rule: [{
                approve_after_days: approve_after_days, compliance_level: 'HIGH', enable_non_security: false, patch_filter: filters
              }]
            }
          end

          def self.security_filters_for_os(operating_system)
            case operating_system
            when 'WINDOWS' then [{ key: 'CLASSIFICATION', values: ['SecurityUpdates'] }]
            when 'UBUNTU', 'DEBIAN' then [{ key: 'PRIORITY', values: %w[Important Standard] }]
            else [{ key: 'CLASSIFICATION', values: ['Security'] }]
            end
          end

          def self.production_filters_for_os(operating_system)
            case operating_system
            when 'WINDOWS' then [{ key: 'CLASSIFICATION', values: %w[CriticalUpdates SecurityUpdates] }]
            when 'UBUNTU', 'DEBIAN' then [{ key: 'PRIORITY', values: ['Important'] }]
            else [{ key: 'CLASSIFICATION', values: ['Security'] }, { key: 'SEVERITY', values: %w[Critical Important] }]
            end
          end
        end
      end
    end
  end
end
