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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      class IotAnalyticsChannelAttributes < Dry::Struct
        attribute :channel_name, Resources::Types::IotAnalyticsChannelName
        attribute :channel_storage, Resources::Types::Hash.optional
        attribute :retention_period, Resources::Types::Hash.optional
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)
        
        def has_custom_storage?
          channel_storage && channel_storage[:service_managed_s3].nil?
        end
        
        def retention_period_days
          retention_period&.dig(:number_of_days) || 7 # Default 7 days
        end
        
        def has_unlimited_retention?
          retention_period&.dig(:unlimited) == true
        end
        
        def storage_type
          return 'service_managed' if channel_storage.nil? || channel_storage[:service_managed_s3]
          return 'customer_managed_s3' if channel_storage[:customer_managed_s3]
          'unknown'
        end
        
        def estimated_cost_tier
          if has_unlimited_retention?
            'high'
          elsif retention_period_days > 30
            'medium'
          else
            'low'
          end
        end
      end
    end
  end
end