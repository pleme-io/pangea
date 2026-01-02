# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Event selector for CloudTrail data events
        class EventSelector < Dry::Struct
          attribute :read_write_type, Resources::Types::String.optional.constrained(included_in: %w[ReadOnly WriteOnly All])
          attribute :include_management_events, Resources::Types::Bool.default(true)
          attribute :data_resource, Resources::Types::Array.of(
            Types::Hash.schema(type: Types::String, values: Types::Array.of(Types::String))
          ).default([].freeze)

          def includes_s3_data_events?
            data_resource.any? { |resource| resource[:type] == 'AWS::S3::Object' }
          end

          def includes_lambda_data_events?
            data_resource.any? { |resource| resource[:type] == 'AWS::Lambda::Function' }
          end

          def tracked_resource_types
            data_resource.map { |resource| resource[:type] }.uniq
          end
        end

        # Insight selector for CloudTrail Insights
        class InsightSelector < Dry::Struct
          attribute :insight_type, Resources::Types::String.constrained(included_in: %w[ApiCallRateInsight ApiErrorRateInsight])

          def is_api_call_rate_insight? = insight_type == 'ApiCallRateInsight'
          def is_api_error_rate_insight? = insight_type == 'ApiErrorRateInsight'
        end
      end
    end
  end
end
