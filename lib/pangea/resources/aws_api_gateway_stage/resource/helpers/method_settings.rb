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
          # Method settings and optimization helper methods
          module MethodSettings
            def add_method_settings_helpers(ref, name, stage_attrs)
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

              ref.define_singleton_method(:stage_url) do
                "\${aws_api_gateway_stage.#{name}.invoke_url}"
              end

              ref.define_singleton_method(:common_log_formats) do
                Types::Types::ApiGatewayStageAttributes.common_log_formats
              end

              ref.define_singleton_method(:common_method_paths) do
                Types::Types::ApiGatewayStageAttributes.common_method_paths
              end
            end

            def add_optimization_helpers(ref, stage_attrs)
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
            end
          end
        end
      end
    end
  end
end
