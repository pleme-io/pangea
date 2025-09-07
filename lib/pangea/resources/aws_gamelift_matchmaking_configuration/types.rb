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
require "pangea/types"

module Pangea
  module Resources
    module AwsGameliftMatchmakingConfiguration
      module Types
        # Game properties for matchmaking
        class GameProperty < Dry::Struct
          attribute :key, Pangea::Types::String
          attribute :value, Pangea::Types::String
        end

        # Main attributes for GameLift matchmaking configuration
        class Attributes < Dry::Struct
          # Required attributes
          attribute :name, Pangea::Types::String
          attribute :game_session_queue_arns, Pangea::Types::Array.of(Pangea::Types::String).constrained(min_size: 1)
          attribute :request_timeout_seconds, Pangea::Types::Integer.constrained(gteq: 10, lteq: 43200)
          attribute :rule_set_name, Pangea::Types::String
          
          # Optional attributes
          attribute :acceptance_required?, Pangea::Types::Bool
          attribute :acceptance_timeout_seconds?, Pangea::Types::Integer.constrained(gteq: 1, lteq: 600)
          attribute :additional_player_count?, Pangea::Types::Integer.constrained(gteq: 0)
          attribute :backfill_mode?, Pangea::Types::String.enum("AUTOMATIC", "MANUAL")
          attribute :custom_event_data?, Pangea::Types::String.constrained(max_size: 256)
          attribute :description?, Pangea::Types::String.constrained(max_size: 1024)
          attribute :flex_match_mode?, Pangea::Types::String.enum("STANDALONE", "WITH_QUEUE")
          attribute :game_properties?, Pangea::Types::Array.of(GameProperty).constrained(max_size: 16)
          attribute :game_session_data?, Pangea::Types::String.constrained(max_size: 4096)
          attribute :notification_target?, Pangea::Types::String
          attribute :tags?, Pangea::Types::Hash.map(Pangea::Types::String, Pangea::Types::String)

          def self.from_dynamic(d)
            d = Pangea::Types::Hash[d]
            
            # Validate acceptance timeout requirement
            if d[:acceptance_required] && !d[:acceptance_timeout_seconds]
              raise ArgumentError, "acceptance_timeout_seconds is required when acceptance_required is true"
            end

            new(
              name: d.fetch(:name),
              game_session_queue_arns: d.fetch(:game_session_queue_arns),
              request_timeout_seconds: d.fetch(:request_timeout_seconds),
              rule_set_name: d.fetch(:rule_set_name),
              acceptance_required: d[:acceptance_required],
              acceptance_timeout_seconds: d[:acceptance_timeout_seconds],
              additional_player_count: d[:additional_player_count],
              backfill_mode: d[:backfill_mode],
              custom_event_data: d[:custom_event_data],
              description: d[:description],
              flex_match_mode: d[:flex_match_mode],
              game_properties: d[:game_properties]&.map { |p| GameProperty.from_dynamic(p) },
              game_session_data: d[:game_session_data],
              notification_target: d[:notification_target],
              tags: d[:tags]
            )
          end
        end

        # Reference for GameLift matchmaking configuration resources
        class Reference < Dry::Struct
          attribute :arn, Pangea::Types::String
          attribute :name, Pangea::Types::String
          attribute :creation_time, Pangea::Types::String
          attribute :rule_set_arn, Pangea::Types::String
        end
      end
    end
  end
end