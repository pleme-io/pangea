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
      module Types
        # Validators for API Gateway Stage attributes
        module ApiGatewayStageValidators
          VALID_HTTP_METHODS = %w[GET POST PUT DELETE OPTIONS HEAD PATCH ANY *].freeze
          VALID_LOGGING_LEVELS = %w[OFF ERROR INFO].freeze
          RESERVED_STAGE_NAMES = %w[test].freeze

          class << self
            def validate!(attrs)
              validate_stage_name!(attrs[:stage_name])
              validate_cache_settings!(attrs)
              validate_throttling!(attrs)
              validate_access_log_settings!(attrs[:access_log_settings])
              validate_method_settings!(attrs[:method_settings])
              validate_canary_settings!(attrs[:canary_settings])
            end

            private

            def validate_stage_name!(stage_name)
              return unless stage_name

              unless stage_name.match?(/^[a-zA-Z0-9_-]+$/)
                raise Dry::Struct::Error, 'Stage name must contain only alphanumeric characters, underscores, and dashes'
              end

              return unless RESERVED_STAGE_NAMES.include?(stage_name.downcase)

              raise Dry::Struct::Error, "Stage name '#{stage_name}' is reserved"
            end

            def validate_cache_settings!(attrs)
              return unless attrs[:cache_cluster_enabled] && attrs[:cache_cluster_size].nil?

              raise Dry::Struct::Error, 'cache_cluster_size must be specified when cache_cluster_enabled is true'
            end

            def validate_throttling!(attrs)
              if attrs[:throttle_rate_limit]&.negative?
                raise Dry::Struct::Error, 'throttle_rate_limit must be non-negative'
              end

              return unless attrs[:throttle_burst_limit]&.negative?

              raise Dry::Struct::Error, 'throttle_burst_limit must be non-negative'
            end

            def validate_access_log_settings!(settings)
              return unless settings

              raise Dry::Struct::Error, 'access_log_settings must include destination_arn' unless settings.key?(:destination_arn)
              raise Dry::Struct::Error, 'access_log_settings must include format' unless settings.key?(:format)
            end

            def validate_method_settings!(method_settings)
              return unless method_settings

              method_settings.each { |setting| validate_single_method_setting!(setting) }
            end

            def validate_single_method_setting!(setting)
              validate_method_setting_required_fields!(setting)
              validate_method_setting_resource_path!(setting[:resource_path])
              validate_method_setting_http_method!(setting[:http_method])
              validate_method_setting_logging_level!(setting[:logging_level])
              validate_method_setting_cache_ttl!(setting[:cache_ttl_in_seconds])
            end

            def validate_method_setting_required_fields!(setting)
              return if setting.key?(:resource_path) && setting.key?(:http_method)

              raise Dry::Struct::Error, 'Method setting must include resource_path and http_method'
            end

            def validate_method_setting_resource_path!(resource_path)
              return if resource_path.start_with?('/')

              raise Dry::Struct::Error, "Method setting resource_path must start with '/'"
            end

            def validate_method_setting_http_method!(http_method)
              return if VALID_HTTP_METHODS.include?(http_method)

              raise Dry::Struct::Error, "Invalid HTTP method: #{http_method}"
            end

            def validate_method_setting_logging_level!(logging_level)
              return unless logging_level
              return if VALID_LOGGING_LEVELS.include?(logging_level)

              raise Dry::Struct::Error, "Invalid logging level: #{logging_level}"
            end

            def validate_method_setting_cache_ttl!(cache_ttl)
              return unless cache_ttl
              return if cache_ttl >= 0 && cache_ttl <= 3600

              raise Dry::Struct::Error, 'cache_ttl_in_seconds must be between 0 and 3600'
            end

            def validate_canary_settings!(settings)
              return unless settings

              percent = settings[:percent_traffic].to_f
              return if percent >= 0.0 && percent <= 100.0

              raise Dry::Struct::Error, 'Canary traffic percentage must be between 0.0 and 100.0'
            end
          end
        end
      end
    end
  end
end
