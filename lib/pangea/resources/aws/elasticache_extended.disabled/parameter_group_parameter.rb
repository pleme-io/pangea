# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module ElastiCacheExtended
        class ParameterGroupParameterAttributes < Dry::Struct
          attribute :cache_parameter_group_name, Types::String
          attribute :parameter_name, Types::String
          attribute :parameter_value, Types::String
        end

        class ParameterGroupParameterReference < ::Pangea::Resources::ResourceReference
          property :id
        end

        module ParameterGroupParameter
          def aws_elasticache_parameter_group_parameter(name, attributes = {})
            attrs = ParameterGroupParameterAttributes.new(attributes)
            
            synthesizer.resource :aws_elasticache_parameter_group_parameter, name do
              cache_parameter_group_name attrs.cache_parameter_group_name
              parameter_name attrs.parameter_name
              parameter_value attrs.parameter_value
            end

            ParameterGroupParameterReference.new(name, :aws_elasticache_parameter_group_parameter, synthesizer, attrs)
          end
        end
      end
    end
  end
end