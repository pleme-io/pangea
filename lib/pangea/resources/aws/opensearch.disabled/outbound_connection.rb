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
        # OpenSearch outbound connection for cross-cluster search
        class OutboundConnectionAttributes < Dry::Struct
          attribute :connection_alias, Types::String
          attribute :local_domain_info do
            attribute :owner_id, Types::String.optional
            attribute :domain_name, Types::String
            attribute :region, Types::String.optional
          end
          attribute :remote_domain_info do
            attribute :owner_id, Types::String.optional
            attribute :domain_name, Types::String
            attribute :region, Types::String.optional
          end
          attribute :connection_mode, Types::String.default('VPC_ENDPOINT')
          attribute? :connection_properties do
            attribute? :endpoint do
              attribute :service_name, Types::String.optional
              attribute :region, Types::String.optional
            end
            attribute? :cross_cluster_search do
              attribute :skip_unavailable, Types::Bool.optional
            end
          end
        end

        # OpenSearch outbound connection reference
        class OutboundConnectionReference < ::Pangea::Resources::ResourceReference
          property :id
          property :connection_id
          property :connection_alias
          property :connection_status

          def local_domain_name
            get_attribute(:local_domain_info)&.domain_name
          end

          def remote_domain_name
            get_attribute(:remote_domain_info)&.domain_name
          end

          def connection_mode
            get_attribute(:connection_mode) || 'VPC_ENDPOINT'
          end

          def active?
            connection_status == 'ACTIVE'
          end

          def cross_region?
            local_region = get_attribute(:local_domain_info)&.region
            remote_region = get_attribute(:remote_domain_info)&.region
            local_region && remote_region && local_region != remote_region
          end

          def cross_account?
            local_owner = get_attribute(:local_domain_info)&.owner_id
            remote_owner = get_attribute(:remote_domain_info)&.owner_id
            local_owner && remote_owner && local_owner != remote_owner
          end
        end

        module OutboundConnection
          # Creates an outbound connection for cross-cluster search
          #
          # @param name [Symbol] The connection name
          # @param attributes [Hash] Connection configuration
          # @return [OutboundConnectionReference] Reference to the connection
          def aws_opensearch_outbound_connection(name, attributes = {})
            connection_attrs = OutboundConnectionAttributes.new(attributes)
            
            synthesizer.resource :aws_opensearch_outbound_connection, name do
              connection_alias connection_attrs.connection_alias

              local_domain_info do
                owner_id connection_attrs.local_domain_info.owner_id if connection_attrs.local_domain_info.owner_id
                domain_name connection_attrs.local_domain_info.domain_name
                region connection_attrs.local_domain_info.region if connection_attrs.local_domain_info.region
              end

              remote_domain_info do
                owner_id connection_attrs.remote_domain_info.owner_id if connection_attrs.remote_domain_info.owner_id
                domain_name connection_attrs.remote_domain_info.domain_name
                region connection_attrs.remote_domain_info.region if connection_attrs.remote_domain_info.region
              end

              connection_mode connection_attrs.connection_mode

              if connection_attrs.connection_properties
                connection_properties do
                  if connection_attrs.connection_properties.endpoint
                    endpoint do
                      service_name connection_attrs.connection_properties.endpoint.service_name if connection_attrs.connection_properties.endpoint.service_name
                      region connection_attrs.connection_properties.endpoint.region if connection_attrs.connection_properties.endpoint.region
                    end
                  end

                  if connection_attrs.connection_properties.cross_cluster_search
                    cross_cluster_search do
                      skip_unavailable connection_attrs.connection_properties.cross_cluster_search.skip_unavailable if connection_attrs.connection_properties.cross_cluster_search.skip_unavailable
                    end
                  end
                end
              end
            end

            OutboundConnectionReference.new(name, :aws_opensearch_outbound_connection, synthesizer, connection_attrs)
          end
        end
      end
    end
  end
end