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
        # Configuration templates for BatchComputeEnvironmentAttributes
        module BatchComputeEnvironmentTemplates
          def self.ec2_managed_environment(name, vpc_config, options = {})
            {
              compute_environment_name: name,
              type: "MANAGED",
              state: "ENABLED",
              compute_resources: {
                type: "EC2",
                allocation_strategy: "BEST_FIT_PROGRESSIVE",
                min_vcpus: options[:min_vcpus] || 0,
                max_vcpus: options[:max_vcpus] || 100,
                desired_vcpus: options[:desired_vcpus] || 0,
                instance_types: options[:instance_types] || ["optimal"],
                subnets: vpc_config[:subnets],
                security_group_ids: vpc_config[:security_group_ids],
                instance_role: options[:instance_role],
                tags: options[:tags] || {}
              }
            }
          end

          def self.spot_managed_environment(name, vpc_config, options = {})
            {
              compute_environment_name: name,
              type: "MANAGED",
              state: "ENABLED",
              compute_resources: {
                type: "SPOT",
                allocation_strategy: "SPOT_CAPACITY_OPTIMIZED",
                min_vcpus: options[:min_vcpus] || 0,
                max_vcpus: options[:max_vcpus] || 100,
                desired_vcpus: options[:desired_vcpus] || 0,
                instance_types: options[:instance_types] || ["optimal"],
                spot_iam_fleet_request_role: options[:spot_iam_fleet_request_role],
                bid_percentage: options[:bid_percentage] || 50,
                subnets: vpc_config[:subnets],
                security_group_ids: vpc_config[:security_group_ids],
                instance_role: options[:instance_role],
                tags: options[:tags] || {}
              }
            }
          end

          def self.fargate_managed_environment(name, vpc_config, options = {})
            {
              compute_environment_name: name,
              type: "MANAGED",
              state: "ENABLED",
              compute_resources: {
                type: "FARGATE",
                max_vcpus: options[:max_vcpus] || 100,
                subnets: vpc_config[:subnets],
                security_group_ids: vpc_config[:security_group_ids],
                platform_capabilities: ["FARGATE"],
                tags: options[:tags] || {}
              }
            }
          end

          def self.fargate_spot_managed_environment(name, vpc_config, options = {})
            {
              compute_environment_name: name,
              type: "MANAGED",
              state: "ENABLED",
              compute_resources: {
                type: "FARGATE_SPOT",
                max_vcpus: options[:max_vcpus] || 100,
                subnets: vpc_config[:subnets],
                security_group_ids: vpc_config[:security_group_ids],
                platform_capabilities: ["FARGATE"],
                tags: options[:tags] || {}
              }
            }
          end

          def self.unmanaged_environment(name, options = {})
            {
              compute_environment_name: name,
              type: "UNMANAGED",
              state: options[:state] || "ENABLED",
              service_role: options[:service_role],
              tags: options[:tags] || {}
            }
          end
        end

        # Common EC2 instance type groups for AWS Batch
        module BatchInstanceTypes
          def self.compute_optimized_instances
            %w[
              c4.large c4.xlarge c4.2xlarge c4.4xlarge c4.8xlarge
              c5.large c5.xlarge c5.2xlarge c5.4xlarge c5.9xlarge c5.12xlarge c5.18xlarge c5.24xlarge
              c5n.large c5n.xlarge c5n.2xlarge c5n.4xlarge c5n.9xlarge c5n.18xlarge
              c6i.large c6i.xlarge c6i.2xlarge c6i.4xlarge c6i.8xlarge c6i.12xlarge c6i.16xlarge
              c6i.24xlarge c6i.32xlarge
            ]
          end

          def self.memory_optimized_instances
            %w[
              r4.large r4.xlarge r4.2xlarge r4.4xlarge r4.8xlarge r4.16xlarge
              r5.large r5.xlarge r5.2xlarge r5.4xlarge r5.8xlarge r5.12xlarge r5.16xlarge r5.24xlarge
              r5a.large r5a.xlarge r5a.2xlarge r5a.4xlarge r5a.8xlarge r5a.12xlarge r5a.16xlarge r5a.24xlarge
              r6i.large r6i.xlarge r6i.2xlarge r6i.4xlarge r6i.8xlarge r6i.12xlarge r6i.16xlarge
              r6i.24xlarge r6i.32xlarge
            ]
          end

          def self.general_purpose_instances
            %w[
              m4.large m4.xlarge m4.2xlarge m4.4xlarge m4.10xlarge m4.16xlarge
              m5.large m5.xlarge m5.2xlarge m5.4xlarge m5.8xlarge m5.12xlarge m5.16xlarge m5.24xlarge
              m5a.large m5a.xlarge m5a.2xlarge m5a.4xlarge m5a.8xlarge m5a.12xlarge m5a.16xlarge m5a.24xlarge
              m6i.large m6i.xlarge m6i.2xlarge m6i.4xlarge m6i.8xlarge m6i.12xlarge m6i.16xlarge
              m6i.24xlarge m6i.32xlarge
            ]
          end

          def self.gpu_instances
            %w[
              p2.xlarge p2.8xlarge p2.16xlarge
              p3.2xlarge p3.8xlarge p3.16xlarge
              p3dn.24xlarge
              g3.4xlarge g3.8xlarge g3.16xlarge
              g4dn.xlarge g4dn.2xlarge g4dn.4xlarge g4dn.8xlarge g4dn.12xlarge g4dn.16xlarge
            ]
          end
        end
      end
    end
  end
end
