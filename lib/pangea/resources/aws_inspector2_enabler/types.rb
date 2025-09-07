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
        # Inspector v2 Enabler attributes with validation
        class Inspector2EnablerAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :account_ids, Array.of(Resources::Types::AwsAccountId).constrained(min_size: 1)
          attribute :resource_types, Array.of(Resources::Types::InspectorV2ResourceType).constrained(min_size: 1)
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate unique account IDs
            if attrs[:account_ids]
              duplicates = attrs[:account_ids].group_by(&:itself).select { |_, v| v.size > 1 }.keys
              unless duplicates.empty?
                raise Dry::Struct::Error, "Duplicate account IDs found: #{duplicates.join(', ')}"
              end
            end
            
            # Validate unique resource types
            if attrs[:resource_types]
              duplicates = attrs[:resource_types].group_by(&:itself).select { |_, v| v.size > 1 }.keys
              unless duplicates.empty?
                raise Dry::Struct::Error, "Duplicate resource types found: #{duplicates.join(', ')}"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def account_count
            account_ids.size
          end
          
          def resource_type_count
            resource_types.size
          end
          
          def covers_ec2?
            resource_types.include?('EC2')
          end
          
          def covers_ecr?
            resource_types.include?('ECR')
          end
          
          def comprehensive_coverage?
            covers_ec2? && covers_ecr?
          end
          
          def single_account?
            account_ids.size == 1
          end
          
          def multi_account?
            account_ids.size > 1
          end
        end
      end
    end
  end
end