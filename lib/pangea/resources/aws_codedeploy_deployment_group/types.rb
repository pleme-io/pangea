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
require_relative 'types/tag_filters'
require_relative 'types/deployment'
require_relative 'types/infrastructure'
require_relative 'types/helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS CodeDeploy Deployment Group resources
        class CodeDeployDeploymentGroupAttributes < Dry::Struct
          include CodeDeployDeploymentGroupHelpers
          transform_keys(&:to_sym)

          # Core attributes
          attribute :app_name, Resources::Types::String

          attribute :deployment_group_name, Resources::Types::String.constrained(
            format: /\A[a-zA-Z0-9._-]+\z/,
            min_size: 1,
            max_size: 100
          )

          attribute :service_role_arn, Resources::Types::String
          attribute :deployment_config_name, Resources::Types::String.default('CodeDeployDefault.OneAtATime')

          # Compose attributes from sub-types
          attributes_from TagFilterAttributes
          attributes_from DeploymentAttributes
          attributes_from InfrastructureAttributes

          # Tags
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            validate_tag_filters(attrs)
            validate_blue_green_deployment(attrs)
            validate_ecs_service(attrs)
            attrs
          end

          def self.validate_tag_filters(attrs)
            attrs.ec2_tag_filters.each do |filter|
              case filter[:type]
              when 'KEY_ONLY'
                raise Dry::Struct::Error, "KEY_ONLY filter requires 'key' to be specified" unless filter[:key]
              when 'VALUE_ONLY'
                raise Dry::Struct::Error, "VALUE_ONLY filter requires 'value' to be specified" unless filter[:value]
              when 'KEY_AND_VALUE'
                raise Dry::Struct::Error, "KEY_AND_VALUE filter requires both 'key' and 'value'" unless filter[:key] && filter[:value]
              end
            end
          end

          def self.validate_blue_green_deployment(attrs)
            return unless attrs.deployment_style[:deployment_type] == 'BLUE_GREEN'

            if attrs.blue_green_deployment_config.empty?
              raise Dry::Struct::Error, 'Blue-green deployment requires blue_green_deployment_config'
            end

            has_lb = attrs.load_balancer_info[:elb_info] ||
                     attrs.load_balancer_info[:target_group_info] ||
                     attrs.load_balancer_info[:target_group_pair_info]
            raise Dry::Struct::Error, 'Blue-green deployment requires load balancer configuration' unless has_lb
          end

          def self.validate_ecs_service(attrs)
            if attrs.ecs_service[:cluster_name] && !attrs.ecs_service[:service_name]
              raise Dry::Struct::Error, 'ECS service configuration requires both cluster_name and service_name'
            end
          end
        end
      end
    end
  end
end
