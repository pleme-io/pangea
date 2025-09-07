# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module SfnExtended
        class ExecutionAttributes < Dry::Struct
          attribute :state_machine_arn, Types::String
          attribute :name, Types::String.optional
          attribute :input, Types::String.optional
        end

        class ExecutionReference < ::Pangea::Resources::ResourceReference
          property :id
          property :arn
        end

        module Execution
          def aws_sfn_execution(name, attributes = {})
            attrs = ExecutionAttributes.new(attributes)
            
            synthesizer.resource :aws_sfn_execution, name do
              state_machine_arn attrs.state_machine_arn
              name attrs.name if attrs.name
              input attrs.input if attrs.input
            end

            ExecutionReference.new(name, :aws_sfn_execution, synthesizer, attrs)
          end
        end
      end
    end
  end
end