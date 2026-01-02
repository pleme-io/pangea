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
    module AwsIotanalyticsDataset
      module Builders
        # Builds action configuration hashes for IoT Analytics datasets
        module ActionBuilder
          extend self

          # Build action configurations from validated action structs
          # @param actions [Array] Array of action structs
          # @return [Array<Hash>] Array of action configuration hashes
          def build(actions)
            actions.map { |action| build_action(action) }
          end

          private

          def build_action(action)
            config = { 'actionName' => action.action_name }
            config['queryAction'] = build_query_action(action.query_action) if action.query_action
            config['containerAction'] = build_container_action(action.container_action) if action.container_action
            config
          end

          def build_query_action(query_action)
            config = { 'sqlQuery' => query_action.sql_query }
            config['filters'] = build_filters(query_action.filters) if query_action.filters
            config
          end

          def build_filters(filters)
            filters.map do |filter|
              filter_config = {}
              if filter.delta_time
                filter_config['deltaTime'] = {
                  'offsetSeconds' => filter.delta_time.offset_seconds,
                  'timeExpression' => filter.delta_time.time_expression
                }
              end
              filter_config
            end
          end

          def build_container_action(container_action)
            config = {
              'image' => container_action.image,
              'executionRoleArn' => container_action.execution_role_arn,
              'resourceConfiguration' => {
                'computeType' => container_action.resource_configuration.compute_type,
                'volumeSizeInGB' => container_action.resource_configuration.volume_size_in_gb
              }
            }
            config['variables'] = container_action.variables if container_action.variables
            config
          end
        end
      end
    end
  end
end
