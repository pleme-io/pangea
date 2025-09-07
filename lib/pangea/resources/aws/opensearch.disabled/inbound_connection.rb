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
        # OpenSearch inbound connection acceptance for cross-cluster search
        class InboundConnectionAttributes < Dry::Struct
          attribute :connection_id, Types::String
          attribute :accept_connection, Types::Bool.default(true)
        end

        # OpenSearch inbound connection reference
        class InboundConnectionReference < ::Pangea::Resources::ResourceReference
          property :id
          property :connection_id
          property :connection_status

          def accepted?
            get_attribute(:accept_connection) || false
          end

          def active?
            connection_status == 'ACTIVE'
          end

          def pending?
            connection_status == 'PENDING_ACCEPTANCE'
          end

          def rejected?
            connection_status == 'REJECTED'
          end
        end

        module InboundConnection
          # Accepts an inbound connection for cross-cluster search
          #
          # @param name [Symbol] The connection acceptance name
          # @param attributes [Hash] Connection acceptance configuration
          # @return [InboundConnectionReference] Reference to the connection acceptance
          def aws_opensearch_inbound_connection(name, attributes = {})
            connection_attrs = InboundConnectionAttributes.new(attributes)
            
            synthesizer.resource :aws_opensearch_inbound_connection, name do
              connection_id connection_attrs.connection_id
              accept_connection connection_attrs.accept_connection
            end

            InboundConnectionReference.new(name, :aws_opensearch_inbound_connection, synthesizer, connection_attrs)
          end
        end
      end
    end
  end
end