# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Default capacity provider strategy
      class EcsDefaultCapacityProviderStrategy < Dry::Struct
        attribute :capacity_provider, Resources::Types::String
        attribute :weight, Resources::Types::Integer.constrained(gteq: 0, lteq: 1000).default(1)
        attribute :base, Resources::Types::Integer.constrained(gteq: 0, lteq: 100000).default(0)
        
        # Validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate that base tasks don't exceed reasonable limits
          if attrs.base > 0 && attrs.weight == 0
            raise Dry::Struct::Error, "Cannot have base > 0 with weight = 0"
          end
          
          attrs
        end
      end
      
      # Type-safe attributes for AWS ECS Cluster Capacity Providers
      class EcsClusterCapacityProvidersAttributes < Dry::Struct
        # Cluster name (required)
        attribute :cluster_name, Resources::Types::String
        
        # Capacity providers to associate with the cluster
        attribute :capacity_providers, Resources::Types::Array.of(Types::String).default([].freeze)
        
        # Default capacity provider strategy
        attribute :default_capacity_provider_strategy, Resources::Types::Array.of(EcsDefaultCapacityProviderStrategy).default([].freeze)
        
        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate capacity provider names
          valid_aws_providers = %w[FARGATE FARGATE_SPOT]
          attrs.capacity_providers.each do |provider|
            unless valid_aws_providers.include?(provider) || provider.start_with?("arn:aws:ecs:")
              # Could be a custom capacity provider name
              unless provider.match?(/^[\w\-]+$/)
                raise Dry::Struct::Error, "Invalid capacity provider name format: #{provider}"
              end
            end
          end
          
          # Validate default strategy references valid providers
          if attrs.default_capacity_provider_strategy.any?
            strategy_providers = attrs.default_capacity_provider_strategy.map(&:capacity_provider)
            strategy_providers.each do |provider|
              unless attrs.capacity_providers.include?(provider)
                raise Dry::Struct::Error, "Default strategy references undefined capacity provider: #{provider}"
              end
            end
            
            # Validate total weight > 0
            total_weight = attrs.default_capacity_provider_strategy.sum(&:weight)
            if total_weight == 0 && attrs.default_capacity_provider_strategy.any? { |s| s.base == 0 }
              raise Dry::Struct::Error, "Default capacity provider strategy must have at least one provider with weight > 0 or base > 0"
            end
            
            # Validate only one provider can have base > 0 for a given base value
            # Multiple providers can have different base values
            base_counts = attrs.default_capacity_provider_strategy
              .group_by(&:base)
              .reject { |base, _| base == 0 }
            
            base_counts.each do |base, strategies|
              if strategies.size > 1
                raise Dry::Struct::Error, "Multiple providers cannot have the same base value (#{base})"
              end
            end
          end
          
          attrs
        end
        
        # Helper to check if using Fargate
        def using_fargate?
          capacity_providers.any? { |cp| cp.include?("FARGATE") }
        end
        
        # Helper to check if using EC2
        def using_ec2?
          capacity_providers.any? { |cp| !cp.include?("FARGATE") && !cp.start_with?("arn:") }
        end
        
        # Helper to check if using custom providers
        def using_custom_providers?
          capacity_providers.any? { |cp| !%w[FARGATE FARGATE_SPOT].include?(cp) }
        end
        
        # Helper to get the primary capacity provider
        def primary_capacity_provider
          return nil if default_capacity_provider_strategy.empty?
          
          # Provider with highest base, or highest weight if no base
          strategy_with_base = default_capacity_provider_strategy.max_by(&:base)
          return strategy_with_base.capacity_provider if strategy_with_base.base > 0
          
          default_capacity_provider_strategy.max_by(&:weight).capacity_provider
        end
        
        # Helper to calculate capacity distribution
        def capacity_distribution
          return {} if default_capacity_provider_strategy.empty?
          
          total_weight = default_capacity_provider_strategy.sum(&:weight)
          return {} if total_weight == 0
          
          distribution = {}
          default_capacity_provider_strategy.each do |strategy|
            percentage = (strategy.weight.to_f / total_weight * 100).round(1)
            distribution[strategy.capacity_provider] = {
              percentage: percentage,
              base: strategy.base
            }
          end
          
          distribution
        end
        
        # Helper to check if Spot instances are prioritized
        def spot_prioritized?
          return false if default_capacity_provider_strategy.empty?
          
          spot_strategy = default_capacity_provider_strategy.find { |s| s.capacity_provider == "FARGATE_SPOT" }
          regular_strategy = default_capacity_provider_strategy.find { |s| s.capacity_provider == "FARGATE" }
          
          return false unless spot_strategy && regular_strategy
          
          spot_strategy.weight > regular_strategy.weight
        end
        
        # Helper to estimate cost savings from Spot usage
        def estimated_spot_savings_percent
          return 0.0 unless using_fargate?
          
          distribution = capacity_distribution
          spot_percentage = distribution["FARGATE_SPOT"]&.dig(:percentage) || 0.0
          
          # Fargate Spot offers up to 70% discount
          (spot_percentage * 0.7).round(1)
        end
      end
    end
      end
    end
  end
end