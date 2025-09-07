# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module ElastiCacheExtended
        class AuthTokenAttributes < Dry::Struct
          attribute :replication_group_id, Types::String
          attribute :auth_token, Types::String
        end

        class AuthTokenReference < ::Pangea::Resources::ResourceReference
          property :id
        end

        module AuthToken
          def aws_elasticache_auth_token(name, attributes = {})
            attrs = AuthTokenAttributes.new(attributes)
            
            synthesizer.resource :aws_elasticache_auth_token, name do
              replication_group_id attrs.replication_group_id
              auth_token attrs.auth_token
            end

            AuthTokenReference.new(name, :aws_elasticache_auth_token, synthesizer, attrs)
          end
        end
      end
    end
  end
end