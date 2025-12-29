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
  module Components
    module SpotInstanceCarbonOptimizer
      # Spot fleet resource creation methods
      module Fleets
        def create_regional_spot_fleets(input, fleet_role, state_table)
          spot_fleets = {}

          # Only create fleets in regions with VPC configuration
          configured_regions = input.vpc_configs.keys & input.allowed_regions

          configured_regions.each do |region|
            vpc_config = input.vpc_configs[region]

            spot_fleets[region] = aws_spot_fleet_request(:"#{input.name}-fleet-#{region}", {
              iam_fleet_role: fleet_role.arn,
              target_capacity: calculate_regional_capacity(input, region),
              valid_until: (Time.now + 365 * 24 * 60 * 60).iso8601, # 1 year
              terminate_instances_with_expiration: true,
              instance_interruption_behavior: input.interruption_behavior,
              fleet_type: "maintain",
              replace_unhealthy_instances: true,

              launch_specification: create_launch_specifications(input, region, vpc_config),

              spot_price: calculate_spot_price(input, region),
              allocation_strategy: "lowestPrice",
              instance_pools_to_use_count: 2,

              tag_specification: [{
                resource_type: "spot-fleet-request",
                tags: input.tags.merge(
                  "Component" => "spot-carbon-optimizer",
                  "Region" => region,
                  "CarbonOptimized" => "true"
                )
              }]
            })
          end

          spot_fleets
        end

        def calculate_regional_capacity(input, region)
          # Distribute capacity based on carbon intensity
          if input.optimization_strategy == 'renewable_only'
            input.preferred_regions.include?(region) ? input.target_capacity : 0
          else
            # Weight by inverse carbon intensity
            carbon_intensity = Types::REGIONAL_CARBON_BASELINE[region] || 400
            weight = 1000.0 / carbon_intensity
            (input.target_capacity * weight / 10).to_i.clamp(1, input.target_capacity)
          end
        end

        def create_launch_specifications(input, region, vpc_config)
          input.instance_types.map do |instance_type|
            {
              instance_type: instance_type,
              image_id: get_latest_ami(region, instance_type),
              subnet_id: vpc_config[:subnet_ids].split(',').first,
              security_groups: [{ group_id: create_security_group(input, region, vpc_config[:vpc_id]) }],

              user_data: Base64.encode64(generate_user_data(input, region)),

              block_device_mappings: [{
                device_name: "/dev/xvda",
                ebs: {
                  volume_size: 30,
                  volume_type: "gp3",
                  delete_on_termination: true
                }
              }],

              instance_market_options: {
                market_type: "spot",
                spot_options: {
                  spot_instance_type: input.use_spot_blocks ? "persistent" : "one-time",
                  block_duration_minutes: input.spot_block_duration_hours ? input.spot_block_duration_hours * 60 : nil
                }
              },

              tag_specifications: [{
                resource_type: "instance",
                tags: input.tags.merge(
                  "Component" => "spot-carbon-optimizer",
                  "Region" => region,
                  "WorkloadType" => input.workload_type
                )
              }]
            }
          end
        end
      end
    end
  end
end
