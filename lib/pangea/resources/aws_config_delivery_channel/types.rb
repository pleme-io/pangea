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
        # AWS Config Delivery Channel resource attributes with validation
        class ConfigDeliveryChannelAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :name, Resources::Types::String
          attribute :s3_bucket_name, Resources::Types::String
          
          # Optional attributes
          attribute :s3_key_prefix, Resources::Types::String.optional.default(nil)
          attribute :s3_kms_key_arn, Resources::Types::String.optional.default(nil)
          attribute :sns_topic_arn, Resources::Types::String.optional.default(nil)
          attribute :snapshot_delivery_properties, Resources::Types::Hash.optional.default(nil)
          
          # Tags
          attribute :tags, Resources::Types::AwsTags
          
          # Validate delivery channel name and S3 bucket name
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            if attrs[:name]
              name = attrs[:name]
              
              # Must not be empty
              if name.empty?
                raise Dry::Struct::Error, "Delivery channel name cannot be empty"
              end
              
              # Length constraints (AWS Config allows 1-256 characters)
              if name.length > 256
                raise Dry::Struct::Error, "Delivery channel name cannot exceed 256 characters"
              end
              
              # Character validation - alphanumeric, hyphens, underscores, periods
              unless name.match?(/\A[a-zA-Z0-9._-]+\z/)
                raise Dry::Struct::Error, "Delivery channel name can only contain alphanumeric characters, periods, hyphens, and underscores"
              end
            end
            
            if attrs[:s3_bucket_name]
              bucket_name = attrs[:s3_bucket_name]
              
              # Must not be empty
              if bucket_name.empty?
                raise Dry::Struct::Error, "S3 bucket name cannot be empty"
              end
              
              # S3 bucket name validation (basic)
              unless bucket_name.match?(/\A[a-z0-9.-]+\z/)
                raise Dry::Struct::Error, "S3 bucket name can only contain lowercase letters, numbers, periods, and hyphens"
              end
              
              # Length validation
              if bucket_name.length < 3 || bucket_name.length > 63
                raise Dry::Struct::Error, "S3 bucket name must be between 3 and 63 characters"
              end
            end
            
            # Validate KMS key ARN if provided
            if attrs[:s3_kms_key_arn]
              kms_arn = attrs[:s3_kms_key_arn]
              unless kms_arn.match?(/\Aarn:aws:kms:[^:]+:\d{12}:key\//)
                raise Dry::Struct::Error, "KMS key ARN must be a valid KMS key ARN format"
              end
            end
            
            # Validate SNS topic ARN if provided
            if attrs[:sns_topic_arn]
              sns_arn = attrs[:sns_topic_arn]
              unless sns_arn.match?(/\Aarn:aws:sns:[^:]+:\d{12}:/)
                raise Dry::Struct::Error, "SNS topic ARN must be a valid SNS topic ARN format"
              end
            end
            
            # Validate snapshot delivery properties if provided
            if attrs[:snapshot_delivery_properties].is_a?(Hash)
              props = attrs[:snapshot_delivery_properties]
              
              if props.key?(:delivery_frequency) && !props[:delivery_frequency].is_a?(String)
                raise Dry::Struct::Error, "snapshot_delivery_properties.delivery_frequency must be a string"
              end
              
              # Valid delivery frequencies
              valid_frequencies = [
                'One_Hour', 'Three_Hours', 'Six_Hours', 'Twelve_Hours', 'TwentyFour_Hours'
              ]
              
              if props[:delivery_frequency] && !valid_frequencies.include?(props[:delivery_frequency])
                raise Dry::Struct::Error, "snapshot_delivery_properties.delivery_frequency must be one of: #{valid_frequencies.join(', ')}"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def has_s3_key_prefix?
            !s3_key_prefix.nil? && !s3_key_prefix.empty?
          end
          
          def has_encryption?
            !s3_kms_key_arn.nil?
          end
          
          def has_sns_notifications?
            !sns_topic_arn.nil?
          end
          
          def has_snapshot_delivery_properties?
            !snapshot_delivery_properties.nil? && !snapshot_delivery_properties.empty?
          end
          
          def delivery_frequency
            if has_snapshot_delivery_properties?
              snapshot_delivery_properties[:delivery_frequency] || 'TwentyFour_Hours'
            else
              'TwentyFour_Hours'
            end
          end
          
          def estimated_monthly_cost_usd
            # AWS Config delivery channel costs
            base_delivery_cost = 2.00 # Base cost for delivery channel operation
            
            # S3 storage cost (estimate based on configuration items)
            estimated_config_items = 1000 # Conservative estimate
            config_item_size_kb = 5 # Average size per configuration item
            total_storage_gb = (estimated_config_items * config_item_size_kb) / 1024.0 / 1024.0
            
            s3_storage_cost = total_storage_gb * 0.023 # $0.023 per GB/month standard storage
            
            # S3 PUT requests cost (based on delivery frequency)
            requests_per_month = case delivery_frequency
                                when 'One_Hour' then 30 * 24
                                when 'Three_Hours' then 30 * 8
                                when 'Six_Hours' then 30 * 4
                                when 'Twelve_Hours' then 30 * 2
                                else 30 # TwentyFour_Hours
                                end
            
            s3_request_cost = (requests_per_month / 1000.0) * 0.005 # $0.005 per 1000 PUT requests
            
            # SNS cost if notifications enabled
            sns_cost = has_sns_notifications? ? 1.00 : 0.0
            
            # KMS cost if encryption enabled
            kms_cost = has_encryption? ? 1.00 : 0.0
            
            total_cost = base_delivery_cost + s3_storage_cost + s3_request_cost + sns_cost + kms_cost
            total_cost.round(2)
          end
          
          def to_h
            hash = {
              name: name,
              s3_bucket_name: s3_bucket_name,
              tags: tags
            }
            
            hash[:s3_key_prefix] = s3_key_prefix if has_s3_key_prefix?
            hash[:s3_kms_key_arn] = s3_kms_key_arn if has_encryption?
            hash[:sns_topic_arn] = sns_topic_arn if has_sns_notifications?
            hash[:snapshot_delivery_properties] = snapshot_delivery_properties if has_snapshot_delivery_properties?
            
            hash.compact
          end
        end
      end
    end
  end
end