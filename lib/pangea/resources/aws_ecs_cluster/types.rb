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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS ECS Cluster resources
        class EcsClusterAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Cluster name (required)
          attribute :name, Pangea::Resources::Types::String

          # Capacity providers
          attribute :capacity_providers, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)

          # Container Insights
          attribute? :container_insights_enabled, Pangea::Resources::Types::Bool.optional

          # Settings
          attribute :setting, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              name: Pangea::Resources::Types::String.constrained(included_in: ["containerInsights"]),
              value: Pangea::Resources::Types::String.constrained(included_in: ["enabled", "disabled"])
            )
          ).default([].freeze)

          # Configuration for execute command
          attribute? :configuration, Pangea::Resources::Types::Hash.schema(
            execute_command_configuration?: Pangea::Resources::Types::Hash.schema(
              kms_key_id?: Pangea::Resources::Types::String.optional,
              logging?: Pangea::Resources::Types::String.constrained(included_in: ["DEFAULT", "NONE", "OVERRIDE"]).optional,
              log_configuration?: Pangea::Resources::Types::Hash.schema(
                cloud_watch_encryption_enabled?: Pangea::Resources::Types::Bool.optional,
                cloud_watch_log_group_name?: Pangea::Resources::Types::String.optional,
                s3_bucket_name?: Pangea::Resources::Types::String.optional,
                s3_bucket_encryption_enabled?: Pangea::Resources::Types::Bool.optional,
                s3_key_prefix?: Pangea::Resources::Types::String.optional
              ).optional
            ).optional
          ).optional

          # Service Connect defaults
          attribute? :service_connect_defaults, Pangea::Resources::Types::Hash.schema(
            namespace: Pangea::Resources::Types::String
          ).optional

          # Tags
          attribute :tags, Pangea::Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate capacity providers
          valid_providers = %w[FARGATE FARGATE_SPOT]
          attrs.capacity_providers.each do |provider|
            unless valid_providers.include?(provider) || provider.start_with?("arn:aws:ecs:")
              raise Dry::Struct::Error, "Invalid capacity provider: #{provider}. Must be FARGATE, FARGATE_SPOT, or an ARN"
            end
          end

          # Validate container insights setting
          if attrs.container_insights_enabled && attrs.setting.any?
            existing_insights = attrs.setting.find { |s| s[:name] == "containerInsights" }
            if existing_insights
              expected_value = attrs.container_insights_enabled ? "enabled" : "disabled"
              if existing_insights[:value] != expected_value
                raise Dry::Struct::Error, "container_insights_enabled conflicts with setting value"
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
          capacity_providers.any? { |cp| !cp.include?("FARGATE") }
        end

        # Helper to check if Container Insights is enabled
        def insights_enabled?
          return container_insights_enabled if !container_insights_enabled.nil?
          
          insights_setting = setting.find { |s| s[:name] == "containerInsights" }
          insights_setting ? insights_setting[:value] == "enabled" : false
        end

        # Helper to estimate monthly cost
        def estimated_monthly_cost
          # Base cost for Container Insights if enabled
          insights_cost = insights_enabled? ? 5.0 : 0.0
          
          # ECS cluster itself is free, but add estimates for common resources
          base_estimate = {
            insights: insights_cost,
            service_connect: service_connect_defaults ? 2.0 : 0.0
          }
          
          base_estimate.values.sum
        end

        # Helper to generate a cluster ARN pattern
          def arn_pattern(region = "*", account_id = "*")
            "arn:aws:ecs:#{region}:#{account_id}:cluster/#{name}"
          end
        end

        # Type for ECS cluster capacity provider strategy
        class EcsCapacityProviderStrategy < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :capacity_provider, Pangea::Resources::Types::String
          attribute :weight, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 1000).default(1)
          attribute :base, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 100000).default(0)
          
          # Validate strategy
          def self.new(attributes = {})
            attrs = super(attributes)
            
            # Validate that weight and base make sense together
            if attrs.base > 0 && attrs.weight == 0
              raise Dry::Struct::Error, "Cannot have base > 0 with weight = 0"
            end
            
            attrs
          end
        end
      end
    end
  end
end