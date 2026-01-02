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
      module Types
        # Module for detecting AWS service type from ARN
        module TargetServiceDetection
          # Service patterns mapped to service symbols
          SERVICE_PATTERNS = {
            /^arn:aws[a-z\-]*:lambda:/ => :lambda,
            /^arn:aws[a-z\-]*:sns:/ => :sns,
            /^arn:aws[a-z\-]*:sqs:/ => :sqs,
            /^arn:aws[a-z\-]*:kinesis:/ => :kinesis,
            /^arn:aws[a-z\-]*:firehose:/ => :firehose,
            /^arn:aws[a-z\-]*:logs:/ => :cloudwatch_logs,
            /^arn:aws[a-z\-]*:events:/ => :event_bus,
            /^arn:aws[a-z\-]*:states:/ => :step_functions,
            /^arn:aws[a-z\-]*:codebuild:/ => :codebuild,
            /^arn:aws[a-z\-]*:codepipeline:/ => :codepipeline,
            /^arn:aws[a-z\-]*:ecs:/ => :ecs,
            /^arn:aws[a-z\-]*:batch:/ => :batch,
            /^arn:aws[a-z\-]*:glue:/ => :glue,
            /^arn:aws[a-z\-]*:redshift:/ => :redshift,
            /^arn:aws[a-z\-]*:sagemaker:/ => :sagemaker
          }.freeze

          # Services that typically require an IAM role
          ROLE_REQUIRED_SERVICES = %i[
            ecs batch kinesis firehose step_functions codebuild codepipeline
          ].freeze

          # Detect target service from ARN
          def target_service
            return :unknown unless arn

            SERVICE_PATTERNS.each do |pattern, service|
              return service if arn.match?(pattern)
            end

            :unknown
          end

          # Check if this target service typically requires a role
          def requires_role?
            ROLE_REQUIRED_SERVICES.include?(target_service)
          end

          # Check if input transformation is configured
          def has_input_transformation?
            !input_transformer.nil?
          end

          # Check if retry policy is configured
          def has_retry_policy?
            !retry_policy.nil?
          end

          # Check if dead letter queue is configured
          def has_dead_letter_queue?
            !dead_letter_config.nil?
          end
        end
      end
    end
  end
end
