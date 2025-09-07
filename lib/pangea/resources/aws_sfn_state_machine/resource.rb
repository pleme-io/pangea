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


require 'pangea/resources/base'
require_relative 'types'

module Pangea
  module Resources
    module AWS
      # AWS Step Functions State Machine implementation
      # Provides type-safe function for creating state machines
      def aws_sfn_state_machine(name, attributes = {})
        # Validate attributes using dry-struct
        validated_attrs = Types::Types::SfnStateMachineAttributes.new(attributes)
        
        # Create reference that will be returned
        ref = ResourceReference.new(
          type: 'aws_sfn_state_machine',
          name: name,
          resource_attributes: validated_attrs.to_h,
          outputs: {
            id: "${aws_sfn_state_machine.#{name}.id}",
            arn: "${aws_sfn_state_machine.#{name}.arn}",
            name: "${aws_sfn_state_machine.#{name}.name}",
            creation_date: "${aws_sfn_state_machine.#{name}.creation_date}",
            status: "${aws_sfn_state_machine.#{name}.status}",
            tags_all: "${aws_sfn_state_machine.#{name}.tags_all}"
          }
        )
        
        # Synthesize the Terraform resource
        resource :aws_sfn_state_machine, name do
          name validated_attrs.name
          definition validated_attrs.definition
          role_arn validated_attrs.role_arn
          type validated_attrs.type if validated_attrs.type
          
          # Optional logging configuration
          if validated_attrs.logging_configuration
            logging_configuration do
              level validated_attrs.logging_configuration[:level] if validated_attrs.logging_configuration[:level]
              include_execution_data validated_attrs.logging_configuration[:include_execution_data] if validated_attrs.logging_configuration.key?(:include_execution_data)
              
              if validated_attrs.logging_configuration[:destinations]
                validated_attrs.logging_configuration[:destinations].each do |destination|
                  destination do
                    if destination[:cloud_watch_logs_log_group]
                      cloud_watch_logs_log_group do
                        log_group_arn destination[:cloud_watch_logs_log_group][:log_group_arn]
                      end
                    end
                  end
                end
              end
            end
          end
          
          # Optional tracing configuration
          if validated_attrs.tracing_configuration
            tracing_configuration do
              enabled validated_attrs.tracing_configuration[:enabled] if validated_attrs.tracing_configuration.key?(:enabled)
            end
          end
          
          # Tags
          if validated_attrs.tags
            tags validated_attrs.tags
          end
        end
        
        # Return the reference
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)