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
        # SageMaker Feature Group attributes with Feature Store validation
        class SageMakerFeatureGroupAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :feature_group_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 64,
            format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/
          )
          attribute :record_identifier_feature_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 64,
            format: /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
          )
          attribute :event_time_feature_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 64,
            format: /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
          )
          attribute :feature_definitions, Resources::Types::Array.of(
            Hash.schema(
              feature_name: String.constrained(
                min_size: 1,
                max_size: 64,
                format: /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
              ),
              feature_type: String.enum('Integral', 'Fractional', 'String')
            )
          ).constrained(min_size: 1, max_size: 2500)
          
          # Optional attributes
          attribute :description, Resources::Types::String.optional
          attribute :online_store_config, Resources::Types::Hash.schema(
            enable_online_store?: Bool.default(true),
            security_config?: Hash.schema(
              kms_key_id?: String.optional
            ).optional,
            ttl_duration?: Hash.schema(
              unit: String.enum('Seconds', 'Minutes', 'Hours', 'Days', 'Weeks'),
              value: Integer.constrained(gteq: 1)
            ).optional
          ).optional
          attribute :offline_store_config, Resources::Types::Hash.schema(
            s3_storage_config: Hash.schema(
              s3_uri: String.constrained(format: /\As3:\/\//),
              kms_key_id?: String.optional,
              resolved_output_s3_uri?: String.optional
            ),
            disable_glue_table_creation?: Bool.default(false),
            data_catalog_config?: Hash.schema(
              table_name?: String.optional,
              catalog?: String.default('AwsDataCatalog'),
              database?: String.default('sagemaker_featurestore')
            ).optional,
            table_format?: String.enum('Glue', 'Iceberg').default('Glue')
          ).optional
          attribute :role_arn, Resources::Types::String.constrained(
            format: /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_+=,.@-]+\z/
          ).optional
          attribute :tags, Resources::Types::AwsTags
          
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate feature definitions have unique names
            if attrs[:feature_definitions]
              feature_names = attrs[:feature_definitions].map { |fd| fd[:feature_name] }
              if feature_names.uniq.size != feature_names.size
                raise Dry::Struct::Error, "Feature definition names must be unique"
              end
              
              # Validate record identifier and event time are in feature definitions
              record_identifier = attrs[:record_identifier_feature_name]
              event_time = attrs[:event_time_feature_name]
              
              unless feature_names.include?(record_identifier)
                raise Dry::Struct::Error, "record_identifier_feature_name must be included in feature_definitions"
              end
              
              unless feature_names.include?(event_time)
                raise Dry::Struct::Error, "event_time_feature_name must be included in feature_definitions"
              end
            end
            
            # Validate at least one store is configured
            online_store = attrs[:online_store_config]
            offline_store = attrs[:offline_store_config]
            
            if !online_store && !offline_store
              raise Dry::Struct::Error, "At least one of online_store_config or offline_store_config must be specified"
            end
            
            super(attrs)
          end
          
          def estimated_feature_store_cost
            online_cost = has_online_store? ? 50.0 : 0.0 # Estimated monthly cost
            offline_cost = has_offline_store? ? 10.0 : 0.0 # S3 storage cost estimate
            
            online_cost + offline_cost
          end
          
          def has_online_store?
            online_store_config&.dig(:enable_online_store) != false
          end
          
          def has_offline_store?
            !offline_store_config.nil?
          end
          
          def feature_count
            feature_definitions.size
          end
          
          def uses_ttl?
            !online_store_config&.dig(:ttl_duration).nil?
          end
          
          def uses_iceberg_format?
            offline_store_config&.dig(:table_format) == 'Iceberg'
          end
        end
      end
    end
  end
end