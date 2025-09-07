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
        # AWS Lookout for Equipment resources for predictive maintenance
        # These resources manage industrial equipment monitoring and anomaly detection
        # to predict equipment failures and optimize maintenance schedules.
        #
        # @see https://docs.aws.amazon.com/lookout-for-equipment/
        module Equipment
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
            resource = resource(:aws_lookoutequipment_dataset, name) do
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

          # Creates an AWS Lookout for Equipment Model
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the model
          # @option attributes [String] :model_name The name of the model (required)
          # @option attributes [String] :dataset_name The name of the training dataset (required)
          # @option attributes [String] :labels_input_configuration Labels configuration for supervised learning
          # @option attributes [String] :training_data_start_time The start time for training data (required)
          # @option attributes [String] :training_data_end_time The end time for training data (required)
          # @option attributes [String] :evaluation_data_start_time The start time for evaluation data
          # @option attributes [String] :evaluation_data_end_time The end time for evaluation data
          # @option attributes [String] :data_preprocessing_configuration Data preprocessing configuration
          # @option attributes [String] :server_side_kms_key_id The KMS key ID for encryption
          # @option attributes [String] :role_arn The IAM role ARN for the model (required)
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Equipment anomaly detection model
          #   aws_lookoutequipment_model(:turbine_anomaly_model, {
          #     model_name: "wind-turbine-anomaly-detection",
          #     dataset_name: ref(:aws_lookoutequipment_dataset, :turbine_sensor_data, :dataset_name),
          #     role_arn: ref(:aws_iam_role, :lookout_equipment_role, :arn),
          #     training_data_start_time: "2023-01-01T00:00:00.000Z",
          #     training_data_end_time: "2023-06-30T23:59:59.000Z",
          #     evaluation_data_start_time: "2023-07-01T00:00:00.000Z",
          #     evaluation_data_end_time: "2023-08-31T23:59:59.000Z",
          #     tags: {
          #       ModelType: "AnomalyDetection",
          #       Equipment: "WindTurbine",
          #       Version: "1.0"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created model
          def aws_lookoutequipment_model(name, attributes = {})
            resource = resource(:aws_lookoutequipment_model, name) do
              model_name attributes[:model_name] if attributes[:model_name]
              dataset_name attributes[:dataset_name] if attributes[:dataset_name]
              labels_input_configuration attributes[:labels_input_configuration] if attributes[:labels_input_configuration]
              training_data_start_time attributes[:training_data_start_time] if attributes[:training_data_start_time]
              training_data_end_time attributes[:training_data_end_time] if attributes[:training_data_end_time]
              evaluation_data_start_time attributes[:evaluation_data_start_time] if attributes[:evaluation_data_start_time]
              evaluation_data_end_time attributes[:evaluation_data_end_time] if attributes[:evaluation_data_end_time]
              data_preprocessing_configuration attributes[:data_preprocessing_configuration] if attributes[:data_preprocessing_configuration]
              server_side_kms_key_id attributes[:server_side_kms_key_id] if attributes[:server_side_kms_key_id]
              role_arn attributes[:role_arn] if attributes[:role_arn]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_lookoutequipment_model',
              name: name,
              resource_attributes: attributes,
              outputs: {
                model_name: "${aws_lookoutequipment_model.#{name}.model_name}",
                model_arn: "${aws_lookoutequipment_model.#{name}.model_arn}",
                status: "${aws_lookoutequipment_model.#{name}.status}",
                created_at: "${aws_lookoutequipment_model.#{name}.created_at}",
                training_execution_start_time: "${aws_lookoutequipment_model.#{name}.training_execution_start_time}",
                training_execution_end_time: "${aws_lookoutequipment_model.#{name}.training_execution_end_time}"
              }
            )
          end

          # Creates an AWS Lookout for Equipment Inference Scheduler
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the inference scheduler
          # @option attributes [String] :inference_scheduler_name The name of the inference scheduler (required)
          # @option attributes [String] :model_name The name of the model to use (required)
          # @option attributes [Hash] :data_input_configuration Input data configuration (required)
          #   - :s3_input_configuration [Hash] S3 input configuration
          #     - :bucket [String] The S3 bucket name
          #     - :prefix [String] The S3 prefix
          # @option attributes [Hash] :data_output_configuration Output data configuration (required)
          #   - :s3_output_configuration [Hash] S3 output configuration
          #     - :bucket [String] The S3 bucket name
          #     - :prefix [String] The S3 prefix
          #     - :kms_key_id [String] KMS key for encryption
          # @option attributes [String] :data_upload_frequency How often data is uploaded ("PT5M", "PT10M", "PT15M", "PT30M", "PT1H")
          # @option attributes [String] :data_delay_offset_in_minutes Delay offset in minutes
          # @option attributes [String] :role_arn The IAM role ARN for the scheduler (required)
          # @option attributes [String] :server_side_kms_key_id The KMS key ID for encryption
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Real-time equipment monitoring scheduler
          #   aws_lookoutequipment_inference_scheduler(:turbine_monitoring_scheduler, {
          #     inference_scheduler_name: "wind-turbine-real-time-monitoring",
          #     model_name: ref(:aws_lookoutequipment_model, :turbine_anomaly_model, :model_name),
          #     role_arn: ref(:aws_iam_role, :lookout_inference_role, :arn),
          #     data_upload_frequency: "PT15M",
          #     data_delay_offset_in_minutes: "5",
          #     data_input_configuration: {
          #       s3_input_configuration: {
          #         bucket: "equipment-sensor-data",
          #         prefix: "turbine-realtime/"
          #       }
          #     },
          #     data_output_configuration: {
          #       s3_output_configuration: {
          #         bucket: "equipment-inference-results",
          #         prefix: "turbine-anomalies/",
          #         kms_key_id: ref(:aws_kms_key, :equipment_encryption, :arn)
          #       }
          #     },
          #     tags: {
          #       Equipment: "WindTurbine",
          #       MonitoringType: "RealTime",
          #       Frequency: "15Minutes"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created inference scheduler
          def aws_lookoutequipment_inference_scheduler(name, attributes = {})
            resource = resource(:aws_lookoutequipment_inference_scheduler, name) do
              inference_scheduler_name attributes[:inference_scheduler_name] if attributes[:inference_scheduler_name]
              model_name attributes[:model_name] if attributes[:model_name]
              data_input_configuration attributes[:data_input_configuration] if attributes[:data_input_configuration]
              data_output_configuration attributes[:data_output_configuration] if attributes[:data_output_configuration]
              data_upload_frequency attributes[:data_upload_frequency] if attributes[:data_upload_frequency]
              data_delay_offset_in_minutes attributes[:data_delay_offset_in_minutes] if attributes[:data_delay_offset_in_minutes]
              role_arn attributes[:role_arn] if attributes[:role_arn]
              server_side_kms_key_id attributes[:server_side_kms_key_id] if attributes[:server_side_kms_key_id]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_lookoutequipment_inference_scheduler',
              name: name,
              resource_attributes: attributes,
              outputs: {
                inference_scheduler_name: "${aws_lookoutequipment_inference_scheduler.#{name}.inference_scheduler_name}",
                inference_scheduler_arn: "${aws_lookoutequipment_inference_scheduler.#{name}.inference_scheduler_arn}",
                status: "${aws_lookoutequipment_inference_scheduler.#{name}.status}",
                created_at: "${aws_lookoutequipment_inference_scheduler.#{name}.created_at}",
                updated_at: "${aws_lookoutequipment_inference_scheduler.#{name}.updated_at}"
              }
            )
          end
        end
      end
    end
  end
end