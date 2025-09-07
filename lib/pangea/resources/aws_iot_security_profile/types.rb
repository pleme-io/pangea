# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      class IotSecurityProfileAttributes < Dry::Struct
        attribute :security_profile_name, Resources::Types::IotSecurityProfileName
        attribute :security_profile_description, Resources::Types::String.optional
        attribute :behaviors, Resources::Types::Array.of(Types::Hash).default([])
        attribute :alert_targets, Resources::Types::Hash.optional
        attributeadditional_metrics_to_retain_v2 :, Resources::Types::Array.of(Types::Hash).optional
        attribute :tags, Resources::Types::AwsTags.default({})
        
        def behavior_count
          behaviors.length
        end
        
        def has_alert_targets?
          !alert_targets.nil? && alert_targets.any?
        end
        
        def metric_count
          additional_metrics_to_retain_v2&.length || 0
        end
        
        def security_coverage_score
          # Calculate coverage based on behaviors and metrics
          base_score = [behavior_count * 10, 100].min
          alert_bonus = has_alert_targets? ? 20 : 0
          metric_bonus = [metric_count * 5, 30].min
          
          [base_score + alert_bonus + metric_bonus, 100].min
        end
      end
    end
  end
end