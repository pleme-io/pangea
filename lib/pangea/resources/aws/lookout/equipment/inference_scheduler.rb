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
          # Inference Scheduler resource for AWS Lookout for Equipment
          module InferenceScheduler
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
            # @option attributes [String] :data_upload_frequency Upload frequency ("PT5M", "PT10M", "PT15M", "PT30M", "PT1H")
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
              resource(:aws_lookoutequipment_inference_scheduler, name) do
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
end
