# frozen_string_literal: true

require_relative "types"

module Pangea
  module Resources
    module AwsGameliftMatchmakingRuleSet
      # Resource-specific methods for AWS GameLift Matchmaking Rule Set
      module Resource
        def self.validate(definition)
          # Validate rule_set_body is valid JSON
          if definition[:rule_set_body]
            begin
              JSON.parse(definition[:rule_set_body])
            rescue JSON::ParserError
              raise ArgumentError, "rule_set_body must be valid JSON"
            end
          end

          Types::Attributes.from_dynamic(definition)
        end

        def self.defaults
          {}
        end

        def self.required_attributes
          %i[name rule_set_body]
        end

        def self.compute_attributes(definition)
          attrs = {
            id: ref(definition[:name], :id),
            arn: ref(definition[:name], :arn),
            name: ref(definition[:name], :name),
            creation_time: ref(definition[:name], :creation_time),
            rule_set_body: ref(definition[:name], :rule_set_body)
          }

          Types::Reference.new(attrs)
        end

        private

        def self.ref(name, attribute)
          "${aws_gamelift_matchmaking_rule_set.#{name}.#{attribute}}"
        end
      end

      # Public resource function
      def aws_gamelift_matchmaking_rule_set(name, attributes = {})
        # Apply defaults
        attributes = Resource.defaults.merge(attributes)
        
        # Validate and create resource
        validated = Resource.validate(attributes)
        
        # Create terraform resource
        resource :aws_gamelift_matchmaking_rule_set, name do
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