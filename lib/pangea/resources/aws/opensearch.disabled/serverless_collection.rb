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
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module OpenSearch
        # OpenSearch Serverless collection configuration
        class ServerlessCollectionAttributes < Dry::Struct
          attribute :name, Types::String
          attribute :description, Types::String.optional
          attribute :type, Types::String.default('SEARCH') # 'SEARCH', 'TIMESERIES', 'VECTORSEARCH'
          
          attribute? :standby_replicas, Types::String.default('ENABLED') # 'ENABLED', 'DISABLED'
          
          attribute :tags, Types::Hash.default({}.freeze)
        end

        # OpenSearch Serverless collection reference
        class ServerlessCollectionReference < ::Pangea::Resources::ResourceReference
          property :id
          property :name
          property :arn
          property :collection_endpoint
          property :dashboard_endpoint
          property :kms_key_arn

          def collection_type
            get_attribute(:type) || 'SEARCH'
          end

          def search_collection?
            collection_type == 'SEARCH'
          end

          def timeseries_collection?
            collection_type == 'TIMESERIES'
          end

          def vector_collection?
            collection_type == 'VECTORSEARCH'
          end

          def standby_replicas_enabled?
            standby = get_attribute(:standby_replicas)
            standby.nil? || standby == 'ENABLED'
          end

          def collection_url(path = '')
            "https://#{collection_endpoint}#{path}" if collection_endpoint
          end

          def dashboard_url(path = '')
            "#{dashboard_endpoint}#{path}" if dashboard_endpoint
          end

          # Helper for common OpenSearch operations
          def index_url(index_name)
            collection_url("/#{index_name}")
          end

          def search_url(index_name = '_all')
            collection_url("/#{index_name}/_search")
          end
        end

        module ServerlessCollection
          # Creates an OpenSearch Serverless collection
          #
          # @param name [Symbol] The collection identifier
          # @param attributes [Hash] Collection configuration
          # @return [ServerlessCollectionReference] Reference to the collection
          def aws_opensearch_serverless_collection(name, attributes = {})
            collection_attrs = ServerlessCollectionAttributes.new(attributes)
            
            synthesizer.resource :aws_opensearch_serverless_collection, name do
              name collection_attrs.name
              description collection_attrs.description if collection_attrs.description
              type collection_attrs.type
              standby_replicas collection_attrs.standby_replicas
              
              tags collection_attrs.tags unless collection_attrs.tags.empty?
            end

            ServerlessCollectionReference.new(name, :aws_opensearch_serverless_collection, synthesizer, collection_attrs)
          end
        end
      end
    end
  end
end