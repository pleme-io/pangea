# frozen_string_literal: true

require_relative "types"

module Pangea
  module Resources
    module AwsGameliftCompute
      # Resource-specific methods for AWS GameLift Compute
      module Resource
        def self.validate(definition)
          Types::Attributes.from_dynamic(definition)
        end

        def self.defaults
          {}
        end

        def self.required_attributes
          %i[compute_name fleet_id]
        end

        def self.compute_attributes(definition)
          attrs = {
            id: ref(definition[:name], :id),
            compute_name: ref(definition[:name], :compute_name),
            compute_arn: ref(definition[:name], :compute_arn),
            fleet_id: ref(definition[:name], :fleet_id),
            fleet_arn: ref(definition[:name], :fleet_arn),
            ip_address: ref(definition[:name], :ip_address),
            dns_name: ref(definition[:name], :dns_name),
            compute_status: ref(definition[:name], :compute_status),
            location: ref(definition[:name], :location),
            creation_time: ref(definition[:name], :creation_time),
            operating_system: ref(definition[:name], :operating_system),
            type: ref(definition[:name], :type)
          }

          Types::Reference.new(attrs)
        end

        private

        def self.ref(name, attribute)
          "${aws_gamelift_compute.#{name}.#{attribute}}"
        end
      end

      # Public resource function
      def aws_gamelift_compute(name, attributes = {})
        # Apply defaults
        attributes = Resource.defaults.merge(attributes)
        
        # Validate and create resource
        validated = Resource.validate(attributes)
        
        # Create terraform resource
        resource :aws_gamelift_compute, name do
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