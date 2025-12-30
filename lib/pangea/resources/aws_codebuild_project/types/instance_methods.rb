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
        class CodeBuildProjectAttributes
          # Helper instance methods for CodeBuild Project attributes
          module InstanceMethods
            def uses_vpc?
              vpc_config.present?
            end

            def has_secondary_sources?
              secondary_sources.any?
            end

            def has_secondary_artifacts?
              secondary_artifacts.any?
            end

            def cache_enabled?
              cache[:type] != 'NO_CACHE'
            end

            def cloudwatch_logs_enabled?
              logs_config.dig(:cloudwatch_logs, :status) == 'ENABLED'
            end

            def s3_logs_enabled?
              logs_config.dig(:s3_logs, :status) == 'ENABLED'
            end

            def environment_variable_count
              environment[:environment_variables]&.size || 0
            end

            def uses_secrets?
              return false unless environment[:environment_variables]

              environment[:environment_variables].any? do |var|
                var[:type] == 'PARAMETER_STORE' || var[:type] == 'SECRETS_MANAGER'
              end
            end

            def compute_size
              case environment[:compute_type]
              when 'BUILD_GENERAL1_SMALL' then 'Small (3 GB memory, 2 vCPUs)'
              when 'BUILD_GENERAL1_MEDIUM' then 'Medium (7 GB memory, 4 vCPUs)'
              when 'BUILD_GENERAL1_LARGE' then 'Large (15 GB memory, 8 vCPUs)'
              when 'BUILD_GENERAL1_2XLARGE' then '2X Large (145 GB memory, 72 vCPUs)'
              else environment[:compute_type]
              end
            end
          end
        end
      end
    end
  end
end
