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

module Pangea
  module Resources
    module AWS
      module Types
        # CloudWatch Log Subscription Filter resource attributes with validation
        class CloudWatchLogSubscriptionFilterAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :name, Resources::Types::String
          attribute :log_group_name, Resources::Types::String
          attribute :destination_arn, Resources::Types::String
          attribute :filter_pattern, Resources::Types::String.default('')
          
          # Optional attributes
          attribute :role_arn, Resources::Types::String.optional.default(nil)
          attribute :distribution, Resources::Types::String.default('ByLogStream').enum(
            'Random', 'ByLogStream'
          )
          
          # Validate ARN formats and filter configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate name format
            if attrs[:name] && !attrs[:name].match?(/^[\.\-_#A-Za-z0-9]+$/)
              raise Dry::Struct::Error, "name must contain only alphanumeric characters, periods, hyphens, underscores, and hash"
            end
            
            # Validate destination_arn format
            if attrs[:destination_arn]
              unless attrs[:destination_arn].match?(/^arn:aws[a-z\-]*:/) ||
                     attrs[:destination_arn].match?(/^\$\{/)  # Allow terraform references
                raise Dry::Struct::Error, "destination_arn must be a valid ARN"
              end
            end
            
            # Validate role_arn if provided
            if attrs[:role_arn] && !attrs[:role_arn].empty?
              unless attrs[:role_arn].match?(/^arn:aws[a-z\-]*:iam::\d{12}:role\//) ||
                     attrs[:role_arn].match?(/^\$\{/)  # Allow terraform references
                raise Dry::Struct::Error, "role_arn must be a valid IAM role ARN"
              end
            end
            
            # Determine if role is required based on destination
            if attrs[:destination_arn] && !attrs[:destination_arn].match?(/^\$\{/)
              if attrs[:destination_arn].include?(':lambda:') || 
                 attrs[:destination_arn].include?(':kinesis:') ||
                 attrs[:destination_arn].include?(':firehose:')
                unless attrs[:role_arn]
                  raise Dry::Struct::Error, "role_arn is required for Lambda, Kinesis, or Firehose destinations"
                end
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def destination_service
            return :unknown unless destination_arn
            
            case destination_arn
            when /^arn:aws[a-z\-]*:logs:/
              :cloudwatch_logs
            when /^arn:aws[a-z\-]*:lambda:/
              :lambda
            when /^arn:aws[a-z\-]*:kinesis:.*:stream\//
              :kinesis_stream
            when /^arn:aws[a-z\-]*:firehose:/
              :kinesis_firehose
            when /^arn:aws[a-z\-]*:es:/
              :elasticsearch
            else
              :unknown
            end
          end
          
          def is_cross_account?
            return false unless destination_arn && destination_arn.match?(/^arn:/)
            
            # Extract account ID from destination ARN
            destination_parts = destination_arn.split(':')
            destination_account = destination_parts[4] if destination_parts.length > 4
            
            # Extract account ID from role ARN if present
            if role_arn && role_arn.match?(/^arn:/)
              role_parts = role_arn.split(':')
              role_account = role_parts[4] if role_parts.length > 4
              
              return destination_account != role_account if destination_account && role_account
            end
            
            false
          end
          
          def requires_role?
            [:lambda, :kinesis_stream, :kinesis_firehose].include?(destination_service)
          end
          
          def has_filter_pattern?
            !filter_pattern.empty?
          end
          
          def to_h
            hash = {
              name: name,
              log_group_name: log_group_name,
              destination_arn: destination_arn,
              filter_pattern: filter_pattern,
              distribution: distribution
            }
            
            hash[:role_arn] = role_arn if role_arn
            
            hash.compact
          end
        end
      end
    end
  end
end