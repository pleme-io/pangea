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
      # Comprehensive AWS GameLift Service Resource Functions
      # Covers multiplayer game hosting, matchmaking, and fleet management
      module GameLift
        include Dry::Types()

        # GameLift Script (Realtime Servers)
        module GameLiftScript
          class ScriptAttributes < Dry::Struct
            attribute :name, String
            attribute? :version, String
            attribute? :storage_location, Hash
            attribute? :zip_file, String
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # GameLift Matchmaking Rule Set
        module GameLiftMatchmakingRuleSet
          class RuleSetAttributes < Dry::Struct
            attribute :name, String
            attribute :rule_set_body, String
            attribute? :tags, Types::Hash.map(Types::String, Types::String)
          end
        end

        # GameLift Player Session
        module GameLiftPlayerSession
          class PlayerSessionAttributes < Dry::Struct
            attribute :game_session_id, String
            attribute :player_id, String
            attribute? :player_data, String
          end
        end

        # GameLift Game Session
        module GameLiftGameSession
          class GameSessionAttributes < Dry::Struct
            attribute? :fleet_id, String
            attribute? :alias_id, String
            attribute :maximum_player_session_count, Integer
            attribute? :name, String
            attribute? :game_properties, Array
            attribute? :creator_id, String
            attribute? :game_session_data, String
          end
        end

        # GameLift Fleet Locations
        module GameLiftFleetLocations
          class FleetLocationAttributes < Dry::Struct
            attribute :fleet_id, String
            attribute :locations, Types::Array.of(Types::String)
          end
        end

        # GameLift Fleet Capacity  
        module GameLiftFleetCapacity
          class FleetCapacityAttributes < Dry::Struct
            attribute :fleet_id, String
            attribute :desired_instances, Integer
            attribute? :location, String
          end
        end

        # GameLift Compute (Anywhere)
        module GameLiftCompute
          class ComputeAttributes < Dry::Struct
            attribute :compute_name, String
            attribute :fleet_id, String
            attribute? :ip_address, String
            attribute? :dns_name, String
            attribute? :certificate_path, String
          end
        end

        # GameLift Matchmaking Ticket
        module GameLiftMatchmakingTicket
          class TicketAttributes < Dry::Struct
            attribute :configuration_name, String
            attribute :players, Array
            attribute? :ticket_id, String
          end
        end

        # Public resource functions for GameLift
        def aws_gamelift_script(name, attributes = {})
          validated = GameLiftScript::ScriptAttributes.from_dynamic(attributes)
          
          resource :aws_gamelift_script, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_gamelift_script.#{name}.id}",
            arn: "${aws_gamelift_script.#{name}.arn}",
            name: "${aws_gamelift_script.#{name}.name}",
            creation_time: "${aws_gamelift_script.#{name}.creation_time}",
            version: "${aws_gamelift_script.#{name}.version}"
          )
        end

        def aws_gamelift_matchmaking_rule_set(name, attributes = {})
          validated = GameLiftMatchmakingRuleSet::RuleSetAttributes.from_dynamic(attributes)
          
          resource :aws_gamelift_matchmaking_rule_set, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_gamelift_matchmaking_rule_set.#{name}.id}",
            arn: "${aws_gamelift_matchmaking_rule_set.#{name}.arn}",
            name: "${aws_gamelift_matchmaking_rule_set.#{name}.name}",
            creation_time: "${aws_gamelift_matchmaking_rule_set.#{name}.creation_time}"
          )
        end

        def aws_gamelift_player_session(name, attributes = {})
          validated = GameLiftPlayerSession::PlayerSessionAttributes.from_dynamic(attributes)
          
          resource :aws_gamelift_player_session, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_gamelift_player_session.#{name}.id}",
            player_session_id: "${aws_gamelift_player_session.#{name}.player_session_id}",
            game_session_id: "${aws_gamelift_player_session.#{name}.game_session_id}",
            fleet_id: "${aws_gamelift_player_session.#{name}.fleet_id}",
            player_id: "${aws_gamelift_player_session.#{name}.player_id}",
            ip_address: "${aws_gamelift_player_session.#{name}.ip_address}",
            port: "${aws_gamelift_player_session.#{name}.port}",
            dns_name: "${aws_gamelift_player_session.#{name}.dns_name}",
            status: "${aws_gamelift_player_session.#{name}.status}"
          )
        end

        def aws_gamelift_game_session(name, attributes = {})
          validated = GameLiftGameSession::GameSessionAttributes.from_dynamic(attributes)
          
          resource :aws_gamelift_game_session, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_gamelift_game_session.#{name}.id}",
            game_session_id: "${aws_gamelift_game_session.#{name}.game_session_id}",
            arn: "${aws_gamelift_game_session.#{name}.arn}",
            fleet_id: "${aws_gamelift_game_session.#{name}.fleet_id}",
            ip_address: "${aws_gamelift_game_session.#{name}.ip_address}",
            dns_name: "${aws_gamelift_game_session.#{name}.dns_name}",
            port: "${aws_gamelift_game_session.#{name}.port}",
            status: "${aws_gamelift_game_session.#{name}.status}"
          )
        end

        def aws_gamelift_fleet_locations(name, attributes = {})
          validated = GameLiftFleetLocations::FleetLocationAttributes.from_dynamic(attributes)
          
          resource :aws_gamelift_fleet_locations, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_gamelift_fleet_locations.#{name}.id}",
            fleet_id: "${aws_gamelift_fleet_locations.#{name}.fleet_id}",
            locations: "${aws_gamelift_fleet_locations.#{name}.locations}"
          )
        end

        def aws_gamelift_fleet_capacity(name, attributes = {})
          validated = GameLiftFleetCapacity::FleetCapacityAttributes.from_dynamic(attributes)
          
          resource :aws_gamelift_fleet_capacity, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_gamelift_fleet_capacity.#{name}.id}",
            fleet_id: "${aws_gamelift_fleet_capacity.#{name}.fleet_id}",
            desired_instances: "${aws_gamelift_fleet_capacity.#{name}.desired_instances}",
            location: "${aws_gamelift_fleet_capacity.#{name}.location}"
          )
        end

        def aws_gamelift_compute(name, attributes = {})
          validated = GameLiftCompute::ComputeAttributes.from_dynamic(attributes)
          
          resource :aws_gamelift_compute, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_gamelift_compute.#{name}.id}",
            compute_name: "${aws_gamelift_compute.#{name}.compute_name}",
            compute_arn: "${aws_gamelift_compute.#{name}.compute_arn}",
            fleet_id: "${aws_gamelift_compute.#{name}.fleet_id}",
            ip_address: "${aws_gamelift_compute.#{name}.ip_address}",
            dns_name: "${aws_gamelift_compute.#{name}.dns_name}",
            compute_status: "${aws_gamelift_compute.#{name}.compute_status}"
          )
        end

        def aws_gamelift_matchmaking_ticket(name, attributes = {})
          validated = GameLiftMatchmakingTicket::TicketAttributes.from_dynamic(attributes)
          
          resource :aws_gamelift_matchmaking_ticket, name do
            validated.to_h.each { |k, v| send(k, v) unless v.nil? }
          end
          
          OpenStruct.new(
            id: "${aws_gamelift_matchmaking_ticket.#{name}.id}",
            ticket_id: "${aws_gamelift_matchmaking_ticket.#{name}.ticket_id}",
            configuration_name: "${aws_gamelift_matchmaking_ticket.#{name}.configuration_name}",
            status: "${aws_gamelift_matchmaking_ticket.#{name}.status}",
            status_reason: "${aws_gamelift_matchmaking_ticket.#{name}.status_reason}",
            start_time: "${aws_gamelift_matchmaking_ticket.#{name}.start_time}",
            end_time: "${aws_gamelift_matchmaking_ticket.#{name}.end_time}"
          )
        end
      end
    end
  end
end