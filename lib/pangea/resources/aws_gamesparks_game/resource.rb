# frozen_string_literal: true

require_relative "types"

module Pangea
  module Resources
    module AwsGamesparksGame
      # Resource-specific methods for AWS GameSparks Game
      module Resource
        def self.validate(definition)
          Types::Attributes.from_dynamic(definition)
        end

        def self.defaults
          {}
        end

        def self.required_attributes
          %i[name]
        end

        def self.compute_attributes(definition)
          attrs = {
            id: ref(definition[:name], :id),
            arn: ref(definition[:name], :arn),
            name: ref(definition[:name], :name),
            description: ref(definition[:name], :description),
            state: ref(definition[:name], :state),
            created_time: ref(definition[:name], :created_time),
            last_updated_time: ref(definition[:name], :last_updated_time),
            game_sdk_version: ref(definition[:name], :game_sdk_version)
          }

          Types::Reference.new(attrs)
        end

        private

        def self.ref(name, attribute)
          "${aws_gamesparks_game.#{name}.#{attribute}}"
        end
      end

      # Public resource function
      def aws_gamesparks_game(name, attributes = {})
        # Apply defaults
        attributes = Resource.defaults.merge(attributes)
        
        # Validate and create resource
        validated = Resource.validate(attributes)
        
        # Create terraform resource
        resource :aws_gamesparks_game, name do
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