# frozen_string_literal: true

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