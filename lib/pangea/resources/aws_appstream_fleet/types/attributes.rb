# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # AppStream Fleet resource attributes with validation
        class AppstreamFleetAttributes < Dry::Struct
          include AppstreamFleetCostEstimation

          transform_keys(&:to_sym)

          # Required attributes
          attribute :name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 100,
            format: /\A[a-zA-Z0-9][a-zA-Z0-9_-]*\z/
          )

          attribute :compute_capacity, ComputeCapacityType
          attribute :instance_type, Resources::Types::String.constrained(
            format: /\Astream\.[a-z0-9]+\.[a-z0-9]+\z/
          )

          # Optional attributes
          attribute :description, Resources::Types::String.constrained(max_size: 256).optional
          attribute :display_name, Resources::Types::String.constrained(max_size: 100).optional
          attribute :vpc_config, VpcConfigType.optional
          attribute :domain_join_info, DomainJoinInfoType.optional
          attribute :fleet_type, Resources::Types::String.default('ON_DEMAND').enum('ALWAYS_ON', 'ON_DEMAND')
          attribute :enable_default_internet_access, Resources::Types::Bool.default(true)
          attribute :image_name, Resources::Types::String.optional
          attribute :image_arn, Resources::Types::String.optional
          attribute :idle_disconnect_timeout_in_seconds, Resources::Types::Integer.constrained(
            gteq: 0, lteq: 3600
          ).default(0)
          attribute :disconnect_timeout_in_seconds, Resources::Types::Integer.constrained(
            gteq: 60, lteq: 360_000
          ).default(900)
          attribute :max_user_duration_in_seconds, Resources::Types::Integer.constrained(
            gteq: 600, lteq: 360_000
          ).default(57_600) # 16 hours
          attribute :stream_view, Resources::Types::String.default('APP').enum('APP', 'DESKTOP')
          attribute :tags, Resources::Types::AwsTags

          # Validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Must specify either image_name or image_arn
            unless attrs[:image_name] || attrs[:image_arn]
              raise Dry::Struct::Error, 'Either image_name or image_arn must be specified'
            end

            if attrs[:image_name] && attrs[:image_arn]
              raise Dry::Struct::Error, 'Cannot specify both image_name and image_arn'
            end

            super(attrs)
          end

          # Computed properties
          def always_on?
            fleet_type == 'ALWAYS_ON'
          end

          def on_demand?
            fleet_type == 'ON_DEMAND'
          end

          def max_concurrent_sessions
            compute_capacity.desired_instances
          end
        end
      end
    end
  end
end
