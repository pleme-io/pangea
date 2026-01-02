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

module Pangea
  module Resources
    module AWS
      module ApiGatewayStageResource
        module HelpersModules
          # Configuration helper methods for API Gateway Stage resource reference
          module Configuration
            def add_cache_helpers(ref, stage_attrs)
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
            end

            def add_throttling_helpers(ref, stage_attrs)
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
            end

            def add_logging_helpers(ref, stage_attrs)
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
            end

            def add_canary_helpers(ref, stage_attrs)
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
            end

            def add_security_helpers(ref, stage_attrs)
              ref.define_singleton_method(:security_configuration) do
                {
                  client_certificate: !stage_attrs.client_certificate_id.nil?,
                  xray_tracing: stage_attrs.xray_tracing_enabled,
                  access_logging: stage_attrs.has_access_logging?,
                  cache_encryption: stage_attrs.method_settings.any? { |ms| ms[:cache_data_encrypted] },
                  throttling_protection: stage_attrs.has_throttling?
                }
              end
            end
          end
        end
      end
    end
  end
end
