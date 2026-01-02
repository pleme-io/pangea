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
      module Lookout
        module Equipment
          # Dataset resource for AWS Lookout for Equipment
          module Dataset
            # Creates an AWS Lookout for Equipment Dataset
            #
            # @param name [Symbol] The unique name for this resource instance
            # @param attributes [Hash] The configuration options for the dataset
            # @option attributes [String] :dataset_name The name of the dataset (required)
            # @option attributes [String] :dataset_schema The JSON schema defining the dataset structure
            # @option attributes [String] :server_side_kms_key_id The KMS key ID for encryption
            # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
            #
            # @example Basic equipment dataset for predictive maintenance
            #   aws_lookoutequipment_dataset(:turbine_sensor_data, {
            #     dataset_name: "wind-turbine-sensor-dataset",
            #     dataset_schema: JSON.pretty_generate({
            #       Components: [
            #         {
            #           ComponentName: "Turbine",
            #           Columns: [
            #             { Name: "timestamp", Type: "DATETIME" },
            #             { Name: "turbine_id", Type: "CATEGORICAL" },
            #             { Name: "rotor_speed", Type: "DOUBLE" },
            #             { Name: "generator_temperature", Type: "DOUBLE" },
            #             { Name: "gearbox_oil_temperature", Type: "DOUBLE" },
            #             { Name: "vibration_x", Type: "DOUBLE" },
            #             { Name: "vibration_y", Type: "DOUBLE" },
            #             { Name: "vibration_z", Type: "DOUBLE" },
            #             { Name: "power_output", Type: "DOUBLE" }
            #           ]
            #         }
            #       ]
            #     }),
            #     tags: {
            #       Equipment: "WindTurbine",
            #       Purpose: "PredictiveMaintenance"
            #     }
            #   })
            #
            # @return [ResourceReference] Reference to the created dataset
            def aws_lookoutequipment_dataset(name, attributes = {})
              resource(:aws_lookoutequipment_dataset, name) do
                dataset_name attributes[:dataset_name] if attributes[:dataset_name]
                dataset_schema attributes[:dataset_schema] if attributes[:dataset_schema]
                server_side_kms_key_id attributes[:server_side_kms_key_id] if attributes[:server_side_kms_key_id]
                tags attributes[:tags] if attributes[:tags]
              end

              ResourceReference.new(
                type: 'aws_lookoutequipment_dataset',
                name: name,
                resource_attributes: attributes,
                outputs: {
                  dataset_name: "${aws_lookoutequipment_dataset.#{name}.dataset_name}",
                  dataset_arn: "${aws_lookoutequipment_dataset.#{name}.dataset_arn}",
                  status: "${aws_lookoutequipment_dataset.#{name}.status}",
                  created_at: "${aws_lookoutequipment_dataset.#{name}.created_at}"
                }
              )
            end
          end
        end
      end
    end
  end
end
