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


require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      # Type-safe resource function for AWS CloudWatch Anomaly Detector
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_anomaly_detector
      #
      # @example EC2 CPU anomaly detector
      #   aws_cloudwatch_anomaly_detector(:ec2_cpu_anomaly, {
      #     metric_name: "CPUUtilization",
      #     namespace: "AWS/EC2",
      #     stat: "Average",
      #     dimensions: {
      #       InstanceId: ec2_instance.id
      #     }
      #   })
      #
      # @example RDS connection anomaly detector with exclusion
      #   aws_cloudwatch_anomaly_detector(:rds_connections, {
      #     metric_name: "DatabaseConnections",
      #     namespace: "AWS/RDS",
      #     stat: "Average",
      #     dimensions: {
      #       DBInstanceIdentifier: rds_instance.id
      #     },
      #     anomaly_detector_exclusion_times: [{
      #       start_time: "2024-01-01T00:00:00Z",
      #       end_time: "2024-01-01T06:00:00Z"
      #     }]
      #   })
      def aws_cloudwatch_anomaly_detector(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          metric_name: {
            description: "Name of the metric to detect anomalies for",
            type: :string,
            required: true
          },
          namespace: {
            description: "Namespace of the metric",
            type: :string,
            required: true
          },
          stat: {
            description: "Statistic to use for anomaly detection",
            type: :string,
            required: true
          },
          dimensions: {
            description: "Dimensions for the metric",
            type: :map
          },
          anomaly_detector_exclusion_times: {
            description: "List of time ranges to exclude from training",
            type: :array
          },
          tags: {
            description: "Resource tags",
            type: :map
          }
        })

        resource_block = resource(:aws_cloudwatch_anomaly_detector, name, transformed)
        
        Reference.new(
          type: :aws_cloudwatch_anomaly_detector,
          name: name,
          attributes: {
            arn: "#{resource_block}.arn",
            id: "#{resource_block}.id",
            tags_all: "#{resource_block}.tags_all"
          },
          resource: resource_block
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)