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
    module AwsGameliftGameSession
      # Resource-specific methods for AWS GameLift Game Session
      module Resource
        def self.validate(definition)
          # Must have either fleet_id or alias_id
          unless definition[:fleet_id] || definition[:alias_id]
            raise ArgumentError, "Either fleet_id or alias_id must be specified for GameLift game session"
          end

          # Both cannot be specified
          if definition[:fleet_id] && definition[:alias_id]
            raise ArgumentError, "Cannot specify both fleet_id and alias_id for GameLift game session"
          end

          # Validate maximum_player_session_count
          if definition[:maximum_player_session_count] && definition[:maximum_player_session_count] <= 0
            raise ArgumentError, "maximum_player_session_count must be greater than 0"
          end

          Types::Attributes.from_dynamic(definition)
        end

        def self.defaults
          {
            maximum_player_session_count: 10
          }
        end

        def self.required_attributes
          %i[maximum_player_session_count]
        end

        def self.compute_attributes(definition)
          attrs = {
            id: ref(definition[:name], :id),
            game_session_id: ref(definition[:name], :game_session_id),
            arn: ref(definition[:name], :arn),
            name: ref(definition[:name], :name),
            fleet_id: ref(definition[:name], :fleet_id),
            fleet_arn: ref(definition[:name], :fleet_arn),
            creation_time: ref(definition[:name], :creation_time),
            termination_time: ref(definition[:name], :termination_time),
            current_player_session_count: ref(definition[:name], :current_player_session_count),
            maximum_player_session_count: ref(definition[:name], :maximum_player_session_count),
            status: ref(definition[:name], :status),
            status_reason: ref(definition[:name], :status_reason),
            ip_address: ref(definition[:name], :ip_address),
            dns_name: ref(definition[:name], :dns_name),
            port: ref(definition[:name], :port),
            player_session_creation_policy: ref(definition[:name], :player_session_creation_policy)
          }

          Types::Reference.new(attrs)
        end

        private

        def self.ref(name, attribute)
          "${aws_gamelift_game_session.#{name}.#{attribute}}"
        end
      end

      # Public resource function
      def aws_gamelift_game_session(name, attributes = {})
        # Apply defaults
        attributes = Resource.defaults.merge(attributes)
        
        # Validate and create resource
        validated = Resource.validate(attributes)
        
        # Create terraform resource
        resource :aws_gamelift_game_session, name do
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