# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS API Gateway Usage Plan resources
      class ApiGatewayUsagePlanAttributes < Dry::Struct
        # Name for the usage plan
        attribute :name, Resources::Types::String

        # Description of the usage plan
        attribute :description, Resources::Types::String.optional

        # API stages this usage plan applies to
        attribute :api_stages, Resources::Types::Array.of(
          Types::Hash.schema(
            api_id: Types::String,
            stage: Types::String,
            throttle?: Types::Hash.schema(
              path?: Types::String.optional,
              burst_limit?: Types::Integer.optional,
              rate_limit?: Types::Coercible::Float.optional
            ).optional
          )
        ).default([].freeze)

        # Throttling settings
        attribute :throttle_settings, Resources::Types::Hash.schema(
          burst_limit?: Types::Integer.optional,
          rate_limit?: Types::Coercible::Float.optional
        ).optional

        # Quota settings
        attribute :quota_settings, Resources::Types::Hash.schema(
          limit: Types::Integer,
          offset?: Types::Integer.optional,
          period: Types::String.enum('DAY', 'WEEK', 'MONTH')
        ).optional

        # Product code for billing
        attribute :product_code, Resources::Types::String.optional

        # Tags to apply to the usage plan
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate name format
          unless attrs.name.match?(/\A[a-zA-Z0-9\-_\s]{1,255}\z/)
            raise Dry::Struct::Error, "Usage plan name must be 1-255 characters"
          end

          # Validate API stages
          attrs.api_stages.each do |stage|
            unless stage[:api_id].match?(/\A[a-z0-9]{10}\z/)
              raise Dry::Struct::Error, "Invalid API ID format: #{stage[:api_id]}"
            end
            
            unless stage[:stage].match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)
              raise Dry::Struct::Error, "Invalid stage name: #{stage[:stage]}"
            end
          end

          # Validate throttle settings
          if attrs.throttle_settings
            if attrs.throttle_settings[:burst_limit] && attrs.throttle_settings[:burst_limit] <= 0
              raise Dry::Struct::Error, "Burst limit must be positive"
            end
            
            if attrs.throttle_settings[:rate_limit] && attrs.throttle_settings[:rate_limit] <= 0
              raise Dry::Struct::Error, "Rate limit must be positive"
            end
          end

          # Validate quota settings
          if attrs.quota_settings
            if attrs.quota_settings[:limit] <= 0
              raise Dry::Struct::Error, "Quota limit must be positive"
            end
            
            if attrs.quota_settings[:offset] && attrs.quota_settings[:offset] < 0
              raise Dry::Struct::Error, "Quota offset cannot be negative"
            end
          end

          # Set default description if not provided
          unless attrs.description
            plan_type = attrs.quota_settings ? "Quota-based" : "Throttle-only"
            attrs = attrs.copy_with(description: "#{plan_type} usage plan for #{attrs.name}")
          end

          attrs
        end

        # Helper methods
        def api_count
          api_stages.length
        end

        def has_throttling?
          !!throttle_settings
        end

        def has_quota?
          !!quota_settings
        end

        def quota_period
          quota_settings&.[](:period)&.downcase
        end

        def daily_quota?
          quota_period == 'day'
        end

        def monthly_quota?
          quota_period == 'month'
        end

        def estimated_monthly_cost
          base_cost = "$3.50 per million requests"
          quota_cost = has_quota? ? " + quota management" : ""
          "#{base_cost}#{quota_cost}"
        end

        def validate_configuration
          warnings = []
          
          if api_stages.empty?
            warnings << "Usage plan has no API stages - it won't apply to any APIs"
          end
          
          if !has_throttling? && !has_quota?
            warnings << "Usage plan has no throttling or quota - consider adding limits"
          end
          
          if throttle_settings && throttle_settings[:rate_limit] && throttle_settings[:rate_limit] < 1
            warnings << "Very low rate limit may cause service disruption"
          end
          
          if quota_settings && quota_settings[:limit] < 1000
            warnings << "Very low quota limit may impact user experience"
          end
          
          warnings
        end

        # Get plan strictness level
        def strictness_level
          return "none" unless has_throttling? || has_quota?
          return "high" if has_throttling? && has_quota?
          return "medium" if has_quota?
          "low"
        end

        # Check if suitable for production
        def production_ready?
          has_throttling? || has_quota?
        end

        # Get protection level
        def protection_level
          case strictness_level
          when "high"
            "comprehensive"
          when "medium"
            "quota_only"
          when "low"
            "throttle_only"
          else
            "unprotected"
          end
        end
      end

      # Common API Gateway usage plan configurations
      module ApiGatewayUsagePlanConfigs
        # Basic usage plan with throttling only
        def self.basic_throttle_plan(plan_name, api_id, stage_name, rate_limit: 1000, burst_limit: 2000)
          {
            name: plan_name,
            description: "Basic throttling plan for #{stage_name}",
            api_stages: [
              {
                api_id: api_id,
                stage: stage_name
              }
            ],
            throttle_settings: {
              rate_limit: rate_limit,
              burst_limit: burst_limit
            }
          }
        end

        # Standard quota-based plan
        def self.quota_plan(plan_name, api_id, stage_name, daily_limit: 10000)
          {
            name: plan_name,
            description: "Quota-based usage plan for #{stage_name}",
            api_stages: [
              {
                api_id: api_id,
                stage: stage_name
              }
            ],
            quota_settings: {
              limit: daily_limit,
              period: 'DAY'
            }
          }
        end

        # Premium plan with both throttling and quota
        def self.premium_plan(plan_name, api_id, stage_name, monthly_quota: 1000000, rate_limit: 5000)
          {
            name: plan_name,
            description: "Premium usage plan with high limits",
            api_stages: [
              {
                api_id: api_id,
                stage: stage_name
              }
            ],
            throttle_settings: {
              rate_limit: rate_limit,
              burst_limit: rate_limit * 2
            },
            quota_settings: {
              limit: monthly_quota,
              period: 'MONTH'
            }
          }
        end

        # Development plan with generous limits
        def self.development_plan(plan_name, api_id, stage_name)
          {
            name: plan_name,
            description: "Development usage plan with generous limits",
            api_stages: [
              {
                api_id: api_id,
                stage: stage_name
              }
            ],
            throttle_settings: {
              rate_limit: 10000,
              burst_limit: 20000
            },
            quota_settings: {
              limit: 1000000,
              period: 'MONTH'
            },
            tags: {
              Environment: "development",
              Purpose: "API development and testing"
            }
          }
        end

        # Corporate enterprise plan
        def self.enterprise_plan(plan_name, api_id, stage_name, organization)
          {
            name: plan_name,
            description: "Enterprise usage plan for #{organization}",
            api_stages: [
              {
                api_id: api_id,
                stage: stage_name
              }
            ],
            throttle_settings: {
              rate_limit: 50000,
              burst_limit: 100000
            },
            quota_settings: {
              limit: 10000000,
              period: 'MONTH'
            },
            tags: {
              Organization: organization,
              PlanType: "enterprise",
              SupportLevel: "premium"
            }
          }
        end
      end
    end
      end
    end
  end
end