# frozen_string_literal: true

require "dry-struct"

module Pangea
  module Resources
    module AwsGamesparksGame
      module Types
        include Dry::Types()

        class Attributes < Dry::Struct
          attribute :name, String
          attribute? :description, String
          attribute? :tags, Hash.map(String, String)
        end

        class Reference < Dry::Struct
          attribute :id, String
          attribute :arn, String
          attribute :name, String
          attribute :description, String
          attribute :state, String
          attribute :created_time, String
          attribute :last_updated_time, String
          attribute :game_sdk_version, String
        end
      end
    end
  end
end