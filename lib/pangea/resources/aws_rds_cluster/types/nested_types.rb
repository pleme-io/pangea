# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        class ServerlessV2Scaling < Dry::Struct
          attribute :min_capacity, Resources::Types::Float.constrained(gteq: 0.5, lteq: 128)
          attribute :max_capacity, Resources::Types::Float.constrained(gteq: 0.5, lteq: 128)

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, "min_capacity (#{attrs.min_capacity}) cannot be greater than max_capacity (#{attrs.max_capacity})" if attrs.min_capacity > attrs.max_capacity
            attrs
          end

          def is_minimal? = min_capacity <= 1.0 && max_capacity <= 2.0
          def is_high_performance? = max_capacity >= 16.0
          def scaling_range = max_capacity - min_capacity
          def estimated_hourly_cost_range = "$#{(min_capacity * 0.12).round(2)}-#{(max_capacity * 0.12).round(2)}/hour"
        end

        class RestoreToPointInTime < Dry::Struct
          attribute :source_cluster_identifier, Resources::Types::String.optional
          attribute :restore_to_time, Resources::Types::String.optional
          attribute :use_latest_restorable_time, Resources::Types::Bool.default(false)
          attribute :restore_type, Resources::Types::String.optional.constrained(included_in: %w[full-copy copy-on-write])

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, "Must specify either 'restore_to_time' or set 'use_latest_restorable_time' to true" if !attrs.use_latest_restorable_time && !attrs.restore_to_time
            raise Dry::Struct::Error, "Cannot specify both 'restore_to_time' and 'use_latest_restorable_time'" if attrs.use_latest_restorable_time && attrs.restore_to_time
            raise Dry::Struct::Error, 'source_cluster_identifier is required for point-in-time restore' unless attrs.source_cluster_identifier
            attrs
          end

          def uses_latest_time? = use_latest_restorable_time
          def uses_specific_time? = !restore_to_time.nil?
        end
      end
    end
  end
end
