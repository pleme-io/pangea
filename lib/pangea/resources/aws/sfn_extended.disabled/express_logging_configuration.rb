# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module SfnExtended
        class ExpressLoggingConfigurationAttributes < Dry::Struct
          attribute :state_machine_arn, Types::String
          attribute :log_destination, Types::String
          attribute :level, Types::String.default('ERROR')
          attribute :include_execution_data, Types::Bool.default(false)
        end

        class ExpressLoggingConfigurationReference < ::Pangea::Resources::ResourceReference
          property :id
        end

        module ExpressLoggingConfiguration
          def aws_sfn_express_logging_configuration(name, attributes = {})
            attrs = ExpressLoggingConfigurationAttributes.new(attributes)
            
            synthesizer.resource :aws_sfn_express_logging_configuration, name do
              state_machine_arn attrs.state_machine_arn
              log_destination attrs.log_destination
              level attrs.level
              include_execution_data attrs.include_execution_data
            end

            ExpressLoggingConfigurationReference.new(name, :aws_sfn_express_logging_configuration, synthesizer, attrs)
          end
        end
      end
    end
  end
end