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
    module SustainableMLTraining
      # DynamoDB tables for training state and carbon tracking
      module Tables
        def create_training_state_table(input)
          aws_dynamodb_table(:"#{input.name}-training-state", {
            billing_mode: "PAY_PER_REQUEST",
            hash_key: "job_id",
            range_key: "timestamp",
            attribute: [
              { name: "job_id", type: "S" },
              { name: "timestamp", type: "N" },
              { name: "region", type: "S" },
              { name: "carbon_intensity", type: "N" }
            ],
            global_secondary_index: [{
              name: "region-carbon-index",
              hash_key: "region",
              range_key: "carbon_intensity",
              projection_type: "ALL"
            }],
            stream_specification: {
              stream_enabled: true,
              stream_view_type: "NEW_AND_OLD_IMAGES"
            },
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Purpose" => "training-state"
            )
          })
        end

        def create_carbon_tracking_table(input)
          aws_dynamodb_table(:"#{input.name}-carbon-tracking", {
            billing_mode: "PAY_PER_REQUEST",
            hash_key: "metric_id",
            range_key: "timestamp",
            attribute: [
              { name: "metric_id", type: "S" },
              { name: "timestamp", type: "N" }
            ],
            ttl: {
              enabled: true,
              attribute_name: "expiration"
            },
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Purpose" => "carbon-tracking"
            )
          })
        end
      end
    end
  end
end
