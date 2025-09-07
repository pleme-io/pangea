# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # CloudWatch Log Destination resource attributes with validation
        class CloudWatchLogDestinationAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :name, Resources::Types::String
          attribute :role_arn, Resources::Types::String
          attribute :target_arn, Resources::Types::String
          
          # Optional attributes
          attribute :tags, Resources::Types::AwsTags
          
          # Validate ARN formats
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate role_arn format
            if attrs[:role_arn] && !attrs[:role_arn].match?(/^arn:aws[a-z\-]*:iam::\d{12}:role\//)
              raise Dry::Struct::Error, "role_arn must be a valid IAM role ARN"
            end
            
            # Validate target_arn format (Kinesis stream)
            if attrs[:target_arn] && !attrs[:target_arn].match?(/^arn:aws[a-z\-]*:kinesis:/)
              raise Dry::Struct::Error, "target_arn must be a valid Kinesis stream ARN"
            end
            
            # Validate name format (alphanumeric, hyphens, underscores, periods)
            if attrs[:name] && !attrs[:name].match?(/^[\w\-\.]+$/)
              raise Dry::Struct::Error, "name must contain only alphanumeric characters, hyphens, underscores, and periods"
            end
            
            super(attrs)
          end
          
          # Computed properties
          def cross_account_capable?
            true # Log destinations are designed for cross-account access
          end
          
          def target_service
            return nil unless target_arn
            
            if target_arn.include?(':kinesis:')
              :kinesis
            elsif target_arn.include?(':firehose:')
              :firehose
            elsif target_arn.include?(':lambda:')
              :lambda
            else
              :unknown
            end
          end
          
          def region
            return nil unless target_arn
            parts = target_arn.split(':')
            parts[3] if parts.length > 3
          end
          
          def account_id
            return nil unless role_arn
            parts = role_arn.split(':')
            parts[4] if parts.length > 4
          end
          
          def to_h
            hash = {
              name: name,
              role_arn: role_arn,
              target_arn: target_arn,
              tags: tags
            }
            
            hash.compact
          end
        end
      end
    end
  end
end