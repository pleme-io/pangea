# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Anomaly subscription frequency
        AnomalySubscriptionFrequency = String.enum('DAILY', 'IMMEDIATE', 'WEEKLY')
        
        # Anomaly subscription threshold types
        AnomalyThresholdExpression = String.enum('AND', 'OR', 'DIMENSION', 'MATCH_OPTIONS')
        
        class AnomalySubscriptionAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name, String.constrained(format: /\A[a-zA-Z0-9\s\-_\.]{1,128}\z/)
          attribute :frequency, AnomalySubscriptionFrequency
          attribute :monitor_arn_list, Array.of(String).constrained(min_size: 1, max_size: 1024)
          attribute :subscribers, Array.of(String).constrained(min_size: 1, max_size: 1024)
          attribute :threshold_expression?, String.optional
          attribute :tags?, AwsTags.optional
          
          def subscriber_count
            subscribers.length
          end
          
          def monitor_count  
            monitor_arn_list.length
          end
          
          def is_immediate?
            frequency == 'IMMEDIATE'
          end
          
          def has_threshold?
            !threshold_expression.nil?
          end
        end
      end
    end
  end
end