# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module RdsClusterInstanceMethods
          def is_serverless? = instance_class == 'serverless'
          def is_burstable? = instance_class.include?('t3') || instance_class.include?('t4g')
          def is_memory_optimized? = instance_class.include?('r5') || instance_class.include?('r6') || instance_class.include?('x2g')
          def is_graviton? = instance_class.include?('t4g') || instance_class.include?('r6g') || instance_class.include?('x2g')
          def has_enhanced_monitoring? = monitoring_interval.positive?
          def has_performance_insights? = performance_insights_enabled
          def can_be_writer? = promotion_tier.zero?
          def is_likely_reader? = promotion_tier.positive?
          def supports_performance_insights? = !is_serverless?
          def supports_enhanced_monitoring? = !is_serverless?

          def instance_family
            return 'serverless' if is_serverless?
            case instance_class
            when /^db\.t3/ then 't3'
            when /^db\.t4g/ then 't4g'
            when /^db\.r5/ then 'r5'
            when /^db\.r6g/ then 'r6g'
            when /^db\.r6i/ then 'r6i'
            when /^db\.x2g/ then 'x2g'
            else 'unknown'
            end
          end

          def instance_size
            return 'serverless' if is_serverless?
            parts = instance_class.split('.')
            parts.last if parts.length >= 3
          end

          def role_description
            case promotion_tier
            when 0 then 'Primary writer instance'
            when 1 then 'Primary failover target'
            else "Reader instance (tier #{promotion_tier})"
            end
          end

          def estimated_vcpus
            return 'variable' if is_serverless?
            case instance_class
            when /micro|small/ then 1
            when /medium/ then 2
            when /large$/ then 2
            when /xlarge$/ then 4
            when /2xlarge/ then 8
            when /4xlarge/ then 16
            when /8xlarge/ then 32
            when /12xlarge/ then 48
            when /16xlarge/ then 64
            when /24xlarge/ then 96
            when /32xlarge/ then 128
            else 2
            end
          end

          def estimated_memory_gb
            return 'variable' if is_serverless?
            INSTANCE_MEMORY_MAP[instance_class] || 8
          end

          def estimated_monthly_cost
            return 'Variable based on Aurora Capacity Units' if is_serverless?
            hourly_rate = HOURLY_RATES[instance_class] || 0.200
            "~$#{(hourly_rate * 730).round(2)}/month"
          end

          def performance_characteristics
            {
              vcpus: estimated_vcpus, memory_gb: estimated_memory_gb, instance_family: instance_family,
              instance_size: instance_size, is_burstable: is_burstable?, is_memory_optimized: is_memory_optimized?,
              is_graviton: is_graviton?, supports_performance_insights: supports_performance_insights?,
              supports_enhanced_monitoring: supports_enhanced_monitoring?
            }
          end

          INSTANCE_MEMORY_MAP = {
            'db.t3.micro' => 1, 'db.t3.small' => 2, 'db.t3.medium' => 4, 'db.t3.large' => 8,
            'db.t3.xlarge' => 16, 'db.t3.2xlarge' => 32, 'db.t4g.micro' => 1, 'db.t4g.small' => 2,
            'db.t4g.medium' => 4, 'db.t4g.large' => 8, 'db.t4g.xlarge' => 16, 'db.t4g.2xlarge' => 32,
            'db.r5.large' => 16, 'db.r5.xlarge' => 32, 'db.r5.2xlarge' => 64, 'db.r5.4xlarge' => 128,
            'db.r5.8xlarge' => 256, 'db.r5.12xlarge' => 384, 'db.r5.16xlarge' => 512, 'db.r5.24xlarge' => 768,
            'db.r6g.large' => 16, 'db.r6g.xlarge' => 32, 'db.r6g.2xlarge' => 64, 'db.r6g.4xlarge' => 128,
            'db.r6g.8xlarge' => 256, 'db.r6g.12xlarge' => 384, 'db.r6g.16xlarge' => 512
          }.freeze

          HOURLY_RATES = {
            'db.t3.small' => 0.041, 'db.t3.medium' => 0.082, 'db.t3.large' => 0.164, 'db.t3.xlarge' => 0.328,
            'db.t3.2xlarge' => 0.656, 'db.t4g.medium' => 0.073, 'db.t4g.large' => 0.146,
            'db.r5.large' => 0.240, 'db.r5.xlarge' => 0.480, 'db.r5.2xlarge' => 0.960, 'db.r5.4xlarge' => 1.920,
            'db.r6g.large' => 0.216, 'db.r6g.xlarge' => 0.432, 'db.r6g.2xlarge' => 0.864
          }.freeze
        end
      end
    end
  end
end
