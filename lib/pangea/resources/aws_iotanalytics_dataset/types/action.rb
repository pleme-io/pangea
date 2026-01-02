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
  module Resources
    module AwsIotanalyticsDatasetTypes
      # Action configuration for dataset content generation
      class Action < Dry::Struct
        schema schema.strict

        # Name of the action
        attribute :action_name, Resources::Types::String

        # SQL query to execute for data retrieval
        class QueryAction < Dry::Struct
          schema schema.strict

          # SQL query string
          attribute :sql_query, Resources::Types::String

          # Filter configuration for query results
          class Filter < Dry::Struct
            schema schema.strict

            # Delta time filter for incremental processing
            class DeltaTime < Dry::Struct
              schema schema.strict

              # Offset in seconds from current time
              attribute :offset_seconds, Resources::Types::Integer

              # Time expression for filtering
              attribute :time_expression, Resources::Types::String
            end

            attribute? :delta_time, DeltaTime.optional
          end

          attribute :filters, Resources::Types::Array.of(Filter).optional
        end

        attribute? :query_action, QueryAction.optional

        # Container action for custom data processing
        class ContainerAction < Dry::Struct
          schema schema.strict

          # Docker image URI for processing
          attribute :image, Resources::Types::String

          # Execution role ARN
          attribute :execution_role_arn, Resources::Types::String

          # Resource configuration
          class ResourceConfiguration < Dry::Struct
            schema schema.strict

            # Compute type for processing
            attribute :compute_type, Resources::Types::String.enum('ACU_1', 'ACU_2')

            # Volume size in GB
            attribute :volume_size_in_gb, Resources::Types::Integer.constrained(gteq: 1, lteq: 50)
          end

          attribute :resource_configuration, ResourceConfiguration

          # Environment variables for container
          attribute :variables, Resources::Types::Hash.map(Types::String, Types::String).optional
        end

        attribute? :container_action, ContainerAction.optional
      end
    end
  end
end
