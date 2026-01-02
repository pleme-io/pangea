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

require 'json'

module Pangea
  module Resources
    module AWS
      module Types
        # Validation methods for SNS Subscription attributes
        module SNSSubscriptionValidators
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
              validate_email_endpoint(attrs.endpoint)
            when 'sms'
              validate_sms_endpoint(attrs.endpoint)
            when 'http'
              validate_http_endpoint(attrs.endpoint)
            when 'https'
              validate_https_endpoint(attrs.endpoint)
            when 'sqs'
              validate_sqs_endpoint(attrs.endpoint)
            when 'lambda'
              validate_lambda_endpoint(attrs.endpoint)
            when 'firehose'
              validate_firehose_protocol(attrs)
            end
          end

          def self.validate_email_endpoint(endpoint)
            return if endpoint.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)

            raise Dry::Struct::Error, 'Email protocol requires valid email address'
          end

          def self.validate_sms_endpoint(endpoint)
            return if endpoint.match?(/\A\+?[1-9]\d{1,14}\z/)

            raise Dry::Struct::Error, 'SMS protocol requires valid phone number (E.164 format)'
          end

          def self.validate_http_endpoint(endpoint)
            return if endpoint.start_with?('http://')

            raise Dry::Struct::Error, 'HTTP protocol requires endpoint starting with http://'
          end

          def self.validate_https_endpoint(endpoint)
            return if endpoint.start_with?('https://')

            raise Dry::Struct::Error, 'HTTPS protocol requires endpoint starting with https://'
          end

          def self.validate_sqs_endpoint(endpoint)
            return if endpoint.match?(/\Aarn:aws:sqs:[\w-]+:\d{12}:[\w-]+\z/)

            raise Dry::Struct::Error, 'SQS protocol requires valid SQS queue ARN'
          end

          def self.validate_lambda_endpoint(endpoint)
            return if endpoint.match?(/\Aarn:aws:lambda:[\w-]+:\d{12}:function:[\w-]+/)

            raise Dry::Struct::Error, 'Lambda protocol requires valid Lambda function ARN'
          end

          def self.validate_firehose_protocol(attrs)
            unless attrs.endpoint.match?(/\Aarn:aws:firehose:[\w-]+:\d{12}:deliverystream\/[\w-]+\z/)
              raise Dry::Struct::Error, 'Firehose protocol requires valid delivery stream ARN'
            end
            raise Dry::Struct::Error, 'Firehose protocol requires subscription_role_arn' unless attrs.subscription_role_arn
          end

          def self.validate_protocol_options(attrs)
            validate_raw_message_delivery(attrs)
            validate_filter_policy_scope(attrs)
            validate_delivery_policy_protocol(attrs)
          end

          def self.validate_raw_message_delivery(attrs)
            return unless attrs.raw_message_delivery
            return if %w[sqs lambda http https firehose].include?(attrs.protocol)

            raise Dry::Struct::Error, 'raw_message_delivery is only valid for sqs, lambda, http, https, and firehose protocols'
          end

          def self.validate_filter_policy_scope(attrs)
            return unless attrs.filter_policy_scope == 'MessageBody'
            return if %w[sqs lambda firehose].include?(attrs.protocol)

            raise Dry::Struct::Error, 'MessageBody filter scope is only valid for sqs, lambda, and firehose protocols'
          end

          def self.validate_delivery_policy_protocol(attrs)
            return unless attrs.delivery_policy
            return if %w[http https].include?(attrs.protocol)

            raise Dry::Struct::Error, 'delivery_policy is only valid for http and https protocols'
          end
        end
      end
    end
  end
end
