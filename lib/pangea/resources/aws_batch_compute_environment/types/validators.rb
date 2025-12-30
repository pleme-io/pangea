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

module Pangea
  module Resources
    module AWS
      module Types
        # Validation methods for BatchComputeEnvironmentAttributes
        module BatchComputeEnvironmentValidators
          def self.validate_compute_environment_name(name)
            if name.length < 1 || name.length > 128
              raise Dry::Struct::Error, "Compute environment name must be between 1 and 128 characters"
            end

            unless name.match?(/^[a-zA-Z0-9\-_]+$/)
              raise Dry::Struct::Error,
                    "Compute environment name can only contain letters, numbers, hyphens, and underscores"
            end

            true
          end

          def self.validate_compute_resources(resources)
            unless resources.is_a?(Hash)
              raise Dry::Struct::Error, "Compute resources must be a hash"
            end

            if resources[:type] && !%w[EC2 SPOT FARGATE FARGATE_SPOT].include?(resources[:type])
              raise Dry::Struct::Error, "Compute resource type must be one of: EC2, SPOT, FARGATE, FARGATE_SPOT"
            end

            validate_allocation_strategy(resources)
            validate_vcpu_settings(resources)
            validate_instance_types(resources[:instance_types]) if resources[:instance_types]
            validate_spot_configuration(resources)
            validate_fargate_configuration(resources)

            true
          end

          def self.validate_allocation_strategy(resources)
            return unless resources[:allocation_strategy]

            valid_strategies = case resources[:type]
                               when "EC2", "SPOT"
                                 %w[BEST_FIT BEST_FIT_PROGRESSIVE SPOT_CAPACITY_OPTIMIZED]
                               when "FARGATE", "FARGATE_SPOT"
                                 ["SPOT_CAPACITY_OPTIMIZED"]
                               else
                                 []
                               end

            unless valid_strategies.include?(resources[:allocation_strategy])
              raise Dry::Struct::Error,
                    "Invalid allocation strategy '#{resources[:allocation_strategy]}' for type '#{resources[:type]}'"
            end
          end

          def self.validate_vcpu_settings(resources)
            if resources[:min_vcpus] && resources[:min_vcpus] < 0
              raise Dry::Struct::Error, "min_vcpus must be non-negative"
            end

            if resources[:max_vcpus] && resources[:max_vcpus] < 0
              raise Dry::Struct::Error, "max_vcpus must be non-negative"
            end

            if resources[:desired_vcpus] && resources[:desired_vcpus] < 0
              raise Dry::Struct::Error, "desired_vcpus must be non-negative"
            end

            if resources[:min_vcpus] && resources[:max_vcpus] && resources[:min_vcpus] > resources[:max_vcpus]
              raise Dry::Struct::Error, "min_vcpus cannot be greater than max_vcpus"
            end

            if resources[:desired_vcpus] && resources[:max_vcpus] && resources[:desired_vcpus] > resources[:max_vcpus]
              raise Dry::Struct::Error, "desired_vcpus cannot be greater than max_vcpus"
            end
          end

          def self.validate_instance_types(instance_types)
            return true if instance_types == ["optimal"]

            unless instance_types.is_a?(Array) && instance_types.all? { |type| type.is_a?(String) }
              raise Dry::Struct::Error, "Instance types must be an array of strings"
            end

            instance_types.each do |type|
              unless type.match?(/^[a-z0-9]+\.[a-z0-9]+$/) || type == "optimal"
                raise Dry::Struct::Error, "Invalid instance type format: #{type}"
              end
            end

            true
          end

          def self.validate_spot_configuration(resources)
            if resources[:type] == "SPOT" && resources[:spot_iam_fleet_request_role].nil?
              raise Dry::Struct::Error, "SPOT compute resources require spot_iam_fleet_request_role"
            end
          end

          def self.validate_fargate_configuration(resources)
            return unless %w[FARGATE FARGATE_SPOT].include?(resources[:type])

            if resources[:platform_capabilities] && !resources[:platform_capabilities].include?("FARGATE")
              raise Dry::Struct::Error, "Fargate compute resources must include FARGATE platform capability"
            end
          end

          def self.validate_vpc_configuration(vpc_config)
            unless vpc_config.is_a?(Hash)
              raise Dry::Struct::Error, "VPC configuration must be a hash"
            end

            unless vpc_config[:subnets] && vpc_config[:subnets].is_a?(Array) && !vpc_config[:subnets].empty?
              raise Dry::Struct::Error, "VPC configuration must include non-empty subnets array"
            end

            unless vpc_config[:security_group_ids] && vpc_config[:security_group_ids].is_a?(Array) &&
                   !vpc_config[:security_group_ids].empty?
              raise Dry::Struct::Error, "VPC configuration must include non-empty security_group_ids array"
            end

            true
          end
        end
      end
    end
  end
end
