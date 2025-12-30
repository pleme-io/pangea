# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'validation'
require_relative 'instance_methods'

module Pangea
  module Resources
    module AWS
      module Types
        class SsmPatchBaselineAttributes < Dry::Struct
          extend SsmPatchBaselineValidation
          include SsmPatchBaselineInstanceMethods

          attribute :name, Resources::Types::String
          attribute :operating_system, Resources::Types::String.enum(
            'WINDOWS', 'AMAZON_LINUX', 'AMAZON_LINUX_2', 'UBUNTU', 'REDHAT_ENTERPRISE_LINUX', 'SUSE', 'CENTOS',
            'ORACLE_LINUX', 'DEBIAN', 'MACOS', 'RASPBIAN', 'ROCKY_LINUX', 'ALMA_LINUX'
          )
          attribute :description, Resources::Types::String.optional
          attribute :approved_patches, Resources::Types::Array.of(Types::String).default([].freeze)
          attribute :rejected_patches, Resources::Types::Array.of(Types::String).default([].freeze)
          attribute :approved_patches_compliance_level, Resources::Types::String.enum(
            'CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'INFORMATIONAL', 'UNSPECIFIED'
          ).default('UNSPECIFIED')
          attribute :approved_patches_enable_non_security, Resources::Types::Bool.default(false)
          attribute :rejected_patches_action, Resources::Types::String.enum('ALLOW_AS_DEPENDENCY', 'BLOCK').default('ALLOW_AS_DEPENDENCY')

          attribute :global_filter, Resources::Types::Array.of(
            Types::Hash.schema(
              key: Types::String.enum('PATCH_SET', 'PRODUCT', 'PRODUCT_FAMILY', 'CLASSIFICATION', 'MSRC_SEVERITY', 'PATCH_ID',
                                      'SECTION', 'PRIORITY', 'REPOSITORY', 'SEVERITY', 'ARCH', 'EPOCH', 'RELEASE', 'VERSION',
                                      'NAME', 'BUGZILLA_ID', 'CVE_ID', 'ADVISORY_ID'),
              values: Types::Array.of(Types::String).constrained(min_size: 1)
            )
          ).default([].freeze)

          attribute :approval_rule, Resources::Types::Array.of(
            Types::Hash.schema(
              approve_after_days?: Types::Integer.optional.constrained(gteq: 0, lteq: 360),
              approve_until_date?: Types::String.optional,
              compliance_level?: Types::String.enum('CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'INFORMATIONAL', 'UNSPECIFIED').optional,
              enable_non_security?: Types::Bool.optional,
              patch_filter: Types::Array.of(
                Types::Hash.schema(
                  key: Types::String.enum('PATCH_SET', 'PRODUCT', 'PRODUCT_FAMILY', 'CLASSIFICATION', 'MSRC_SEVERITY', 'PATCH_ID',
                                          'SECTION', 'PRIORITY', 'REPOSITORY', 'SEVERITY', 'ARCH', 'EPOCH', 'RELEASE', 'VERSION',
                                          'NAME', 'BUGZILLA_ID', 'CVE_ID', 'ADVISORY_ID'),
                  values: Types::Array.of(Types::String).constrained(min_size: 1)
                )
              ).constrained(min_size: 1)
            )
          ).default([].freeze)

          attribute :source, Resources::Types::Array.of(
            Types::Hash.schema(name: Types::String, products: Types::Array.of(Types::String).constrained(min_size: 1), configuration: Types::String)
          ).default([].freeze)

          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            validate_os_filters(attrs)
            validate_approval_rules(attrs)
            validate_sources(attrs)
            validate_patches(attrs)
            validate_description(attrs)
            attrs
          end
        end
      end
    end
  end
end
