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
      module SfnExtended
        # Step Functions state machine alias for version management
        class StateMachineAliasAttributes < Dry::Struct
          attribute :name, Types::String
          attribute :state_machine_arn, Types::String
          attribute :description, Types::String.optional
          
          attribute? :routing_configuration do
            attribute :state_machine_version_arn, Types::String
            attribute :weight, Types::Integer.default(100)
          end
        end

        # Step Functions state machine alias reference
        class StateMachineAliasReference < ::Pangea::Resources::ResourceReference
          property :id
          property :arn
          property :name
          property :creation_date

          def state_machine_arn
            get_attribute(:state_machine_arn)
          end

          def routing_configuration
            get_attribute(:routing_configuration)
          end

          def routed_version_arn
            routing_configuration&.state_machine_version_arn
          end

          def routing_weight
            routing_configuration&.weight || 100
          end

          def fully_routed_to_version?
            routing_weight == 100
          end

          # Helper for execution
          def execution_arn_prefix
            arn.sub(':stateMachine:', ':execution:').sub(':alias/', ':')
          end
        end

        module StateMachineAlias
          # Creates a Step Functions state machine alias for version management
          #
          # @param name [Symbol] The alias name
          # @param attributes [Hash] Alias configuration
          # @return [StateMachineAliasReference] Reference to the alias
          def aws_sfn_state_machine_alias(name, attributes = {})
            alias_attrs = StateMachineAliasAttributes.new(attributes)
            
            synthesizer.resource :aws_sfn_state_machine_alias, name do
              name alias_attrs.name
              state_machine_arn alias_attrs.state_machine_arn
              description alias_attrs.description if alias_attrs.description
              
              if alias_attrs.routing_configuration
                routing_configuration do
                  state_machine_version_arn alias_attrs.routing_configuration.state_machine_version_arn
                  weight alias_attrs.routing_configuration.weight
                end
              end
            end

            StateMachineAliasReference.new(name, :aws_sfn_state_machine_alias, synthesizer, alias_attrs)
          end
        end
      end
    end
  end
end