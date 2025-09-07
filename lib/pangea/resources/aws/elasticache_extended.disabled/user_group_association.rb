# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module ElastiCacheExtended
        class UserGroupAssociationAttributes < Dry::Struct
          attribute :user_group_id, Types::String
          attribute :user_id, Types::String
        end

        class UserGroupAssociationReference < ::Pangea::Resources::ResourceReference
          property :id
        end

        module UserGroupAssociation
          def aws_elasticache_user_group_association(name, attributes = {})
            attrs = UserGroupAssociationAttributes.new(attributes)
            
            synthesizer.resource :aws_elasticache_user_group_association, name do
              user_group_id attrs.user_group_id
              user_id attrs.user_id
            end

            UserGroupAssociationReference.new(name, :aws_elasticache_user_group_association, synthesizer, attrs)
          end
        end
      end
    end
  end
end