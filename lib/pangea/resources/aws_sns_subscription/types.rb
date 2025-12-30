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
            validate_json_policies(attrs)
            validate_protocol_requirements(attrs)
            validate_protocol_options(attrs)
            attrs
          end

          def self.validate_json_policies(attrs)
            validate_filter_policy(attrs.filter_policy) if attrs.filter_policy
            validate_redrive_policy(attrs.redrive_policy) if attrs.redrive_policy
            validate_delivery_policy(attrs.delivery_policy) if attrs.delivery_policy
          end

          def self.validate_filter_policy(policy)
            filter_doc = JSON.parse(policy)
            raise Dry::Struct::Error, 'filter_policy must be a JSON object' unless filter_doc.is_a?(Hash)
          rescue JSON::ParserError => e
            raise Dry::Struct::Error, "filter_policy must be valid JSON: #{e.message}"
          end

          def self.validate_redrive_policy(policy)
            redrive_doc = JSON.parse(policy)
            unless redrive_doc.is_a?(Hash) && redrive_doc['deadLetterTargetArn']
              raise Dry::Struct::Error, 'redrive_policy must contain deadLetterTargetArn'
            end
          rescue JSON::ParserError => e
            raise Dry::Struct::Error, "redrive_policy must be valid JSON: #{e.message}"
          end

          def self.validate_delivery_policy(policy)
            JSON.parse(policy)
          rescue JSON::ParserError => e
            raise Dry::Struct::Error, "delivery_policy must be valid JSON: #{e.message}"
          end

          def self.validate_protocol_requirements(attrs)
            case attrs.protocol
            when 'email', 'email-json'
              unless attrs.endpoint.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
                raise Dry::Struct::Error, 'Email protocol requires valid email address'
              end
            when 'sms'
              unless attrs.endpoint.match?(/\A\+?[1-9]\d{1,14}\z/)
                raise Dry::Struct::Error, 'SMS protocol requires valid phone number (E.164 format)'
              end
            when 'http'
              raise Dry::Struct::Error, 'HTTP protocol requires endpoint starting with http://' unless attrs.endpoint.start_with?('http://')
            when 'https'
              raise Dry::Struct::Error, 'HTTPS protocol requires endpoint starting with https://' unless attrs.endpoint.start_with?('https://')
            when 'sqs'
              unless attrs.endpoint.match?(/\Aarn:aws:sqs:[\w-]+:\d{12}:[\w-]+\z/)
                raise Dry::Struct::Error, 'SQS protocol requires valid SQS queue ARN'
              end
            when 'lambda'
              unless attrs.endpoint.match?(/\Aarn:aws:lambda:[\w-]+:\d{12}:function:[\w-]+/)
                raise Dry::Struct::Error, 'Lambda protocol requires valid Lambda function ARN'
              end
            when 'firehose'
              validate_firehose_protocol(attrs)
            end
          end

          def self.validate_firehose_protocol(attrs)
            unless attrs.endpoint.match?(/\Aarn:aws:firehose:[\w-]+:\d{12}:deliverystream\/[\w-]+\z/)
              raise Dry::Struct::Error, 'Firehose protocol requires valid delivery stream ARN'
            end
            raise Dry::Struct::Error, 'Firehose protocol requires subscription_role_arn' unless attrs.subscription_role_arn
          end

          def self.validate_protocol_options(attrs)
            if attrs.raw_message_delivery && !%w[sqs lambda http https firehose].include?(attrs.protocol)
              raise Dry::Struct::Error, 'raw_message_delivery is only valid for sqs, lambda, http, https, and firehose protocols'
            end
            if attrs.filter_policy_scope == 'MessageBody' && !%w[sqs lambda firehose].include?(attrs.protocol)
              raise Dry::Struct::Error, 'MessageBody filter scope is only valid for sqs, lambda, and firehose protocols'
            end
            if attrs.delivery_policy && !%w[http https].include?(attrs.protocol)
              raise Dry::Struct::Error, 'delivery_policy is only valid for http and https protocols'
            end
          end
        end
      end
    end
  end
end
