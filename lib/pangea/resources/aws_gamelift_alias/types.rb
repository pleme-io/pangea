# frozen_string_literal: true

require "dry-struct"
require "pangea/types"

module Pangea
  module Resources
    module AwsGameliftAlias
      module Types
        # Routing strategy for the alias
        class RoutingStrategy < Dry::Struct
          attribute :type, Pangea::Types::String.enum("SIMPLE", "TERMINAL")
          attribute :fleet_id?, Pangea::Types::String
          attribute :message?, Pangea::Types::String

          def self.from_dynamic(d)
            d = Pangea::Types::Hash[d]
            
            # Validate based on type
            case d[:type]
            when "SIMPLE"
              unless d[:fleet_id]
                raise ArgumentError, "fleet_id is required when routing_strategy type is SIMPLE"
              end
            when "TERMINAL"
              unless d[:message]
                raise ArgumentError, "message is required when routing_strategy type is TERMINAL"
              end
            end

            new(
              type: d.fetch(:type),
              fleet_id: d[:fleet_id],
              message: d[:message]
            )
          end
        end

        # Main attributes for GameLift alias
        class Attributes < Dry::Struct
          # Required attributes
          attribute :name, Pangea::Types::String
          attribute :description, Pangea::Types::String
          attribute :routing_strategy, RoutingStrategy
          
          # Optional attributes
          attribute :tags?, Pangea::Types::Hash.map(Pangea::Types::String, Pangea::Types::String)

          def self.from_dynamic(d)
            d = Pangea::Types::Hash[d]
            new(
              name: d.fetch(:name),
              description: d.fetch(:description),
              routing_strategy: RoutingStrategy.from_dynamic(d.fetch(:routing_strategy)),
              tags: d[:tags]
            )
          end
        end

        # Reference for GameLift alias resources
        class Reference < Dry::Struct
          attribute :id, Pangea::Types::String
          attribute :arn, Pangea::Types::String
          attribute :creation_time, Pangea::Types::String
          attribute :last_updated_time, Pangea::Types::String
        end
      end
    end
  end
end