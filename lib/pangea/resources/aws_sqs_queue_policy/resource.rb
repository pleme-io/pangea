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
require 'pangea/resources/aws_sqs_queue_policy/types'
require 'pangea/resource_registry'
require 'json'

module Pangea
  module Resources
    module AWS
      # Create an AWS SQS Queue Policy with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] SQS queue policy attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_sqs_queue_policy(name, attributes = {})
        # Validate attributes using dry-struct
        policy_attrs = Types::SQSQueuePolicyAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_sqs_queue_policy, name) do
          queue_url policy_attrs.queue_url
          policy policy_attrs.policy
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_sqs_queue_policy',
          name: name,
          resource_attributes: policy_attrs.to_h,
          outputs: {
            id: "${aws_sqs_queue_policy.#{name}.id}",
            queue_url: policy_attrs.queue_url
          },
          computed: {
            statement_count: policy_attrs.statement_count,
            allows_cross_account: policy_attrs.allows_cross_account?,
            allows_public_access: policy_attrs.allows_public_access?,
            allowed_actions: policy_attrs.allowed_actions,
            denied_actions: policy_attrs.denied_actions
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)