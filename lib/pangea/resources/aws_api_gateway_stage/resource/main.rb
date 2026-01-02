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
        # Core resource definition for API Gateway Stage
        module Main
          # Generate the Terraform resource block
          def generate_stage_resource(name, stage_attrs)
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
          end

          # Create ResourceReference with standard outputs
          def create_stage_reference(name, stage_attrs)
            ResourceReference.new(
              type: 'aws_api_gateway_stage',
              name: name,
              resource_attributes: stage_attrs.to_h,
              outputs: {
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
          end
        end
      end
    end
  end
end
