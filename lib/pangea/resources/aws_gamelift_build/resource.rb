# frozen_string_literal: true

require_relative "types"

module Pangea
  module Resources
    module AwsGameliftBuild
      # Resource-specific methods for AWS GameLift Build
      module Resource
        def self.validate(definition)
          # Validate storage location
          storage = definition[:storage_location]
          if storage
            unless storage[:bucket] && storage[:key] && storage[:role_arn]
              raise ArgumentError, "storage_location must include bucket, key, and role_arn"
            end
          end

          Types::Attributes.from_dynamic(definition)
        end

        def self.defaults
          {
            operating_system: "AMAZON_LINUX_2"
          }
        end

        def self.required_attributes
          %i[name operating_system storage_location]
        end

        def self.compute_attributes(definition)
          attrs = {
            id: ref(definition[:name], :id),
            arn: ref(definition[:name], :arn),
            creation_time: ref(definition[:name], :creation_time),
            size_on_disk: ref(definition[:name], :size_on_disk),
            status: ref(definition[:name], :status)
          }

          Types::Reference.new(attrs)
        end

        private

        def self.ref(name, attribute)
          "${aws_gamelift_build.#{name}.#{attribute}}"
        end
      end

      # Public resource function
      def aws_gamelift_build(name, attributes = {})
        # Apply defaults
        attributes = Resource.defaults.merge(attributes)
        
        # Validate and create resource
        validated = Resource.validate(attributes)
        
        # Create terraform resource
        resource :aws_gamelift_build, name do
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