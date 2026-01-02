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
      module CloudFrontDistribution
        # Builds origin configuration blocks for CloudFront distributions
        module OriginBuilder
          module_function

          def build_origins(context, origins)
            origins.each { |origin_config| build_origin(context, origin_config) }
          end

          def build_origin(context, origin_config)
            context.origin do
              domain_name origin_config[:domain_name]
              origin_id origin_config[:origin_id]
              origin_path origin_config[:origin_path] if origin_config[:origin_path]
              connection_attempts origin_config[:connection_attempts] if origin_config[:connection_attempts]
              connection_timeout origin_config[:connection_timeout] if origin_config[:connection_timeout]

              build_s3_origin_config(self, origin_config[:s3_origin_config]) if origin_config[:s3_origin_config]
              build_custom_origin_config(self, origin_config[:custom_origin_config]) if origin_config[:custom_origin_config]
              build_origin_shield(self, origin_config[:origin_shield]) if origin_config[:origin_shield]
              build_custom_headers(self, origin_config[:custom_header])
            end
          end

          def build_s3_origin_config(context, s3_config)
            context.s3_origin_config do
              origin_access_identity s3_config[:origin_access_identity] if s3_config[:origin_access_identity]
              origin_access_control_id s3_config[:origin_access_control_id] if s3_config[:origin_access_control_id]
            end
          end

          def build_custom_origin_config(context, custom_config)
            context.custom_origin_config do
              http_port custom_config[:http_port]
              https_port custom_config[:https_port]
              origin_protocol_policy custom_config[:origin_protocol_policy]
              origin_ssl_protocols custom_config[:origin_ssl_protocols] if custom_config[:origin_ssl_protocols]
              origin_keepalive_timeout custom_config[:origin_keepalive_timeout] if custom_config[:origin_keepalive_timeout]
              origin_read_timeout custom_config[:origin_read_timeout] if custom_config[:origin_read_timeout]
            end
          end

          def build_origin_shield(context, shield_config)
            context.origin_shield do
              enabled shield_config[:enabled]
              origin_shield_region shield_config[:origin_shield_region] if shield_config[:origin_shield_region]
            end
          end

          def build_custom_headers(context, headers)
            headers.each do |header|
              context.custom_header do
                name header[:name]
                value header[:value]
              end
            end
          end
        end
      end
    end
  end
end
