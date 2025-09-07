# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      class IotAnalyticsDatastoreAttributes < Dry::Struct
        attribute :datastore_name, Resources::Types::IotAnalyticsDatastoreName
        attribute :datastore_storage, Resources::Types::Hash.optional
        attribute :retention_period, Resources::Types::Hash.optional
        attribute :file_format_configuration, Resources::Types::Hash.optional
        attribute :tags, Resources::Types::AwsTags.default({})
        
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