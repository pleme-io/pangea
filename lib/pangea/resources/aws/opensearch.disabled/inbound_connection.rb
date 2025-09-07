# frozen_string_literal: true

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