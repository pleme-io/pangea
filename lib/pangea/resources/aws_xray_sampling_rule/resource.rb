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
      # Type-safe resource function for AWS X-Ray Sampling Rule
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/xray_sampling_rule
      #
      # @example Basic sampling rule for production traffic
      #   aws_xray_sampling_rule(:production_sampling, {
      #     rule_name: "ProductionSampling",
      #     priority: 9000,
      #     fixed_rate: 0.1,
      #     reservoir_size: 1,
      #     service_name: "production-api",
      #     service_type: "AWS::EC2::Instance",
      #     host: "api.mycompany.com",
      #     http_method: "*",
      #     url_path: "/api/*",
      #     version: 1
      #   })
      #
      # @example High-priority error sampling
      #   aws_xray_sampling_rule(:error_sampling, {
      #     rule_name: "HighPriorityErrors",
      #     priority: 1000,
      #     fixed_rate: 1.0,
      #     reservoir_size: 5,
      #     service_name: "*",
      #     service_type: "*",
      #     host: "*",
      #     http_method: "*",
      #     url_path: "*",
      #     version: 1,
      #     attributes: {
      #       "aws.xray.error": "true"
      #     }
      #   })
      def aws_xray_sampling_rule(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          rule_name: {
            description: "Name of the sampling rule",
            type: :string,
            required: true
          },
          priority: {
            description: "Priority of the sampling rule (lower number = higher priority)",
            type: :integer,
            required: true
          },
          fixed_rate: {
            description: "Fixed rate to sample (0.0 to 1.0)",
            type: :float,
            required: true
          },
          reservoir_size: {
            description: "Number of traces per second to sample regardless of fixed rate",
            type: :integer,
            required: true
          },
          service_name: {
            description: "Service name pattern to match",
            type: :string,
            required: true
          },
          service_type: {
            description: "Service type pattern to match",
            type: :string,
            required: true
          },
          host: {
            description: "Host pattern to match",
            type: :string,
            required: true
          },
          http_method: {
            description: "HTTP method pattern to match",
            type: :string,
            required: true
          },
          url_path: {
            description: "URL path pattern to match",
            type: :string,
            required: true
          },
          version: {
            description: "Version of the sampling rule format",
            type: :integer,
            default: 1
          },
          attributes: {
            description: "Additional attributes to match on",
            type: :map
          },
          resource_arn: {
            description: "ARN of the AWS resource associated with the request",
            type: :string
          },
          tags: {
            description: "Resource tags",
            type: :map
          }
        })

        resource_block = resource(:aws_xray_sampling_rule, name, transformed)
        
        Reference.new(
          type: :aws_xray_sampling_rule,
          name: name,
          attributes: {
            arn: "#{resource_block}.arn",
            id: "#{resource_block}.id",
            rule_name: "#{resource_block}.rule_name",
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