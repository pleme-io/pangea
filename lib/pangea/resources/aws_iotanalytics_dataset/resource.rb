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


require_relative 'types'
require_relative 'builders/action_builder'
require 'pangea/resources/base'

module Pangea
  module Resources
    # AWS IoT Analytics Dataset Resource
    # 
    # Datasets enable SQL-based analysis of IoT data stored in datastores. They support
    # scheduled content generation, custom processing containers, and automatic delivery
    # to analytics tools and data lakes.
    #
    # @example SQL-based dataset with scheduled generation
    #   aws_iotanalytics_dataset(:sensor_analytics, {
    #     dataset_name: "sensor_temperature_analysis",
    #     actions: [{
    #       action_name: "temperature_query",
    #       query_action: {
    #         sql_query: "SELECT deviceId, AVG(temperature) as avg_temp, MAX(temperature) as max_temp FROM sensor_datastore WHERE __dt >= current_date - interval '7' day GROUP BY deviceId"
    #       }
    #     }],
    #     triggers: [{
    #       schedule: {
    #         schedule_expression: "cron(0 12 * * ? *)"
    #       }
    #     }],
    #     content_delivery_rules: [{
    #       entry_name: "temperature_report",
    #       destination: {
    #         s3_destination_configuration: {
    #           bucket: "analytics-reports",
    #           key: "temperature/year=!{iotanalytics:scheduleTime/yyyy}/month=!{iotanalytics:scheduleTime/MM}/day=!{iotanalytics:scheduleTime/dd}/temperature_report.csv",
    #           role_arn: s3_delivery_role.arn
    #         }
    #       }
    #     }]
    #   })
    #
    # @example Dataset with container action for ML processing
    #   aws_iotanalytics_dataset(:ml_predictions, {
    #     dataset_name: "device_predictions",
    #     actions: [{
    #       action_name: "ml_inference",
    #       container_action: {
    #         image: "123456789012.dkr.ecr.us-east-1.amazonaws.com/iot-ml-processor:latest",
    #         execution_role_arn: ml_execution_role.arn,
    #         resource_configuration: {
    #           compute_type: "ACU_2",
    #           volume_size_in_gb: 20
    #         },
    #         variables: {
    #           "MODEL_ENDPOINT" => sagemaker_endpoint,
    #           "OUTPUT_FORMAT" => "json"
    #         }
    #       }
    #     }]
    #   })
    module AwsIotanalyticsDataset
      include AwsIotanalyticsDatasetTypes

      # Creates an AWS IoT Analytics dataset for data analysis and content generation
      #
      # @param name [Symbol] Logical name for the dataset resource
      # @param attributes [Hash] Dataset configuration attributes
      # @return [Reference] Resource reference for use in other resources
      def aws_iotanalytics_dataset(name, attributes = {})
        validated_attributes = Attributes[attributes]
        
        resource :aws_iotanalytics_dataset, name do
          dataset_name validated_attributes.dataset_name

          # Configure actions
          actions Builders::ActionBuilder.build(validated_attributes.actions)

          # Configure content delivery rules
          if validated_attributes.content_delivery_rules
            content_delivery_rules validated_attributes.content_delivery_rules.map do |rule|
              rule_config = {
                "entryName" => rule.entry_name,
                "destination" => {}
              }
              
              if rule.destination.s3_destination_configuration
                s3_config = {
                  "bucket" => rule.destination.s3_destination_configuration.bucket,
                  "key" => rule.destination.s3_destination_configuration.key,
                  "roleArn" => rule.destination.s3_destination_configuration.role_arn
                }
                
                if rule.destination.s3_destination_configuration.glue_configuration
                  s3_config["glueConfiguration"] = {
                    "tableName" => rule.destination.s3_destination_configuration.glue_configuration.table_name,
                    "databaseName" => rule.destination.s3_destination_configuration.glue_configuration.database_name
                  }
                end
                
                rule_config["destination"]["s3DestinationConfiguration"] = s3_config
              end
              
              rule_config
            end
          end

          # Configure triggers
          if validated_attributes.triggers
            triggers validated_attributes.triggers.map do |trigger|
              trigger_config = {}
              
              if trigger.schedule
                trigger_config["schedule"] = {
                  "scheduleExpression" => trigger.schedule.schedule_expression
                }
              end
              
              if trigger.triggering_dataset
                trigger_config["triggeringDataset"] = {
                  "name" => trigger.triggering_dataset.name
                }
              end
              
              trigger_config
            end
          end

          # Configure retention period
          if validated_attributes.retention_period
            retention_period do
              unlimited validated_attributes.retention_period.unlimited if validated_attributes.retention_period.unlimited
              number_of_days validated_attributes.retention_period.number_of_days if validated_attributes.retention_period.number_of_days
            end
          end

          # Configure versioning
          if validated_attributes.versioning_configuration
            versioning_configuration do
              unlimited validated_attributes.versioning_configuration.unlimited if validated_attributes.versioning_configuration.unlimited
              max_versions validated_attributes.versioning_configuration.max_versions if validated_attributes.versioning_configuration.max_versions
            end
          end

          tags validated_attributes.tags if validated_attributes.tags
        end

        Reference.new(
          type: :aws_iotanalytics_dataset,
          name: name,
          attributes: Outputs.new(
            arn: "${aws_iotanalytics_dataset.#{name}.arn}",
            name: "${aws_iotanalytics_dataset.#{name}.name}"
          )
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)