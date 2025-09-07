# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      class IotDeviceDefenderSecurityProfileAttributes < Dry::Struct
        attribute :security_profile_name, Resources::Types::IotSecurityProfileName
        attribute :security_profile_description, Resources::Types::String.optional
        attribute :behaviors, Resources::Types::Array.of(Types::Hash).default([])
        attribute :alert_targets, Resources::Types::Hash.optional
        attribute :target_arns, Resources::Types::Array.of(Types::String).default([])
        attribute :tags, Resources::Types::AwsTags.default({})
        
        def target_count
          target_arns.length
        end
        
        def behavior_count
          behaviors.length
        end
        
        def has_ml_behaviors?
          behaviors.any? { |b| b.dig(:criteria, :ml_detection_config) }
        end
        
        def defender_coverage_level
          if behavior_count >= 5 && has_ml_behaviors?
            'comprehensive'
          elsif behavior_count >= 3
            'standard'
          elsif behavior_count >= 1
            'basic'
          else
            'minimal'
          end
        end
      end
    end
  end
end