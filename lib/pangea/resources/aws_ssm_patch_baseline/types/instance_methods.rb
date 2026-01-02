# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module SsmPatchBaselineInstanceMethods
          def is_windows?
            operating_system == 'WINDOWS'
          end

          def is_amazon_linux?
            %w[AMAZON_LINUX AMAZON_LINUX_2].include?(operating_system)
          end

          def is_redhat_family?
            %w[REDHAT_ENTERPRISE_LINUX CENTOS ORACLE_LINUX ROCKY_LINUX ALMA_LINUX].include?(operating_system)
          end

          def is_debian_family?
            %w[UBUNTU DEBIAN].include?(operating_system)
          end

          def is_suse?
            operating_system == 'SUSE'
          end

          def is_macos?
            operating_system == 'MACOS'
          end

          def has_description?
            !description.nil?
          end

          def has_approved_patches?
            approved_patches.any?
          end

          def has_rejected_patches?
            rejected_patches.any?
          end

          def has_global_filters?
            global_filter.any?
          end

          def has_approval_rules?
            approval_rule.any?
          end

          def has_custom_sources?
            source.any?
          end

          def enables_non_security_patches?
            approved_patches_enable_non_security
          end

          def blocks_rejected_patches?
            rejected_patches_action == 'BLOCK'
          end

          def allows_rejected_as_dependency?
            rejected_patches_action == 'ALLOW_AS_DEPENDENCY'
          end

          def compliance_level_priority
            levels = { 'CRITICAL' => 5, 'HIGH' => 4, 'MEDIUM' => 3, 'LOW' => 2, 'INFORMATIONAL' => 1, 'UNSPECIFIED' => 0 }
            levels[approved_patches_compliance_level] || 0
          end

          def total_patch_count
            approved_patches.count + rejected_patches.count
          end

          def filter_summary
            return {} unless has_global_filters?
            global_filter.each_with_object({}) { |filter, h| h[filter[:key]] = filter[:values] }
          end

          def approval_rule_summary
            return [] unless has_approval_rules?
            approval_rule.map do |rule|
              summary = { compliance_level: rule[:compliance_level] || 'UNSPECIFIED', enable_non_security: rule[:enable_non_security] || false }
              summary[:approval_method] = rule[:approve_after_days] ? "after_#{rule[:approve_after_days]}_days" : "until_#{rule[:approve_until_date]}"
              summary[:filter_count] = rule[:patch_filter].count
              summary
            end
          end
        end
      end
    end
  end
end
