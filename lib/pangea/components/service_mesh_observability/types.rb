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

module Pangea
  module Components
    module ServiceMeshObservability
      # Service configuration for observability
      class ServiceConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :name, Types::String
        attribute :namespace, Types::String.default("default")
        attribute :cluster_ref, Types::ResourceReference
        attribute :task_definition_ref, Types::ResourceReference.optional
        attribute :deployment_ref, Types::ResourceReference.optional
        attribute :port, Types::Integer.default(80)
        attribute :protocol, Types::String.enum('HTTP', 'GRPC', 'TCP').default('HTTP')
        attribute :health_check_path, Types::String.default("/health")
      end
      
      # Distributed tracing configuration
      class TracingConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :sampling_rate, Types::Float.default(0.1)
        attribute :trace_id_header, Types::String.default("X-Trace-Id")
        attribute :span_header, Types::String.default("X-Span-Id")
        attribute :parent_span_header, Types::String.default("X-Parent-Span-Id")
        attribute :baggage_header, Types::String.default("X-Trace-Baggage")
      end
      
      # Metrics collection configuration
      class MetricsConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :collection_interval, Types::Integer.default(60)
        attribute :detailed_metrics, Types::Bool.default(true)
        attribute :custom_metrics, Types::Array.of(Types::Hash).default([].freeze)
        attribute :prometheus_enabled, Types::Bool.default(false)
        attribute :prometheus_port, Types::Integer.default(9090)
      end
      
      # Service map visualization configuration
      class ServiceMapConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :update_interval, Types::Integer.default(300)
        attribute :include_external_services, Types::Bool.default(true)
        attribute :group_by_namespace, Types::Bool.default(true)
      end
      
      # Alerting configuration
      class AlertingConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :notification_channel_ref, Types::ResourceReference.optional
        attribute :latency_threshold_ms, Types::Integer.default(1000)
        attribute :error_rate_threshold, Types::Float.default(0.05)
        attribute :availability_threshold, Types::Float.default(0.99)
        attribute :circuit_breaker_threshold, Types::Integer.default(5)
      end
      
      # Log aggregation configuration
      class LogAggregationConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :retention_days, Types::Integer.default(30)
        attribute :log_groups, Types::Array.of(Types::String).default([].freeze)
        attribute :filter_patterns, Types::Array.of(Types::Hash).default([].freeze)
        attribute :insights_queries, Types::Array.of(Types::Hash).default([].freeze)
      end
      
      # Dashboard widget configuration
      class DashboardWidget < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :type, Types::String.enum('metric', 'log', 'alarm', 'text')
        attribute :title, Types::String
        attribute :metrics, Types::Array.of(Types::Hash).default([].freeze)
        attribute :width, Types::Integer.default(12)
        attribute :height, Types::Integer.default(6)
        attribute :properties, Types::Hash.default({}.freeze)
      end
      
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
          if tracing.enabled
            if tracing.sampling_rate < 0 || tracing.sampling_rate > 1
              errors << "Tracing sampling rate must be between 0 and 1"
            end
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
            
            if alerting.latency_threshold_ms < 1
              errors << "Latency threshold must be at least 1ms"
            end
          end
          
          # Validate log retention
          if log_aggregation.enabled
            if log_aggregation.retention_days < 1 || log_aggregation.retention_days > 3653
              errors << "Log retention must be between 1 and 3653 days"
            end
          end
          
          # Validate dashboard widgets
          dashboard_widgets.each do |widget|
            if widget.width < 1 || widget.width > 24
              errors << "Dashboard widget width must be between 1 and 24"
            end
            
            if widget.height < 1 || widget.height > 1000
              errors << "Dashboard widget height must be between 1 and 1000"
            end
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