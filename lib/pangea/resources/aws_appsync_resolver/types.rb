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
        # AppSync resolver kind
        AppSyncResolverKind = String.enum('UNIT', 'PIPELINE')

        # AppSync runtime configuration
        AppSyncRuntime = Hash.schema(
          name: String.enum('APPSYNC_JS'),
          runtime_version: String.constrained(format: /\A\d+\.\d+\.\d+\z/)
        )

        # AppSync pipeline config
        AppSyncPipelineConfig = Hash.schema(
          functions: Resources::Types::Array.of(String).constrained(min_size: 1)
        )

        # AppSync caching config
        AppSyncCachingConfig = Hash.schema(
          caching_keys?: Resources::Types::Array.of(String).optional,
          ttl?: Resources::Types::Integer.constrained(gteq: 1, lteq: 3600).optional
        )

        # AppSync sync config for subscriptions
        AppSyncSyncConfig = Hash.schema(
          conflict_detection?: String.enum('VERSION', 'NONE').optional,
          conflict_handler?: String.enum('OPTIMISTIC_CONCURRENCY', 'LAMBDA', 'AUTOMERGE', 'NONE').optional,
          lambda_conflict_handler_config?: Hash.schema(
            lambda_conflict_handler_arn?: String.constrained(format: /\Aarn:aws:lambda:/).optional
          ).optional
        )

        # AppSync Resolver resource attributes
        class AppSyncResolverAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :api_id, Resources::Types::String
          
          attribute :type, Resources::Types::String.constrained(
            format: /\A[A-Z][a-zA-Z0-9_]*\z/,
            size: 1..65
          )
          
          attribute :field, Resources::Types::String.constrained(
            format: /\A[a-zA-Z][a-zA-Z0-9_]*\z/,
            size: 1..65
          )
          
          attribute? :code, Resources::Types::String.optional
          
          attribute? :data_source, Resources::Types::String.optional
          
          attribute? :kind, AppSyncResolverKind.default('UNIT')
          
          attribute? :max_batch_size, Resources::Types::Integer.constrained(
            gteq: 1, lteq: 2000
          ).optional
          
          attribute? :pipeline_config, AppSyncPipelineConfig.optional
          
          attribute? :request_template, Resources::Types::String.optional
          
          attribute? :response_template, Resources::Types::String.optional
          
          attribute? :runtime, AppSyncRuntime.optional
          
          attribute? :caching_config, AppSyncCachingConfig.optional
          
          attribute? :sync_config, AppSyncSyncConfig.optional

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate resolver configuration based on kind
            if attrs[:kind] == 'PIPELINE'
              unless attrs[:pipeline_config]
                raise Dry::Struct::Error, "pipeline_config is required when kind is PIPELINE"
              end
              if attrs[:data_source]
                raise Dry::Struct::Error, "data_source should not be specified for PIPELINE resolvers"
              end
            else # UNIT resolver
              unless attrs[:data_source]
                raise Dry::Struct::Error, "data_source is required for UNIT resolvers"
              end
              if attrs[:pipeline_config]
                raise Dry::Struct::Error, "pipeline_config should not be specified for UNIT resolvers"
              end
            end

            # Validate runtime and template configuration
            if attrs[:runtime] && (attrs[:request_template] || attrs[:response_template])
              raise Dry::Struct::Error, "runtime and templates (request_template/response_template) are mutually exclusive"
            end

            if attrs[:runtime] && !attrs[:code]
              raise Dry::Struct::Error, "code is required when using runtime"
            end

            # Validate conflict handler configuration
            if attrs[:sync_config] && attrs[:sync_config][:conflict_handler] == 'LAMBDA'
              unless attrs[:sync_config][:lambda_conflict_handler_config]
                raise Dry::Struct::Error, "lambda_conflict_handler_config is required when conflict_handler is LAMBDA"
              end
            end

            super(attrs)
          end
        end
      end
    end
  end
end