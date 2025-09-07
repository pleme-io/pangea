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
      # Type-safe resource function for AWS CloudWatch Query Definition
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_query_definition
      #
      # @example Error analysis query definition
      #   aws_cloudwatch_query_definition(:error_analysis, {
      #     name: "Application Error Analysis",
      #     query_string: <<~QUERY
      #       fields @timestamp, @message
      #       | filter @message like /ERROR/
      #       | stats count() by bin(5m)
      #       | sort @timestamp desc
      #     QUERY,
      #     log_group_names: [
      #       "/aws/lambda/my-function",
      #       "/aws/apigateway/my-api"
      #     ]
      #   })
      #
      # @example Performance monitoring query
      #   aws_cloudwatch_query_definition(:performance_monitor, {
      #     name: "Request Latency Analysis",
      #     query_string: <<~QUERY
      #       fields @timestamp, @requestId, @duration
      #       | filter @type = "REPORT"
      #       | stats avg(@duration), max(@duration), min(@duration) by bin(5m)
      #     QUERY,
      #     log_group_names: ["/aws/lambda/api-handler"]
      #   })
      def aws_cloudwatch_query_definition(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          name: {
            description: "Name of the query definition",
            type: :string,
            required: true
          },
          query_string: {
            description: "CloudWatch Logs Insights query string",
            type: :string,
            required: true
          },
          log_group_names: {
            description: "List of log group names to query",
            type: :array
          }
        })

        resource_block = resource(:aws_cloudwatch_query_definition, name, transformed)
        
        Reference.new(
          type: :aws_cloudwatch_query_definition,
          name: name,
          attributes: {
            arn: "#{resource_block}.arn",
            id: "#{resource_block}.id",
            name: "#{resource_block}.name",
            query_definition_id: "#{resource_block}.query_definition_id"
          },
          resource: resource_block
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)