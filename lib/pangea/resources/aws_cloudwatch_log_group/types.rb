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
        # CloudWatch Log Group resource attributes with validation
        class CloudWatchLogGroupAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :name, Pangea::Resources::Types::String
          
          # Optional attributes
          attribute :retention_in_days?, Pangea::Resources::Types::Integer.optional.default(nil).constrained(
            included_in: [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653]
          )
          attribute :kms_key_id?, Pangea::Resources::Types::String.optional
          attribute :log_group_class?, Pangea::Resources::Types::String.optional.default(nil).constrained(
            included_in: ['STANDARD', 'INFREQUENT_ACCESS']
          )
          attribute :skip_destroy?, Pangea::Resources::Types::Bool.optional.default(false)
          
          # Tags
          attribute :tags?, Pangea::Resources::Types::AwsTags.optional.default(proc { {} }.freeze)
          
          # Validate log group name pattern
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            if attrs[:name]
              # CloudWatch log group name validation
              name = attrs[:name]
              
              # Must not be empty
              if name.empty?
                raise Dry::Struct::Error, "Log group name cannot be empty"
              end
              
              # Length constraints
              if name.length > 512
                raise Dry::Struct::Error, "Log group name cannot exceed 512 characters"
              end
              
              # Character validation - allows letters, numbers, periods, underscores, hyphens, and forward slashes
              unless name.match?(/\A[a-zA-Z0-9._\-\/]+\z/)
                raise Dry::Struct::Error, "Log group name can only contain alphanumeric characters, periods, underscores, hyphens, and forward slashes"
              end
              
              # Cannot start with aws/ (reserved for AWS services)
              if name.start_with?('aws/')
                raise Dry::Struct::Error, "Log group name cannot start with 'aws/' as it's reserved for AWS services"
              end
              
              # Must not end with a forward slash unless it's a single slash
              if name.length > 1 && name.end_with?('/')
                raise Dry::Struct::Error, "Log group name cannot end with a forward slash"
              end
              
              # Cannot contain consecutive forward slashes
              if name.include?('//')
                raise Dry::Struct::Error, "Log group name cannot contain consecutive forward slashes"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def has_retention?
            !retention_in_days.nil?
          end
          
          def has_encryption?
            !kms_key_id.nil?
          end
          
          def is_infrequent_access?
            log_group_class == 'INFREQUENT_ACCESS'
          end
          
          def estimated_monthly_cost_usd
            # Base cost estimation for CloudWatch Logs
            base_gb_per_month = 10.0 # Assume 10GB ingestion per month
            
            case log_group_class
            when 'INFREQUENT_ACCESS'
              # IA class: lower ingestion cost, higher query cost
              ingestion_cost = base_gb_per_month * 0.25 # $0.25 per GB for IA
              storage_cost = base_gb_per_month * 0.013  # $0.013 per GB/month for IA storage
            else
              # Standard class
              ingestion_cost = base_gb_per_month * 0.50 # $0.50 per GB for standard
              storage_cost = base_gb_per_month * 0.025  # $0.025 per GB/month for standard storage
            end
            
            # Add KMS encryption cost if enabled
            encryption_cost = has_encryption? ? 1.00 : 0.0 # $1 per month for KMS usage
            
            total_cost = ingestion_cost + storage_cost + encryption_cost
            total_cost.round(2)
          end
          
          def to_h
            hash = {
              name: name,
              skip_destroy: skip_destroy,
              tags: tags
            }
            
            hash[:retention_in_days] = retention_in_days if retention_in_days
            hash[:kms_key_id] = kms_key_id if kms_key_id
            hash[:log_group_class] = log_group_class if log_group_class
            
            hash.compact
          end
        end
      end
    end
  end
end