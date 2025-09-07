# frozen_string_literal: true

require_relative "types"

module Pangea
  module Resources
    module AwsMobileAnalyticsApp
      # Resource-specific methods for AWS Mobile Analytics App
      # Note: This service is deprecated - use Amazon Pinpoint instead
      module Resource
        def self.validate(definition)
          warn "WARNING: AWS Mobile Analytics is deprecated. Consider using aws_pinpoint_app instead."
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
            id: ref(definition[:name], :id)
          }

          Types::Reference.new(attrs)
        end

        private

        def self.ref(name, attribute)
          "${aws_mobile_analytics_app.#{name}.#{attribute}}"
        end
      end

      # Public resource function
      def aws_mobile_analytics_app(name, attributes = {})
        # Apply defaults
        attributes = Resource.defaults.merge(attributes)
        
        # Validate and create resource
        validated = Resource.validate(attributes)
        
        # Create terraform resource
        resource :aws_mobile_analytics_app, name do
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