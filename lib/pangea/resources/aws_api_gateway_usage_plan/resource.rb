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
require 'pangea/resources/aws_api_gateway_usage_plan/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS API Gateway Usage Plan with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] API Gateway usage plan attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_api_gateway_usage_plan(name, attributes = {})
        # Validate attributes using dry-struct
        usage_plan_attrs = Types::ApiGatewayUsagePlanAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_api_gateway_usage_plan, name) do
          name usage_plan_attrs.name
          description usage_plan_attrs.description if usage_plan_attrs.description
          
          # Configure API stages
          usage_plan_attrs.api_stages.each do |stage_config|
            api_stages do
              api_id stage_config[:api_id]
              stage stage_config[:stage]
              
              # Add per-stage throttling if specified
              if stage_config[:throttle]
                throttle do
                  path stage_config[:throttle][:path] if stage_config[:throttle][:path]
                  burst_limit stage_config[:throttle][:burst_limit] if stage_config[:throttle][:burst_limit]
                  rate_limit stage_config[:throttle][:rate_limit] if stage_config[:throttle][:rate_limit]
                end
              end
            end
          end
          
          # Configure global throttle settings
          if usage_plan_attrs.throttle_settings
            throttle_settings do
              burst_limit usage_plan_attrs.throttle_settings[:burst_limit] if usage_plan_attrs.throttle_settings[:burst_limit]
              rate_limit usage_plan_attrs.throttle_settings[:rate_limit] if usage_plan_attrs.throttle_settings[:rate_limit]
            end
          end
          
          # Configure quota settings
          if usage_plan_attrs.quota_settings
            quota_settings do
              limit usage_plan_attrs.quota_settings[:limit]
              offset usage_plan_attrs.quota_settings[:offset] if usage_plan_attrs.quota_settings[:offset]
              period usage_plan_attrs.quota_settings[:period]
            end
          end
          
          # Set product code if specified
          product_code usage_plan_attrs.product_code if usage_plan_attrs.product_code
          
          # Apply tags if present
          if usage_plan_attrs.tags.any?
            tags do
              usage_plan_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_api_gateway_usage_plan',
          name: name,
          resource_attributes: usage_plan_attrs.to_h,
          outputs: {
            id: "${aws_api_gateway_usage_plan.#{name}.id}",
            arn: "${aws_api_gateway_usage_plan.#{name}.arn}",
            name: "${aws_api_gateway_usage_plan.#{name}.name}",
            description: "${aws_api_gateway_usage_plan.#{name}.description}",
            api_stages: "${aws_api_gateway_usage_plan.#{name}.api_stages}",
            throttle_settings: "${aws_api_gateway_usage_plan.#{name}.throttle_settings}",
            quota_settings: "${aws_api_gateway_usage_plan.#{name}.quota_settings}",
            product_code: "${aws_api_gateway_usage_plan.#{name}.product_code}",
            tags_all: "${aws_api_gateway_usage_plan.#{name}.tags_all}"
          },
          computed_properties: {
            api_count: usage_plan_attrs.api_count,
            has_throttling: usage_plan_attrs.has_throttling?,
            has_quota: usage_plan_attrs.has_quota?,
            quota_period: usage_plan_attrs.quota_period,
            daily_quota: usage_plan_attrs.daily_quota?,
            monthly_quota: usage_plan_attrs.monthly_quota?,
            strictness_level: usage_plan_attrs.strictness_level,
            production_ready: usage_plan_attrs.production_ready?,
            protection_level: usage_plan_attrs.protection_level,
            configuration_warnings: usage_plan_attrs.validate_configuration,
            estimated_monthly_cost: usage_plan_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)