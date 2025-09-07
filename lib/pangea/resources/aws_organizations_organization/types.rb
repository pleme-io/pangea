# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        class OrganizationsOrganizationAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :aws_service_access_principals, Resources::Types::Array.optional.default([])
          attribute :enabled_policy_types, Resources::Types::Array.optional.default([])
          attribute :feature_set, Resources::Types::String.default("ALL")
          
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            if attrs[:feature_set]
              valid_features = ["ALL", "CONSOLIDATED_BILLING"]
              unless valid_features.include?(attrs[:feature_set])
                raise Dry::Struct::Error, "feature_set must be ALL or CONSOLIDATED_BILLING"
              end
            end
            
            super(attrs)
          end
          
          def has_all_features?
            feature_set == "ALL"
          end
          
          def has_service_access_principals?
            !aws_service_access_principals.empty?
          end
          
          def has_enabled_policy_types?
            !enabled_policy_types.empty?
          end
          
          def estimated_monthly_cost_usd
            # Organizations is free, but consider governance costs
            base_cost = 0.0
            
            # Service access principals may incur service costs
            service_cost = aws_service_access_principals.length * 0.50
            
            base_cost + service_cost
          end
          
          def to_h
            {
              aws_service_access_principals: aws_service_access_principals,
              enabled_policy_types: enabled_policy_types,
              feature_set: feature_set
            }.compact
          end
        end
      end
    end
  end
end