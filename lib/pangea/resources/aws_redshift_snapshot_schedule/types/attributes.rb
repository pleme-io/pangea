# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'validation'
require_relative 'instance_methods'
require_relative 'templates'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Redshift Snapshot Schedule resources
        class RedshiftSnapshotScheduleAttributes < Dry::Struct
          extend RedshiftSnapshotScheduleValidation
          extend RedshiftSnapshotScheduleTemplates
          include RedshiftSnapshotScheduleInstanceMethods

          # Schedule identifier (required)
          attribute :identifier, Resources::Types::String

          # Schedule description
          attribute :description, Resources::Types::String.optional

          # Schedule definitions (required)
          # Format: "rate(12 hours)" or "cron(0 12 * * ? *)"
          attribute :definitions, Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1)

          # Force destroy
          attribute :force_destroy, Resources::Types::Bool.default(false)

          # Tags
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            validate_identifier(attrs)
            validate_definitions(attrs)
            attrs
          end
        end
      end
    end
  end
end
