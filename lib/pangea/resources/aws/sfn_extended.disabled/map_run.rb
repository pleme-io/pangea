# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module SfnExtended
        class MapRunAttributes < Dry::Struct
          attribute :execution_arn, Types::String
          attribute :max_concurrency, Types::Integer.default(0)
        end

        class MapRunReference < ::Pangea::Resources::ResourceReference
          property :id
          property :arn
        end

        module MapRun
          def aws_sfn_map_run(name, attributes = {})
            attrs = MapRunAttributes.new(attributes)
            
            synthesizer.resource :aws_sfn_map_run, name do
              execution_arn attrs.execution_arn
              max_concurrency attrs.max_concurrency
            end

            MapRunReference.new(name, :aws_sfn_map_run, synthesizer, attrs)
          end
        end
      end
    end
  end
end