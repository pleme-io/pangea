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
      # Type-safe resource function for AWS CloudWatch Insight Rule
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_insight_rule
      #
      # @example Application performance insight rule
      #   aws_cloudwatch_insight_rule(:app_performance, {
      #     name: "ApplicationPerformanceInsights",
      #     rule_definition: jsonencode({
      #       "Rules": [
      #         {
      #           "RuleName": "ApplicationLatency",
      #           "RuleState": "ENABLED",
      #           "Schema": "AWS/ApplicationELB",
      #           "Fields": {
      #             "TargetResponseTime": "TargetResponseTime"
      #           }
      #         }
      #       ]
      #     }),
      #     rule_state: "ENABLED"
      #   })
      #
      # @example Custom metric insight rule
      #   aws_cloudwatch_insight_rule(:custom_insights, {
      #     name: "CustomMetricInsights",
      #     rule_definition: rule_definition_ref.json,
      #     rule_state: "ENABLED",
      #     tags: {
      #       Environment: "production",
      #       Team: "platform"
      #     }
      #   })
      def aws_cloudwatch_insight_rule(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          name: {
            description: "Name of the insight rule",
            type: :string,
            required: true
          },
          rule_definition: {
            description: "JSON definition of the insight rule",
            type: :string,
            required: true
          },
          rule_state: {
            description: "State of the insight rule (ENABLED or DISABLED)",
            type: :string,
            default: "ENABLED"
          },
          tags: {
            description: "Resource tags",
            type: :map
          }
        })

        resource_block = resource(:aws_cloudwatch_insight_rule, name, transformed)
        
        Reference.new(
          type: :aws_cloudwatch_insight_rule,
          name: name,
          attributes: {
            arn: "#{resource_block}.arn",
            id: "#{resource_block}.id",
            name: "#{resource_block}.name",
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