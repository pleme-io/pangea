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
        # EFS File System resource attributes with validation
        class EfsFileSystemAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Core EFS attributes
          attribute? :creation_token, Resources::Types::String.optional
          attribute :performance_mode, Resources::Types::EfsPerformanceMode.default("generalPurpose")
          attribute :throughput_mode, Resources::Types::EfsThroughputMode.default("bursting")
          attribute? :provisioned_throughput_in_mibps, Resources::Types::Integer.optional
          attribute :encrypted, Resources::Types::Bool.default(true)
          attribute? :kms_key_id, Resources::Types::String.optional
          
          # Lifecycle management
          attribute? :lifecycle_policy, Resources::Types::EfsLifecyclePolicy.optional
          
          # Storage configuration
          attribute? :availability_zone_name, Resources::Types::String.optional
          
          # Tags
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Call parent to get defaults applied
            instance = super(attrs)
            
            # Validate throughput mode configuration
            if instance.throughput_mode == "provisioned" && !instance.provisioned_throughput_in_mibps
              raise Dry::Struct::Error, "provisioned_throughput_in_mibps is required when throughput_mode is 'provisioned'"
            end
            
            if instance.throughput_mode == "bursting" && instance.provisioned_throughput_in_mibps
              raise Dry::Struct::Error, "provisioned_throughput_in_mibps cannot be set when throughput_mode is 'bursting'"
            end
            
            # Validate provisioned throughput range
            if instance.provisioned_throughput_in_mibps
              throughput = instance.provisioned_throughput_in_mibps
              if throughput < 1 || throughput > 3584
                raise Dry::Struct::Error, "provisioned_throughput_in_mibps must be between 1 and 3584 MiB/s, got #{throughput}"
              end
            end
            
            # Validate performance mode constraints for One Zone
            if instance.availability_zone_name && instance.performance_mode == "maxIO"
              raise Dry::Struct::Error, "maxIO performance mode is not supported with One Zone storage classes"
            end
            
            instance
          end
          
          # Computed properties
          def is_one_zone?
            !availability_zone_name.nil?
          end
          
          def is_regional?
            availability_zone_name.nil?
          end
          
          def storage_class
            is_one_zone? ? "One Zone" : "Regional"
          end
          
          def estimated_monthly_cost_per_gb
            # Rough cost estimation in USD per GB per month (as of 2024)
            base_cost = is_one_zone? ? 0.0225 : 0.30
            
            # Add throughput costs for provisioned mode
            if throughput_mode == "provisioned" && provisioned_throughput_in_mibps
              throughput_cost = provisioned_throughput_in_mibps * 6.00 / 1024 # $6 per provisioned MiB/s per month
              return { storage: base_cost, throughput: throughput_cost, total: base_cost + throughput_cost }
            end
            
            { storage: base_cost, throughput: 0.0, total: base_cost }
          end
        end
      end
    end
  end
end