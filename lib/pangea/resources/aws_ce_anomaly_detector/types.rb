# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Anomaly detector types
        AnomalyDetectorType = String.enum('DIMENSIONAL', 'SERVICE')
        
        # Anomaly monitor types  
        AnomalyMonitorType = String.enum('DIMENSIONAL', 'CUSTOM')
        
        # Frequency for anomaly detection
        AnomalyDetectorFrequency = String.enum('DAILY', 'IMMEDIATE')
        
        # Dimension key for anomaly detection
        AnomalyDimensionKey = String.enum(
          'AZ', 'INSTANCE_TYPE', 'LINKED_ACCOUNT', 'OPERATION', 'PURCHASE_TYPE',
          'REGION', 'SERVICE', 'USAGE_TYPE', 'USAGE_TYPE_GROUP', 'RECORD_TYPE',
          'OPERATING_SYSTEM', 'TENANCY', 'SCOPE', 'PLATFORM', 'SUBSCRIPTION_ID',
          'LEGAL_ENTITY_NAME', 'DEPLOYMENT_OPTION', 'DATABASE_ENGINE', 'CACHE_ENGINE',
          'INSTANCE_TYPE_FAMILY', 'BILLING_ENTITY', 'RESERVATION_ID', 'RESOURCE_ID',
          'RIGHTSIZING_TYPE', 'SAVINGS_PLANS_TYPE', 'SAVINGS_PLAN_ARN', 'PAYMENT_OPTION'
        )
        
        # Anomaly detector resource attributes
        class AnomalyDetectorAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name, String.constrained(format: /\A[a-zA-Z0-9\s\-_\.]{1,128}\z/)
          attribute :monitor_type, AnomalyMonitorType
          attribute :monitor_specification?, String.optional  # JSON specification for CUSTOM monitors
          
          attribute :dimension_key?, AnomalyDimensionKey.optional
          attribute :match_options?, Array.of(String).optional
          attribute :dimension_values?, Array.of(String).optional
          
          attribute :tags?, AwsTags.optional
          
          def is_service_monitor?
            monitor_type == 'SERVICE'  
          end
          
          def is_dimensional_monitor?
            monitor_type == 'DIMENSIONAL'
          end
          
          def has_custom_specification?
            !monitor_specification.nil?
          end
        end
      end
    end
  end
end