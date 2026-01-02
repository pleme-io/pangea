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
  module Components
    module CarbonAwareCompute
      # DynamoDB table resources for Carbon Aware Compute
      module Tables
        def create_workload_table(input)
          aws_dynamodb_table(:"#{input.name}-workloads", {
            billing_mode: "PAY_PER_REQUEST",
            hash_key: "workload_id",
            range_key: "scheduled_time",
            attribute: workload_table_attributes,
            global_secondary_index: [workload_gsi],
            ttl: ttl_config("expiration_time"),
            tags: table_tags(input, "workload-queue")
          })
        end

        def create_carbon_data_table(input)
          aws_dynamodb_table(:"#{input.name}-carbon-data", {
            billing_mode: "PAY_PER_REQUEST",
            hash_key: "region",
            range_key: "timestamp",
            attribute: carbon_table_attributes,
            ttl: ttl_config("expiration"),
            tags: table_tags(input, "carbon-intensity-cache")
          })
        end

        private

        def workload_table_attributes
          [
            { name: "workload_id", type: "S" },
            { name: "scheduled_time", type: "N" },
            { name: "region", type: "S" },
            { name: "status", type: "S" }
          ]
        end

        def workload_gsi
          {
            name: "region-status-index",
            hash_key: "region",
            range_key: "status",
            projection_type: "ALL"
          }
        end

        def carbon_table_attributes
          [
            { name: "region", type: "S" },
            { name: "timestamp", type: "N" }
          ]
        end

        def ttl_config(attribute_name)
          {
            enabled: true,
            attribute_name: attribute_name
          }
        end
      end
    end
  end
end
