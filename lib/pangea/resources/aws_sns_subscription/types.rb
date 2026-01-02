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

require 'dry-struct'
require 'pangea/resources/types'
require_relative 'types/helpers'
require_relative 'types/validators'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS SNS Subscription resources
        class SNSSubscriptionAttributes < Dry::Struct
          include SNSSubscriptionHelpers
          transform_keys(&:to_sym)

          attribute :topic_arn, Resources::Types::String
          attribute :protocol, Resources::Types::String.enum(
            'email', 'email-json', 'sms', 'sqs', 'lambda', 'http', 'https', 'application', 'firehose'
          )
          attribute :endpoint, Resources::Types::String
          attribute? :filter_policy, Resources::Types::String.optional
          attribute :filter_policy_scope, Resources::Types::String.default('MessageAttributes').enum('MessageAttributes', 'MessageBody')
          attribute :raw_message_delivery, Resources::Types::Bool.default(false)
          attribute? :redrive_policy, Resources::Types::String.optional
          attribute? :subscription_role_arn, Resources::Types::String.optional
          attribute? :delivery_policy, Resources::Types::String.optional
          attribute :endpoint_auto_confirms, Resources::Types::Bool.default(false)
          attribute? :confirmation_timeout_in_minutes, Resources::Types::Integer.constrained(gteq: 1).optional

          def self.new(attributes = {})
            attrs = super(attributes)
            SNSSubscriptionValidators.validate_json_policies(attrs)
            SNSSubscriptionValidators.validate_protocol_requirements(attrs)
            SNSSubscriptionValidators.validate_protocol_options(attrs)
            attrs
          end
        end
      end
    end
  end
end
