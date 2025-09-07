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


require_relative "types"

module Pangea
  module Resources
    module AwsGameliftGameSessionQueue
      # Resource-specific methods for AWS GameLift Game Session Queue
      module Resource
        def self.validate(definition)
          # Validate player latency policies
          if definition[:player_latency_policies]
            policies = definition[:player_latency_policies]
            policies.each_with_index do |policy, index|
              if index > 0 && !policy[:policy_duration_seconds]
                raise ArgumentError, "policy_duration_seconds is required for all player latency policies except the last one"
              end
            end
          end

          # Validate priority configuration
          if definition[:priority_configuration]
            config = definition[:priority_configuration]
            if config[:priority_order]
              valid_priorities = ["COST", "DESTINATION", "LATENCY", "LOCATION"]
              config[:priority_order].each do |priority|
                unless valid_priorities.include?(priority)
                  raise ArgumentError, "Invalid priority: #{priority}. Must be one of: #{valid_priorities.join(', ')}"
                end
              end
            end
          end

          Types::Attributes.from_dynamic(definition)
        end

        def self.defaults
          {
            timeout_in_seconds: 600  # 10 minutes default
          }
        end

        def self.required_attributes
          %i[name]
        end

        def self.compute_attributes(definition)
          attrs = {
            arn: ref(definition[:name], :arn),
            name: ref(definition[:name], :name)
          }

          Types::Reference.new(attrs)
        end

        private

        def self.ref(name, attribute)
          "${aws_gamelift_game_session_queue.#{name}.#{attribute}}"
        end
      end

      # Public resource function
      def aws_gamelift_game_session_queue(name, attributes = {})
        # Apply defaults
        attributes = Resource.defaults.merge(attributes)
        
        # Validate and create resource
        validated = Resource.validate(attributes)
        
        # Create terraform resource
        resource :aws_gamelift_game_session_queue, name do
          # Add attributes
          validated.to_h.each do |key, value|
            send(key, value) unless value.nil?
          end
        end
        
        # Return computed attributes as reference
        Resource.compute_attributes(validated.to_h.merge(name: name))
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)