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

require 'dry-struct'
require 'pangea/resources/types'

require_relative 'types/service_config'
require_relative 'types/observability_configs'
require_relative 'types/operational_configs'
require_relative 'types/dashboard_widget'

module Pangea
  module Components
    module ServiceMeshObservability
      # Main component attributes
      class ServiceMeshObservabilityAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Core configuration
        attribute :mesh_name, Types::String
        attribute :mesh_description, Types::String.default("Service mesh observability stack")

        # Services to monitor
        attribute :services, Types::Array.of(ServiceConfig).constrained(min_size: 1)

        # X-Ray configuration
        attribute :xray_enabled, Types::Bool.default(true)
        attribute :xray_encryption_config, Types::Hash.default({ type: "KMS" }.freeze)
        attribute :xray_insights_enabled, Types::Bool.default(true)

        # Distributed tracing
        attribute :tracing, TracingConfig.default { TracingConfig.new({}) }

        # Metrics collection
        attribute :metrics, MetricsConfig.default { MetricsConfig.new({}) }

        # Service map
        attribute :service_map, ServiceMapConfig.default { ServiceMapConfig.new({}) }

        # Alerting
        attribute :alerting, AlertingConfig.default { AlertingConfig.new({}) }

        # Log aggregation
        attribute :log_aggregation, LogAggregationConfig.default { LogAggregationConfig.new({}) }

        # Dashboard configuration
        attribute :dashboard_widgets, Types::Array.of(DashboardWidget).default([].freeze)
        attribute :dashboard_name, Types::String.optional
        attribute :dashboard_refresh_interval, Types::Integer.default(300)

        # Container Insights
        attribute :container_insights_enabled, Types::Bool.default(true)

        # Enhanced monitoring
        attribute :enhanced_monitoring_enabled, Types::Bool.default(true)
        attribute :anomaly_detection_enabled, Types::Bool.default(false)

        # Cost tracking
        attribute :cost_tracking_enabled, Types::Bool.default(true)
        attribute :cost_allocation_tags, Types::Hash.default({}.freeze)

        # Tags
        attribute :tags, Types::Hash.default({}.freeze)

        # Custom validations
        def validate!
          errors = []

          # Validate services
          service_names = services.map(&:name)
          if service_names.uniq.length != service_names.length
            errors << "Service names must be unique"
          end

          # Validate tracing configuration
          if tracing.enabled && (tracing.sampling_rate < 0 || tracing.sampling_rate > 1)
            errors << "Tracing sampling rate must be between 0 and 1"
          end

          # Validate metrics configuration
          if metrics.enabled
            if metrics.collection_interval < 10 || metrics.collection_interval > 3600
              errors << "Metrics collection interval must be between 10 and 3600 seconds"
            end

            if metrics.prometheus_enabled && (metrics.prometheus_port < 1024 || metrics.prometheus_port > 65535)
              errors << "Prometheus port must be between 1024 and 65535"
            end
          end

          # Validate alerting thresholds
          if alerting.enabled
            if alerting.error_rate_threshold < 0 || alerting.error_rate_threshold > 1
              errors << "Error rate threshold must be between 0 and 1"
            end

            if alerting.availability_threshold < 0 || alerting.availability_threshold > 1
              errors << "Availability threshold must be between 0 and 1"
            end

            errors << "Latency threshold must be at least 1ms" if alerting.latency_threshold_ms < 1
          end

          # Validate log retention
          if log_aggregation.enabled && (log_aggregation.retention_days < 1 || log_aggregation.retention_days > 3653)
            errors << "Log retention must be between 1 and 3653 days"
          end

          # Validate dashboard widgets
          dashboard_widgets.each do |widget|
            errors << "Dashboard widget width must be between 1 and 24" if widget.width < 1 || widget.width > 24
            errors << "Dashboard widget height must be between 1 and 1000" if widget.height < 1 || widget.height > 1000
          end

          # Validate that services have required references
          services.each do |service|
            unless service.task_definition_ref || service.deployment_ref
              errors << "Service #{service.name} must have either task_definition_ref or deployment_ref"
            end
          end

          raise ArgumentError, errors.join(", ") unless errors.empty?

          true
        end
      end
    end
  end
end
