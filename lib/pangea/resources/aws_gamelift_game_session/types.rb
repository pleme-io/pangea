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
    module AwsGameliftGameSession
      module Types
        include Dry::Types()

        class GameProperty < Dry::Struct
          attribute :key, String
          attribute :value, String
        end

        class Attributes < Dry::Struct
          attribute? :fleet_id, String
          attribute? :alias_id, String
          attribute :maximum_player_session_count, Integer
          attribute? :name, String
          attribute? :game_properties, Array.of(GameProperty)
          attribute? :creator_id, String
          attribute? :game_session_data, String
          attribute? :idempotency_token, String
        end

        class Reference < Dry::Struct
          attribute :id, String
          attribute :game_session_id, String
          attribute :arn, String
          attribute :name, String
          attribute :fleet_id, String
          attribute :fleet_arn, String
          attribute :creation_time, String
          attribute :termination_time, String
          attribute :current_player_session_count, Integer
          attribute :maximum_player_session_count, Integer
          attribute :status, String
          attribute :status_reason, String
          attribute :ip_address, String
          attribute :dns_name, String
          attribute :port, Integer
          attribute :player_session_creation_policy, String
        end
      end
    end
  end
end