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

require "dry-struct"

module Pangea
  module Resources
    module AWS
      module GameLift
        # GameLift Script (Realtime Servers)
        module GameLiftScript
          class ScriptAttributes < Dry::Struct
            attribute :name, Types::String
            attribute? :version, Types::String
            attribute? :storage_location, Types::Hash
            attribute? :zip_file, Types::String
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # GameLift Matchmaking Rule Set
        module GameLiftMatchmakingRuleSet
          class RuleSetAttributes < Dry::Struct
            attribute :name, Types::String
            attribute :rule_set_body, Types::String
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # GameLift Player Session
        module GameLiftPlayerSession
          class PlayerSessionAttributes < Dry::Struct
            attribute :game_session_id, Types::String
            attribute :player_id, Types::String
            attribute? :player_data, Types::String
          end
        end

        # GameLift Game Session
        module GameLiftGameSession
          class GameSessionAttributes < Dry::Struct
            attribute? :fleet_id, Types::String
            attribute? :alias_id, Types::String
            attribute :maximum_player_session_count, Types::Integer
            attribute? :name, Types::String
            attribute? :game_properties, Types::Array
            attribute? :creator_id, Types::String
            attribute? :game_session_data, Types::String
          end
        end

        # GameLift Fleet Locations
        module GameLiftFleetLocations
          class FleetLocationAttributes < Dry::Struct
            attribute :fleet_id, Types::String
            attribute :locations, Types::Array.of(Types::String)
          end
        end

        # GameLift Fleet Capacity
        module GameLiftFleetCapacity
          class FleetCapacityAttributes < Dry::Struct
            attribute :fleet_id, Types::String
            attribute :desired_instances, Types::Integer
            attribute? :location, Types::String
          end
        end

        # GameLift Compute (Anywhere)
        module GameLiftCompute
          class ComputeAttributes < Dry::Struct
            attribute :compute_name, Types::String
            attribute :fleet_id, Types::String
            attribute? :ip_address, Types::String
            attribute? :dns_name, Types::String
            attribute? :certificate_path, Types::String
          end
        end

        # GameLift Matchmaking Ticket
        module GameLiftMatchmakingTicket
          class TicketAttributes < Dry::Struct
            attribute :configuration_name, Types::String
            attribute :players, Types::Array
            attribute? :ticket_id, Types::String
          end
        end
      end
    end
  end
end
