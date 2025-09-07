# frozen_string_literal: true

require "dry-struct"

module Pangea
  module Resources
    module AwsGameliftPlayerSession
      module Types
        include Dry::Types()

        class Attributes < Dry::Struct
          attribute :game_session_id, String
          attribute :player_id, String
          attribute? :player_data, String
        end

        class Reference < Dry::Struct
          attribute :id, String
          attribute :player_session_id, String
          attribute :game_session_id, String
          attribute :fleet_id, String
          attribute :fleet_arn, String
          attribute :player_id, String
          attribute :ip_address, String
          attribute :port, Integer
          attribute :dns_name, String
          attribute :status, String
          attribute :creation_time, String
          attribute :termination_time, String
        end
      end
    end
  end
end