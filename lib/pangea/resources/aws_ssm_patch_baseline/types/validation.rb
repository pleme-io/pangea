# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module SsmPatchBaselineValidation
          WINDOWS_KEYS = %w[PATCH_SET PRODUCT PRODUCT_FAMILY CLASSIFICATION MSRC_SEVERITY PATCH_ID].freeze
          LINUX_KEYS = %w[PATCH_SET PRODUCT CLASSIFICATION SEVERITY PATCH_ID SECTION PRIORITY REPOSITORY ARCH EPOCH RELEASE VERSION].freeze
          DEBIAN_KEYS = %w[PATCH_SET PRODUCT PRIORITY SECTION PATCH_ID NAME VERSION ARCH].freeze

          def validate_os_filters(attrs)
            case attrs.operating_system
            when 'WINDOWS'
              validate_windows_filters(attrs)
            when /\A(AMAZON_LINUX|AMAZON_LINUX_2|CENTOS|ORACLE_LINUX|REDHAT_ENTERPRISE_LINUX|SUSE|ROCKY_LINUX|ALMA_LINUX)\z/
              validate_linux_filters(attrs)
            when /\A(UBUNTU|DEBIAN)\z/
              validate_debian_filters(attrs)
            end
          end

          def validate_windows_filters(attrs)
            validate_filter_keys(attrs.global_filter, WINDOWS_KEYS, 'Windows')
            attrs.approval_rule.each do |rule|
              rule[:patch_filter].each do |filter|
                unless WINDOWS_KEYS.include?(filter[:key])
                  raise Dry::Struct::Error, "Invalid filter key '#{filter[:key]}' for Windows in approval rule. Valid keys: #{WINDOWS_KEYS.join(', ')}"
                end
              end
            end
          end

          def validate_linux_filters(attrs)
            validate_filter_keys(attrs.global_filter, LINUX_KEYS, attrs.operating_system)
          end

          def validate_debian_filters(attrs)
            validate_filter_keys(attrs.global_filter, DEBIAN_KEYS, attrs.operating_system)
          end

          def validate_filter_keys(filters, valid_keys, os_name)
            filters.each do |filter|
              unless valid_keys.include?(filter[:key])
                raise Dry::Struct::Error, "Invalid filter key '#{filter[:key]}' for #{os_name}. Valid keys: #{valid_keys.join(', ')}"
              end
            end
          end

          def validate_approval_rules(attrs)
            attrs.approval_rule.each do |rule|
              validate_approval_method(rule)
              validate_date_format(rule[:approve_until_date]) if rule[:approve_until_date]
            end
          end

          def validate_approval_method(rule)
            if !rule[:approve_after_days] && !rule[:approve_until_date]
              raise Dry::Struct::Error, 'Approval rule must specify either approve_after_days or approve_until_date'
            end
            if rule[:approve_after_days] && rule[:approve_until_date]
              raise Dry::Struct::Error, 'Approval rule cannot specify both approve_after_days and approve_until_date'
            end
          end

          def validate_date_format(date)
            Date.iso8601(date)
          rescue ArgumentError
            raise Dry::Struct::Error, 'approve_until_date must be in ISO 8601 date format (YYYY-MM-DD)'
          end

          def validate_sources(attrs)
            attrs.source.each do |source_config|
              unless source_config[:name].match?(/\A[a-zA-Z0-9_\-\.]{1,50}\z/)
                raise Dry::Struct::Error, 'Source name must be 1-50 characters and contain only letters, numbers, hyphens, underscores, and periods'
              end
            end
          end

          def validate_patches(attrs)
            (attrs.approved_patches + attrs.rejected_patches).each do |patch_id|
              if patch_id.empty? || patch_id.length > 100
                raise Dry::Struct::Error, 'Patch ID must be 1-100 characters long'
              end
            end
          end

          def validate_description(attrs)
            if attrs.description && attrs.description.length > 1024
              raise Dry::Struct::Error, 'Description cannot exceed 1024 characters'
            end
          end
        end
      end
    end
  end
end
