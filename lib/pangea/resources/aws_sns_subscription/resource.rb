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
require 'pangea/resources/aws_sns_subscription/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS SNS Subscription with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] SNS subscription attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_sns_subscription(name, attributes = {})
        # Validate attributes using dry-struct
        subscription_attrs = Types::SNSSubscriptionAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_sns_subscription, name) do
          topic_arn subscription_attrs.topic_arn
          protocol subscription_attrs.protocol
          endpoint subscription_attrs.endpoint
          
          # Set raw message delivery if not default
          if subscription_attrs.raw_message_delivery
            raw_message_delivery subscription_attrs.raw_message_delivery
          end
          
          # Set filter policy if provided
          if subscription_attrs.filter_policy
            filter_policy subscription_attrs.filter_policy
            filter_policy_scope subscription_attrs.filter_policy_scope
          end
          
          # Set redrive policy if provided
          redrive_policy subscription_attrs.redrive_policy if subscription_attrs.redrive_policy
          
          # Set subscription role ARN if provided (required for Firehose)
          subscription_role_arn subscription_attrs.subscription_role_arn if subscription_attrs.subscription_role_arn
          
          # Set delivery policy if provided (HTTP/S only)
          delivery_policy subscription_attrs.delivery_policy if subscription_attrs.delivery_policy
          
          # Set auto-confirmation if true
          endpoint_auto_confirms subscription_attrs.endpoint_auto_confirms if subscription_attrs.endpoint_auto_confirms
          
          # Set confirmation timeout if provided
          confirmation_timeout_in_minutes subscription_attrs.confirmation_timeout_in_minutes if subscription_attrs.confirmation_timeout_in_minutes
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_sns_subscription',
          name: name,
          resource_attributes: subscription_attrs.to_h,
          outputs: {
            id: "${aws_sns_subscription.#{name}.id}",
            arn: "${aws_sns_subscription.#{name}.arn}",
            topic_arn: subscription_attrs.topic_arn,
            protocol: subscription_attrs.protocol,
            endpoint: subscription_attrs.endpoint,
            owner_id: "${aws_sns_subscription.#{name}.owner_id}",
            confirmation_was_authenticated: "${aws_sns_subscription.#{name}.confirmation_was_authenticated}",
            pending_confirmation: "${aws_sns_subscription.#{name}.pending_confirmation}"
          },
          computed: {
            requires_confirmation: subscription_attrs.requires_confirmation?,
            supports_filter_policy: subscription_attrs.supports_filter_policy?,
            supports_raw_delivery: subscription_attrs.supports_raw_delivery?,
            supports_dlq: subscription_attrs.supports_dlq?,
            is_email_subscription: subscription_attrs.is_email_subscription?,
            is_webhook_subscription: subscription_attrs.is_webhook_subscription?,
            filter_policy_attributes: subscription_attrs.filter_policy_attributes,
            has_numeric_filters: subscription_attrs.has_numeric_filters?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)