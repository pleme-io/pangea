# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module SfnExtended
        class StateMachineVersionAttributes < Dry::Struct
          attribute :state_machine_arn, Types::String
          attribute :description, Types::String.optional
        end

        class StateMachineVersionReference < ::Pangea::Resources::ResourceReference
          property :id
          property :arn
          property :version
        end

        module StateMachineVersion
          def aws_sfn_state_machine_version(name, attributes = {})
            attrs = StateMachineVersionAttributes.new(attributes)
            
            synthesizer.resource :aws_sfn_state_machine_version, name do
              state_machine_arn attrs.state_machine_arn
              description attrs.description if attrs.description
            end

            StateMachineVersionReference.new(name, :aws_sfn_state_machine_version, synthesizer, attrs)
          end
        end
      end
    end
  end
end