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
      # Type-safe attributes for AWS Systems Manager Patch Baseline resources
      class SsmPatchBaselineAttributes < Dry::Struct
        # Patch baseline name (required)
        attribute :name, Resources::Types::String

        # Operating system (required)
        attribute :operating_system, Resources::Types::String.enum(
          "WINDOWS", "AMAZON_LINUX", "AMAZON_LINUX_2", "UBUNTU", 
          "REDHAT_ENTERPRISE_LINUX", "SUSE", "CENTOS", "ORACLE_LINUX",
          "DEBIAN", "MACOS", "RASPBIAN", "ROCKY_LINUX", "ALMA_LINUX"
        )

        # Patch baseline description
        attribute :description, Resources::Types::String.optional

        # Approved patches
        attribute :approved_patches, Resources::Types::Array.of(Types::String).default([].freeze)

        # Rejected patches  
        attribute :rejected_patches, Resources::Types::Array.of(Types::String).default([].freeze)

        # Approved patches compliance level
        attribute :approved_patches_compliance_level, Resources::Types::String.enum(
          "CRITICAL", "HIGH", "MEDIUM", "LOW", "INFORMATIONAL", "UNSPECIFIED"
        ).default("UNSPECIFIED")

        # Whether to enable non-security updates
        attribute :approved_patches_enable_non_security, Resources::Types::Bool.default(false)

        # Rejected patches action
        attribute :rejected_patches_action, Resources::Types::String.enum(
          "ALLOW_AS_DEPENDENCY", "BLOCK"
        ).default("ALLOW_AS_DEPENDENCY")

        # Global filters
        attribute :global_filter, Resources::Types::Array.of(
          Types::Hash.schema(
            key: Types::String.enum(
              "PATCH_SET", "PRODUCT", "PRODUCT_FAMILY", "CLASSIFICATION", 
              "MSRC_SEVERITY", "PATCH_ID", "SECTION", "PRIORITY",
              "REPOSITORY", "SEVERITY", "ARCH", "EPOCH", "RELEASE",
              "VERSION", "NAME", "BUGZILLA_ID", "CVE_ID", "ADVISORY_ID"
            ),
            values: Types::Array.of(Types::String).constrained(min_size: 1)
          )
        ).default([].freeze)

        # Approval rules
        attribute :approval_rule, Resources::Types::Array.of(
          Types::Hash.schema(
            approve_after_days?: Types::Integer.optional.constrained(gteq: 0, lteq: 360),
            approve_until_date?: Types::String.optional,
            compliance_level?: Types::String.enum(
              "CRITICAL", "HIGH", "MEDIUM", "LOW", "INFORMATIONAL", "UNSPECIFIED"
            ).optional,
            enable_non_security?: Types::Bool.optional,
            patch_filter: Types::Array.of(
              Types::Hash.schema(
                key: Types::String.enum(
                  "PATCH_SET", "PRODUCT", "PRODUCT_FAMILY", "CLASSIFICATION", 
                  "MSRC_SEVERITY", "PATCH_ID", "SECTION", "PRIORITY",
                  "REPOSITORY", "SEVERITY", "ARCH", "EPOCH", "RELEASE",
                  "VERSION", "NAME", "BUGZILLA_ID", "CVE_ID", "ADVISORY_ID"
                ),
                values: Types::Array.of(Types::String).constrained(min_size: 1)
              )
            ).constrained(min_size: 1)
          )
        ).default([].freeze)

        # Source configuration (for custom repositories)
        attribute :source, Resources::Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            products: Types::Array.of(Types::String).constrained(min_size: 1),
            configuration: Types::String
          )
        ).default([].freeze)

        # Tags for the patch baseline
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate operating system specific configurations
          case attrs.operating_system
          when "WINDOWS"
            # Validate Windows-specific filters
            attrs.global_filter.each do |filter|
              windows_keys = ["PATCH_SET", "PRODUCT", "PRODUCT_FAMILY", "CLASSIFICATION", "MSRC_SEVERITY", "PATCH_ID"]
              unless windows_keys.include?(filter[:key])
                raise Dry::Struct::Error, "Invalid filter key '#{filter[:key]}' for Windows. Valid keys: #{windows_keys.join(', ')}"
              end
            end
            
            attrs.approval_rule.each do |rule|
              rule[:patch_filter].each do |filter|
                windows_keys = ["PATCH_SET", "PRODUCT", "PRODUCT_FAMILY", "CLASSIFICATION", "MSRC_SEVERITY", "PATCH_ID"]
                unless windows_keys.include?(filter[:key])
                  raise Dry::Struct::Error, "Invalid filter key '#{filter[:key]}' for Windows in approval rule. Valid keys: #{windows_keys.join(', ')}"
                end
              end
            end
          when /\A(AMAZON_LINUX|AMAZON_LINUX_2|CENTOS|ORACLE_LINUX|REDHAT_ENTERPRISE_LINUX|SUSE|ROCKY_LINUX|ALMA_LINUX)\z/
            # Validate Linux-specific filters
            attrs.global_filter.each do |filter|
              linux_keys = ["PATCH_SET", "PRODUCT", "CLASSIFICATION", "SEVERITY", "PATCH_ID", "SECTION", "PRIORITY", "REPOSITORY", "ARCH", "EPOCH", "RELEASE", "VERSION"]
              unless linux_keys.include?(filter[:key])
                raise Dry::Struct::Error, "Invalid filter key '#{filter[:key]}' for #{attrs.operating_system}. Valid keys: #{linux_keys.join(', ')}"
              end
            end
          when /\A(UBUNTU|DEBIAN)\z/
            # Validate Debian/Ubuntu-specific filters
            attrs.global_filter.each do |filter|
              debian_keys = ["PATCH_SET", "PRODUCT", "PRIORITY", "SECTION", "PATCH_ID", "NAME", "VERSION", "ARCH"]
              unless debian_keys.include?(filter[:key])
                raise Dry::Struct::Error, "Invalid filter key '#{filter[:key]}' for #{attrs.operating_system}. Valid keys: #{debian_keys.join(', ')}"
              end
            end
          end

          # Validate approval rules
          attrs.approval_rule.each do |rule|
            # Must specify either approve_after_days or approve_until_date
            if !rule[:approve_after_days] && !rule[:approve_until_date]
              raise Dry::Struct::Error, "Approval rule must specify either approve_after_days or approve_until_date"
            end
            
            if rule[:approve_after_days] && rule[:approve_until_date]
              raise Dry::Struct::Error, "Approval rule cannot specify both approve_after_days and approve_until_date"
            end
            
            # Validate date format
            if rule[:approve_until_date]
              begin
                Date.iso8601(rule[:approve_until_date])
              rescue ArgumentError
                raise Dry::Struct::Error, "approve_until_date must be in ISO 8601 date format (YYYY-MM-DD)"
              end
            end
          end

          # Validate source configurations
          attrs.source.each do |source_config|
            # Validate source name format
            unless source_config[:name].match?(/\A[a-zA-Z0-9_\-\.]{1,50}\z/)
              raise Dry::Struct::Error, "Source name must be 1-50 characters and contain only letters, numbers, hyphens, underscores, and periods"
            end
          end

          # Validate patch IDs format (basic validation)
          all_patches = attrs.approved_patches + attrs.rejected_patches
          all_patches.each do |patch_id|
            if patch_id.empty? || patch_id.length > 100
              raise Dry::Struct::Error, "Patch ID must be 1-100 characters long"
            end
          end

          # Validate description length
          if attrs.description && attrs.description.length > 1024
            raise Dry::Struct::Error, "Description cannot exceed 1024 characters"
          end

          attrs
        end

        # Helper methods
        def is_windows?
          operating_system == "WINDOWS"
        end

        def is_amazon_linux?
          ["AMAZON_LINUX", "AMAZON_LINUX_2"].include?(operating_system)
        end

        def is_redhat_family?
          ["REDHAT_ENTERPRISE_LINUX", "CENTOS", "ORACLE_LINUX", "ROCKY_LINUX", "ALMA_LINUX"].include?(operating_system)
        end

        def is_debian_family?
          ["UBUNTU", "DEBIAN"].include?(operating_system)
        end

        def is_suse?
          operating_system == "SUSE"
        end

        def is_macos?
          operating_system == "MACOS"
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
          rejected_patches_action == "BLOCK"
        end

        def allows_rejected_as_dependency?
          rejected_patches_action == "ALLOW_AS_DEPENDENCY"
        end

        def compliance_level_priority
          levels = {
            "CRITICAL" => 5,
            "HIGH" => 4,
            "MEDIUM" => 3,
            "LOW" => 2,
            "INFORMATIONAL" => 1,
            "UNSPECIFIED" => 0
          }
          levels[approved_patches_compliance_level] || 0
        end

        def total_patch_count
          approved_patches.count + rejected_patches.count
        end

        def filter_summary
          return {} unless has_global_filters?
          
          filters = {}
          global_filter.each do |filter|
            filters[filter[:key]] = filter[:values]
          end
          filters
        end

        def approval_rule_summary
          return [] unless has_approval_rules?
          
          approval_rule.map do |rule|
            summary = {
              compliance_level: rule[:compliance_level] || "UNSPECIFIED",
              enable_non_security: rule[:enable_non_security] || false
            }
            
            if rule[:approve_after_days]
              summary[:approval_method] = "after_#{rule[:approve_after_days]}_days"
            elsif rule[:approve_until_date]
              summary[:approval_method] = "until_#{rule[:approve_until_date]}"
            end
            
            summary[:filter_count] = rule[:patch_filter].count
            summary
          end
        end
      end

      # Common SSM Patch Baseline configurations
      module SsmPatchBaselineConfigs
        # Critical patches only baseline
        def self.critical_patches_baseline(name, operating_system)
          {
            name: name,
            operating_system: operating_system,
            description: "Critical patches only baseline",
            approved_patches_compliance_level: "CRITICAL",
            approval_rule: [
              {
                approve_after_days: 0,
                compliance_level: "CRITICAL",
                patch_filter: [
                  {
                    key: operating_system == "WINDOWS" ? "CLASSIFICATION" : "SEVERITY",
                    values: operating_system == "WINDOWS" ? ["CriticalUpdates", "SecurityUpdates"] : ["Critical"]
                  }
                ]
              }
            ]
          }
        end

        # Security patches baseline
        def self.security_patches_baseline(name, operating_system, approve_after_days: 7)
          filters = if operating_system == "WINDOWS"
            [{ key: "CLASSIFICATION", values: ["SecurityUpdates"] }]
          elsif ["UBUNTU", "DEBIAN"].include?(operating_system)
            [{ key: "PRIORITY", values: ["Important", "Standard"] }]
          else
            [{ key: "CLASSIFICATION", values: ["Security"] }]
          end

          {
            name: name,
            operating_system: operating_system,
            description: "Security patches baseline",
            approved_patches_compliance_level: "HIGH",
            approval_rule: [
              {
                approve_after_days: approve_after_days,
                compliance_level: "HIGH", 
                patch_filter: filters
              }
            ]
          }
        end

        # All patches baseline (except rejected)
        def self.all_patches_baseline(name, operating_system, approve_after_days: 30)
          {
            name: name,
            operating_system: operating_system,
            description: "All patches baseline with #{approve_after_days} day approval delay",
            approved_patches_compliance_level: "MEDIUM",
            approved_patches_enable_non_security: true,
            approval_rule: [
              {
                approve_after_days: approve_after_days,
                compliance_level: "MEDIUM",
                enable_non_security: true,
                patch_filter: [
                  {
                    key: "PATCH_SET",
                    values: ["OS"]
                  }
                ]
              }
            ]
          }
        end

        # Custom patch list baseline
        def self.custom_patches_baseline(name, operating_system, approved_patches: [], rejected_patches: [])
          {
            name: name,
            operating_system: operating_system,
            description: "Custom patch list baseline",
            approved_patches: approved_patches,
            rejected_patches: rejected_patches,
            approved_patches_compliance_level: "MEDIUM"
          }
        end

        # Development environment baseline (all patches, immediate approval)
        def self.development_baseline(name, operating_system)
          {
            name: name,
            operating_system: operating_system,
            description: "Development environment baseline - all patches approved immediately",
            approved_patches_compliance_level: "LOW",
            approved_patches_enable_non_security: true,
            approval_rule: [
              {
                approve_after_days: 0,
                compliance_level: "LOW",
                enable_non_security: true,
                patch_filter: [
                  {
                    key: "PATCH_SET",
                    values: ["OS"]
                  }
                ]
              }
            ]
          }
        end

        # Production environment baseline (security only, delayed approval)
        def self.production_baseline(name, operating_system, approve_after_days: 14)
          filters = if operating_system == "WINDOWS"
            [{ key: "CLASSIFICATION", values: ["CriticalUpdates", "SecurityUpdates"] }]
          elsif ["UBUNTU", "DEBIAN"].include?(operating_system)
            [{ key: "PRIORITY", values: ["Important"] }]
          else
            [{ key: "CLASSIFICATION", values: ["Security"] }, { key: "SEVERITY", values: ["Critical", "Important"] }]
          end

          {
            name: name,
            operating_system: operating_system,
            description: "Production environment baseline - security patches with #{approve_after_days} day delay",
            approved_patches_compliance_level: "HIGH",
            approved_patches_enable_non_security: false,
            rejected_patches_action: "BLOCK",
            approval_rule: [
              {
                approve_after_days: approve_after_days,
                compliance_level: "HIGH",
                enable_non_security: false,
                patch_filter: filters
              }
            ]
          }
        end
      end
    end
      end
    end
  end
end