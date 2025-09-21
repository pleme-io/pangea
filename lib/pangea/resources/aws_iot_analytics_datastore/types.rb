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
      class IotAnalyticsDatastoreAttributes < Dry::Struct
        attribute :datastore_name, Resources::Types::IotAnalyticsDatastoreName
        attribute :datastore_storage, Resources::Types::Hash.optional
        attribute :retention_period, Resources::Types::Hash.optional
        attribute :file_format_configuration, Resources::Types::Hash.optional
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)
        
        def has_parquet_format?
          file_format_configuration&.key?(:parquet_configuration) == true
        end
        
        def has_json_format?
          file_format_configuration&.key?(:json_configuration) == true
        end
        
        def format_type
          return 'parquet' if has_parquet_format?
          return 'json' if has_json_format?
          'default'
        end
        
        def storage_optimization_level
          case format_type
          when 'parquet' then 'high'
          when 'json' then 'medium'
          else 'basic'
          end
        end
        
        def retention_days
          retention_period&.dig(:number_of_days) || 7
        end
        
        def query_performance_tier
          has_parquet_format? ? 'optimized' : 'standard'
        end
      end
    end
  end
end