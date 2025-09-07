# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsLbCookieStickinessPolicy resources
      # Manages aws lb cookie stickiness policy resources.
      class AwsLbCookieStickinessPolicyAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_lb_cookie_stickiness_policy
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_lb_cookie_stickiness_policy
      end
    end
      end
    end
  end
end