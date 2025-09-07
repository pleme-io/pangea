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
require 'pangea/resources/aws_cloudwatch_log_stream/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudWatch Log Stream with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudWatch Log Stream attributes
      # @option attributes [String] :name The name of the log stream
      # @option attributes [String] :log_group_name The name of the log group
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Basic log stream
      #   log_stream = aws_cloudwatch_log_stream(:app_stream, {
      #     name: "application-instance-001",
      #     log_group_name: log_group.name
      #   })
      #
      # @example Lambda log stream
      #   lambda_stream = aws_cloudwatch_log_stream(:lambda_stream, {
      #     name: "2023/12/01/[$LATEST]abcd1234567890",
      #     log_group_name: "/aws/lambda/my-function"
      #   })
      #
      # @example ECS task log stream
      #   ecs_stream = aws_cloudwatch_log_stream(:ecs_task_stream, {
      #     name: "ecs/web-service/task-id-12345",
      #     log_group_name: "/ecs/web-service"
      #   })
      #
      # @example Application log stream with timestamp
      #   app_stream = aws_cloudwatch_log_stream(:timestamped_stream, {
      #     name: "server-01/#{Time.now.strftime('%Y/%m/%d')}/session-#{SecureRandom.hex(4)}",
      #     log_group_name: "/application/web-servers"
      #   })
      def aws_cloudwatch_log_stream(name, attributes = {})
        # Validate attributes using dry-struct
        log_stream_attrs = Types::Types::CloudWatchLogStreamAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudwatch_log_stream, name) do
          name log_stream_attrs.name
          log_group_name log_stream_attrs.log_group_name
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudwatch_log_stream',
          name: name,
          resource_attributes: log_stream_attrs.to_h,
          outputs: {
            arn: "${aws_cloudwatch_log_stream.#{name}.arn}",
            name: "${aws_cloudwatch_log_stream.#{name}.name}",
            log_group_name: "${aws_cloudwatch_log_stream.#{name}.log_group_name}"
          },
          computed_properties: {
            is_lambda_stream: log_stream_attrs.is_lambda_stream?,
            is_ecs_stream: log_stream_attrs.is_ecs_stream?,
            is_application_stream: log_stream_attrs.is_application_stream?,
            stream_type: log_stream_attrs.stream_type,
            log_group_hierarchy: log_stream_attrs.log_group_hierarchy
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)