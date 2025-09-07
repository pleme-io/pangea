# frozen_string_literal: true

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