# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require_relative 'types'

module Pangea
  module Resources
    module AWS
      # AWS API Gateway Stage implementation
      # Provides type-safe function for creating API stages
      def aws_api_gateway_stage(name, attributes = {})
        # Validate attributes using dry-struct
        stage_attrs = Types::Types::ApiGatewayStageAttributes.new(attributes)
        
        # Generate the Terraform resource
        resource :aws_api_gateway_stage, name do
          # Core configuration
          rest_api_id stage_attrs.rest_api_id
          deployment_id stage_attrs.deployment_id
          stage_name stage_attrs.stage_name
          
          # Stage configuration
          description stage_attrs.description if stage_attrs.description
          documentation_version stage_attrs.documentation_version if stage_attrs.documentation_version
          
          # Caching
          cache_cluster_enabled stage_attrs.cache_cluster_enabled
          cache_cluster_size stage_attrs.cache_cluster_size if stage_attrs.cache_cluster_size
          
          # Variables
          variables stage_attrs.variables unless stage_attrs.variables.empty?
          
          # Monitoring
          xray_tracing_enabled stage_attrs.xray_tracing_enabled
          
          # Access logging
          if stage_attrs.access_log_settings
            access_log_settings do
              destination_arn stage_attrs.access_log_settings[:destination_arn]
              format stage_attrs.access_log_settings[:format]
            end
          end
          
          # Throttling
          throttle_burst_limit stage_attrs.throttle_burst_limit if stage_attrs.throttle_burst_limit
          throttle_rate_limit stage_attrs.throttle_rate_limit if stage_attrs.throttle_rate_limit
          
          # Method settings
          unless stage_attrs.method_settings.empty?
            stage_attrs.method_settings.each do |method_setting|
              method_settings do
                resource_path method_setting[:resource_path]
                http_method method_setting[:http_method]
                metrics_enabled method_setting[:metrics_enabled] if method_setting.key?(:metrics_enabled)
                logging_level method_setting[:logging_level] if method_setting[:logging_level]
                data_trace_enabled method_setting[:data_trace_enabled] if method_setting.key?(:data_trace_enabled)
                throttling_burst_limit method_setting[:throttling_burst_limit] if method_setting[:throttling_burst_limit]
                throttling_rate_limit method_setting[:throttling_rate_limit] if method_setting[:throttling_rate_limit]
                caching_enabled method_setting[:caching_enabled] if method_setting.key?(:caching_enabled)
                cache_ttl_in_seconds method_setting[:cache_ttl_in_seconds] if method_setting[:cache_ttl_in_seconds]
                cache_data_encrypted method_setting[:cache_data_encrypted] if method_setting.key?(:cache_data_encrypted)
                require_authorization_for_cache_control method_setting[:require_authorization_for_cache_control] if method_setting.key?(:require_authorization_for_cache_control)
              end
            end
          end
          
          # Canary settings
          if stage_attrs.canary_settings
            canary_settings do
              percent_traffic stage_attrs.canary_settings[:percent_traffic]
              deployment_id stage_attrs.canary_settings[:deployment_id] if stage_attrs.canary_settings[:deployment_id]
              stage_variable_overrides stage_attrs.canary_settings[:stage_variable_overrides] if stage_attrs.canary_settings[:stage_variable_overrides]
              use_stage_cache stage_attrs.canary_settings[:use_stage_cache] if stage_attrs.canary_settings.key?(:use_stage_cache)
            end
          end
          
          # Client certificate
          client_certificate_id stage_attrs.client_certificate_id if stage_attrs.client_certificate_id
          
          # Tags
          tags stage_attrs.tags unless stage_attrs.tags.empty?
        end
        
        # Create ResourceReference with outputs and computed properties
        ref = ResourceReference.new(
          type: 'aws_api_gateway_stage',
          name: name,
          resource_attributes: stage_attrs.to_h,
          outputs: {
            # Standard Terraform outputs
            id: "${aws_api_gateway_stage.#{name}.id}",
            rest_api_id: "${aws_api_gateway_stage.#{name}.rest_api_id}",
            stage_name: "${aws_api_gateway_stage.#{name}.stage_name}",
            deployment_id: "${aws_api_gateway_stage.#{name}.deployment_id}",
            arn: "${aws_api_gateway_stage.#{name}.arn}",
            invoke_url: "${aws_api_gateway_stage.#{name}.invoke_url}",
            execution_arn: "${aws_api_gateway_stage.#{name}.execution_arn}",
            description: "${aws_api_gateway_stage.#{name}.description}",
            documentation_version: "${aws_api_gateway_stage.#{name}.documentation_version}",
            cache_cluster_enabled: "${aws_api_gateway_stage.#{name}.cache_cluster_enabled}",
            cache_cluster_size: "${aws_api_gateway_stage.#{name}.cache_cluster_size}",
            variables: "${aws_api_gateway_stage.#{name}.variables}",
            xray_tracing_enabled: "${aws_api_gateway_stage.#{name}.xray_tracing_enabled}",
            access_log_settings: "${aws_api_gateway_stage.#{name}.access_log_settings}",
            throttle_burst_limit: "${aws_api_gateway_stage.#{name}.throttle_burst_limit}",
            throttle_rate_limit: "${aws_api_gateway_stage.#{name}.throttle_rate_limit}",
            client_certificate_id: "${aws_api_gateway_stage.#{name}.client_certificate_id}",
            tags: "${aws_api_gateway_stage.#{name}.tags}",
            tags_all: "${aws_api_gateway_stage.#{name}.tags_all}",
            web_acl_arn: "${aws_api_gateway_stage.#{name}.web_acl_arn}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:has_caching?) { stage_attrs.has_caching? }
        ref.define_singleton_method(:has_access_logging?) { stage_attrs.has_access_logging? }
        ref.define_singleton_method(:has_canary?) { stage_attrs.has_canary? }
        ref.define_singleton_method(:has_throttling?) { stage_attrs.has_throttling? }
        ref.define_singleton_method(:has_method_settings?) { stage_attrs.has_method_settings? }
        ref.define_singleton_method(:estimated_monthly_cost) { stage_attrs.estimated_monthly_cost }
        
        # Stage configuration analysis
        ref.define_singleton_method(:stage_type) do
          if stage_attrs.stage_name.match?(/^(prod|production)$/i)
            "production"
          elsif stage_attrs.stage_name.match?(/^(dev|development)$/i)
            "development"
          elsif stage_attrs.stage_name.match?(/^(stag|staging)$/i)
            "staging"
          else
            "custom"
          end
        end
        
        ref.define_singleton_method(:is_production_stage?) do
          stage_attrs.stage_name.match?(/^(prod|production)$/i)
        end
        
        ref.define_singleton_method(:is_development_stage?) do
          stage_attrs.stage_name.match?(/^(dev|development)$/i)
        end
        
        ref.define_singleton_method(:is_staging_stage?) do
          stage_attrs.stage_name.match?(/^(stag|staging)$/i)
        end
        
        # Cache configuration helpers
        ref.define_singleton_method(:cache_configuration) do
          if stage_attrs.has_caching?
            {
              enabled: true,
              cluster_size: stage_attrs.cache_cluster_size,
              estimated_cost: stage_attrs.estimated_monthly_cost,
              methods_with_caching: stage_attrs.method_settings.select { |ms| ms[:caching_enabled] }.map { |ms| "#{ms[:http_method]} #{ms[:resource_path]}" }
            }
          else
            { enabled: false }
          end
        end
        
        # Throttling configuration helpers
        ref.define_singleton_method(:throttling_configuration) do
          config = {
            stage_level: stage_attrs.has_throttling?,
            method_level: stage_attrs.method_settings.any? { |ms| ms[:throttling_burst_limit] || ms[:throttling_rate_limit] }
          }
          
          if stage_attrs.has_throttling?
            config[:stage_limits] = {
              burst_limit: stage_attrs.throttle_burst_limit,
              rate_limit: stage_attrs.throttle_rate_limit
            }
          end
          
          method_throttling = stage_attrs.method_settings.select { |ms| ms[:throttling_burst_limit] || ms[:throttling_rate_limit] }
          if method_throttling.any?
            config[:method_limits] = method_throttling.map do |ms|
              {
                path: "#{ms[:http_method]} #{ms[:resource_path]}",
                burst_limit: ms[:throttling_burst_limit],
                rate_limit: ms[:throttling_rate_limit]
              }
            end
          end
          
          config
        end
        
        # Access logging configuration helpers
        ref.define_singleton_method(:logging_configuration) do
          config = { enabled: stage_attrs.has_access_logging? }
          
          if stage_attrs.has_access_logging?
            config[:access_logs] = stage_attrs.access_log_settings
            
            # Check if format is JSON
            format_str = stage_attrs.access_log_settings[:format]
            config[:format_type] = format_str&.start_with?('{') ? 'json' : 'text'
          end
          
          # Method-level logging
          method_logging = stage_attrs.method_settings.select { |ms| ms[:logging_level] && ms[:logging_level] != 'OFF' }
          if method_logging.any?
            config[:method_logging] = method_logging.map do |ms|
              {
                path: "#{ms[:http_method]} #{ms[:resource_path]}",
                level: ms[:logging_level],
                data_trace: ms[:data_trace_enabled]
              }
            end
          end
          
          config[:xray_tracing] = stage_attrs.xray_tracing_enabled
          config
        end
        
        # Canary deployment helpers
        ref.define_singleton_method(:canary_configuration) do
          if stage_attrs.has_canary?
            {
              enabled: true,
              percent_traffic: stage_attrs.canary_settings[:percent_traffic],
              deployment_id: stage_attrs.canary_settings[:deployment_id],
              variable_overrides: stage_attrs.canary_settings[:stage_variable_overrides] || {},
              use_stage_cache: stage_attrs.canary_settings[:use_stage_cache]
            }
          else
            { enabled: false }
          end
        end
        
        ref.define_singleton_method(:canary_percentage) do
          stage_attrs.has_canary? ? stage_attrs.canary_settings[:percent_traffic] : 0.0
        end
        
        # Variable analysis
        ref.define_singleton_method(:variable_count) { stage_attrs.variables.size }
        
        ref.define_singleton_method(:has_stage_variables?) { !stage_attrs.variables.empty? }
        
        # Method settings analysis
        ref.define_singleton_method(:method_settings_count) { stage_attrs.method_settings.size }
        
        ref.define_singleton_method(:methods_with_special_settings) do
          stage_attrs.method_settings.map do |ms|
            settings = []
            settings << 'caching' if ms[:caching_enabled]
            settings << 'throttling' if ms[:throttling_burst_limit] || ms[:throttling_rate_limit]
            settings << 'logging' if ms[:logging_level] && ms[:logging_level] != 'OFF'
            settings << 'metrics' if ms[:metrics_enabled]
            
            {
              path: "#{ms[:http_method]} #{ms[:resource_path]}",
              settings: settings
            }
          end
        end
        
        # Stage URL generation
        ref.define_singleton_method(:stage_url) do
          "\${aws_api_gateway_stage.#{name}.invoke_url}"
        end
        
        # Security analysis
        ref.define_singleton_method(:security_configuration) do
          {
            client_certificate: !stage_attrs.client_certificate_id.nil?,
            xray_tracing: stage_attrs.xray_tracing_enabled,
            access_logging: stage_attrs.has_access_logging?,
            cache_encryption: stage_attrs.method_settings.any? { |ms| ms[:cache_data_encrypted] },
            throttling_protection: stage_attrs.has_throttling?
          }
        end
        
        # Performance optimization recommendations
        ref.define_singleton_method(:optimization_recommendations) do
          recommendations = []
          
          # Caching recommendations
          if !stage_attrs.has_caching? && ref.is_production_stage?
            recommendations << "Consider enabling caching for production workloads"
          elsif stage_attrs.has_caching? && stage_attrs.cache_cluster_size == '0.5'
            recommendations << "Consider larger cache size for better performance"
          end
          
          # Throttling recommendations
          if !stage_attrs.has_throttling?
            recommendations << "Consider adding throttling limits to protect backend services"
          end
          
          # Monitoring recommendations
          if !stage_attrs.xray_tracing_enabled && ref.is_production_stage?
            recommendations << "Enable X-Ray tracing for production observability"
          end
          
          # Logging recommendations
          if !stage_attrs.has_access_logging?
            recommendations << "Enable access logging for monitoring and debugging"
          end
          
          recommendations
        end
        
        # Helper methods for common log formats and method paths
        ref.define_singleton_method(:common_log_formats) do
          Types::ApiGatewayStageAttributes.common_log_formats
        end
        
        ref.define_singleton_method(:common_method_paths) do
          Types::ApiGatewayStageAttributes.common_method_paths
        end
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)