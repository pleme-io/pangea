# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS SNS Subscription resources
      class SNSSubscriptionAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Topic ARN to subscribe to
        attribute :topic_arn, Resources::Types::String

        # Protocol for receiving notifications
        attribute :protocol, Resources::Types::String.enum(
          'email',          # Email notifications
          'email-json',     # Email with JSON format
          'sms',           # SMS text messages
          'sqs',           # SQS queue
          'lambda',        # Lambda function
          'http',          # HTTP endpoint
          'https',         # HTTPS endpoint
          'application',   # Mobile app endpoint
          'firehose'       # Kinesis Data Firehose
        )

        # Endpoint to receive notifications
        attribute :endpoint, Resources::Types::String

        # Subscription filter policy (JSON string)
        attribute? :filter_policy, Resources::Types::String.optional

        # Filter policy scope - MessageAttributes (default) or MessageBody
        attribute :filter_policy_scope, Resources::Types::String.default('MessageAttributes').enum('MessageAttributes', 'MessageBody')

        # Raw message delivery (no JSON wrapper)
        attribute :raw_message_delivery, Resources::Types::Bool.default(false)

        # Redrive policy for DLQ (JSON string)
        attribute? :redrive_policy, Resources::Types::String.optional

        # Subscription role ARN (for Kinesis Data Firehose)
        attribute? :subscription_role_arn, Resources::Types::String.optional

        # Delivery policy (JSON string) - for HTTP/S endpoints
        attribute? :delivery_policy, Resources::Types::String.optional

        # Endpoint auto-confirms subscription
        attribute :endpoint_auto_confirms, Resources::Types::Bool.default(false)

        # Confirmation timeout in seconds
        attribute? :confirmation_timeout_in_minutes, Resources::Types::Integer.constrained(gteq: 1).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate filter policy is valid JSON if provided
          if attrs.filter_policy
            begin
              filter_doc = JSON.parse(attrs.filter_policy)
              
              # Basic validation - should be a hash
              unless filter_doc.is_a?(Hash)
                raise Dry::Struct::Error, "filter_policy must be a JSON object"
              end
            rescue JSON::ParserError => e
              raise Dry::Struct::Error, "filter_policy must be valid JSON: #{e.message}"
            end
          end

          # Validate redrive policy is valid JSON if provided
          if attrs.redrive_policy
            begin
              redrive_doc = JSON.parse(attrs.redrive_policy)
              unless redrive_doc.is_a?(Hash) && redrive_doc['deadLetterTargetArn']
                raise Dry::Struct::Error, "redrive_policy must contain deadLetterTargetArn"
              end
            rescue JSON::ParserError => e
              raise Dry::Struct::Error, "redrive_policy must be valid JSON: #{e.message}"
            end
          end

          # Validate delivery policy is valid JSON if provided
          if attrs.delivery_policy
            begin
              JSON.parse(attrs.delivery_policy)
            rescue JSON::ParserError => e
              raise Dry::Struct::Error, "delivery_policy must be valid JSON: #{e.message}"
            end
          end

          # Protocol-specific validations
          case attrs.protocol
          when 'email', 'email-json'
            unless attrs.endpoint.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
              raise Dry::Struct::Error, "Email protocol requires valid email address"
            end
          when 'sms'
            unless attrs.endpoint.match?(/\A\+?[1-9]\d{1,14}\z/)
              raise Dry::Struct::Error, "SMS protocol requires valid phone number (E.164 format)"
            end
          when 'http'
            unless attrs.endpoint.start_with?('http://')
              raise Dry::Struct::Error, "HTTP protocol requires endpoint starting with http://"
            end
          when 'https'
            unless attrs.endpoint.start_with?('https://')
              raise Dry::Struct::Error, "HTTPS protocol requires endpoint starting with https://"
            end
          when 'sqs'
            unless attrs.endpoint.match?(/\Aarn:aws:sqs:[\w-]+:\d{12}:[\w-]+\z/)
              raise Dry::Struct::Error, "SQS protocol requires valid SQS queue ARN"
            end
          when 'lambda'
            unless attrs.endpoint.match?(/\Aarn:aws:lambda:[\w-]+:\d{12}:function:[\w-]+/)
              raise Dry::Struct::Error, "Lambda protocol requires valid Lambda function ARN"
            end
          when 'firehose'
            unless attrs.endpoint.match?(/\Aarn:aws:firehose:[\w-]+:\d{12}:deliverystream\/[\w-]+\z/)
              raise Dry::Struct::Error, "Firehose protocol requires valid delivery stream ARN"
            end
            unless attrs.subscription_role_arn
              raise Dry::Struct::Error, "Firehose protocol requires subscription_role_arn"
            end
          end

          # Raw message delivery validations
          if attrs.raw_message_delivery
            unless %w[sqs lambda http https firehose].include?(attrs.protocol)
              raise Dry::Struct::Error, "raw_message_delivery is only valid for sqs, lambda, http, https, and firehose protocols"
            end
          end

          # Filter policy scope validation
          if attrs.filter_policy_scope == 'MessageBody' && !%w[sqs lambda firehose].include?(attrs.protocol)
            raise Dry::Struct::Error, "MessageBody filter scope is only valid for sqs, lambda, and firehose protocols"
          end

          # Delivery policy validation
          if attrs.delivery_policy && !%w[http https].include?(attrs.protocol)
            raise Dry::Struct::Error, "delivery_policy is only valid for http and https protocols"
          end

          attrs
        end

        # Helper methods
        def requires_confirmation?
          %w[email email-json http https].include?(protocol) && !endpoint_auto_confirms
        end

        def supports_filter_policy?
          %w[sqs lambda http https firehose].include?(protocol)
        end

        def supports_raw_delivery?
          %w[sqs lambda http https firehose].include?(protocol)
        end

        def supports_dlq?
          %w[sqs lambda http https firehose].include?(protocol)
        end

        def is_email_subscription?
          %w[email email-json].include?(protocol)
        end

        def is_webhook_subscription?
          %w[http https].include?(protocol)
        end

        def filter_policy_attributes
          return [] unless filter_policy
          
          begin
            policy = JSON.parse(filter_policy)
            policy.keys
          rescue
            []
          end
        end

        def has_numeric_filters?
          return false unless filter_policy
          
          begin
            policy = JSON.parse(filter_policy)
            policy.values.any? do |filter|
              filter.is_a?(Hash) && filter.key?('numeric')
            end
          rescue
            false
          end
        end
      end
    end
      end
    end
  end
end