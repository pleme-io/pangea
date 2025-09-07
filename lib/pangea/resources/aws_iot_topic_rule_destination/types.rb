# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      class IotTopicRuleDestinationAttributes < Dry::Struct
        attribute :enabled, Resources::Types::Bool.default(true)
        attribute :vpc_configuration, Resources::Types::Hash.schema(
          subnet_ids: Types::Array.of(Types::String),
          security_group_ids: Types::Array.of(Types::String),
          vpc_id: Types::String,
          role_arn: Types::String
        )
        attribute :tags, Resources::Types::AwsTags.default({})
        
        def vpc_subnet_count
          vpc_configuration[:subnet_ids].length
        end
        
        def security_group_count
          vpc_configuration[:security_group_ids].length
        end
        
        def is_multi_az?
          vpc_subnet_count > 1
        end
      end
    end
  end
end