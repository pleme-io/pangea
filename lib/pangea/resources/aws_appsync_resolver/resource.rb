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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_appsync_resolver/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS AppSync Resolver
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resolver attributes
      # @option attributes [String] :api_id The GraphQL API ID
      # @option attributes [String] :type The GraphQL type (e.g., Query, Mutation, Subscription)
      # @option attributes [String] :field The GraphQL field name
      # @option attributes [String] :code JavaScript code for APPSYNC_JS runtime
      # @option attributes [String] :data_source Data source name (for UNIT resolvers)
      # @option attributes [String] :kind UNIT or PIPELINE
      # @option attributes [Integer] :max_batch_size Max batch size for array operations
      # @option attributes [Hash] :pipeline_config Pipeline configuration (for PIPELINE resolvers)
      # @option attributes [String] :request_template VTL request mapping template
      # @option attributes [String] :response_template VTL response mapping template
      # @option attributes [Hash] :runtime Runtime configuration
      # @option attributes [Hash] :caching_config Caching configuration
      # @option attributes [Hash] :sync_config Conflict resolution configuration
      # @return [ResourceReference] Reference object with outputs
      def aws_appsync_resolver(name, attributes = {})
        # Validate attributes using dry-struct
        resolver_attrs = Types::Types::AppSyncResolverAttributes.new(attributes)
        
        # Generate terraform resource block
        resource(:aws_appsync_resolver, name) do
          api_id resolver_attrs.api_id
          type resolver_attrs.type
          field resolver_attrs.field
          
          code resolver_attrs.code if resolver_attrs.code
          data_source resolver_attrs.data_source if resolver_attrs.data_source
          kind resolver_attrs.kind
          max_batch_size resolver_attrs.max_batch_size if resolver_attrs.max_batch_size
          
          # Pipeline configuration
          if resolver_attrs.pipeline_config
            pipeline_config do
              functions resolver_attrs.pipeline_config[:functions]
            end
          end
          
          request_template resolver_attrs.request_template if resolver_attrs.request_template
          response_template resolver_attrs.response_template if resolver_attrs.response_template
          
          # Runtime configuration
          if resolver_attrs.runtime
            runtime do
              name resolver_attrs.runtime[:name]
              runtime_version resolver_attrs.runtime[:runtime_version]
            end
          end
          
          # Caching configuration
          if resolver_attrs.caching_config
            caching_config do
              caching_keys resolver_attrs.caching_config[:caching_keys] if resolver_attrs.caching_config[:caching_keys]
              ttl resolver_attrs.caching_config[:ttl] if resolver_attrs.caching_config[:ttl]
            end
          end
          
          # Sync configuration
          if resolver_attrs.sync_config
            sync_config do
              conflict_detection resolver_attrs.sync_config[:conflict_detection] if resolver_attrs.sync_config[:conflict_detection]
              conflict_handler resolver_attrs.sync_config[:conflict_handler] if resolver_attrs.sync_config[:conflict_handler]
              
              if resolver_attrs.sync_config[:lambda_conflict_handler_config]
                lambda_conflict_handler_config do
                  lambda_conflict_handler_arn resolver_attrs.sync_config[:lambda_conflict_handler_config][:lambda_conflict_handler_arn] if resolver_attrs.sync_config[:lambda_conflict_handler_config][:lambda_conflict_handler_arn]
                end
              end
            end
          end
        end
        
        # Return resource reference with outputs
        ResourceReference.new(
          type: 'aws_appsync_resolver',
          name: name,
          resource_attributes: resolver_attrs.to_h,
          outputs: {
            arn: "${aws_appsync_resolver.#{name}.arn}",
            api_id: "${aws_appsync_resolver.#{name}.api_id}",
            type: "${aws_appsync_resolver.#{name}.type}",
            field: "${aws_appsync_resolver.#{name}.field}",
            kind: "${aws_appsync_resolver.#{name}.kind}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)