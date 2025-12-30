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
      module EmrCluster
        class DSLBuilder
          # Instance group building methods for EMR clusters
          module InstanceGroups
            def build_master_instance_group(ctx)
              mig = attrs.master_instance_group
              ctx.master_instance_group do
                instance_type mig[:instance_type]
                instance_count mig[:instance_count] if mig[:instance_count]
              end
            end

            def build_core_instance_group(ctx)
              return unless attrs.core_instance_group

              cig = attrs.core_instance_group
              builder = self
              ctx.core_instance_group do
                instance_type cig[:instance_type]
                instance_count cig[:instance_count] if cig[:instance_count]
                bid_price cig[:bid_price] if cig[:bid_price]
                builder.send(:build_ebs_config, self, cig[:ebs_config])
              end
            end

            def build_task_instance_groups(ctx)
              attrs.task_instance_groups.each do |task_group|
                build_single_task_group(ctx, task_group)
              end
            end

            private

            def build_single_task_group(ctx, task_group)
              builder = self
              ctx.task_instance_groups do
                name task_group[:name] if task_group[:name]
                instance_role task_group[:instance_role]
                instance_type task_group[:instance_type]
                instance_count task_group[:instance_count]
                bid_price task_group[:bid_price] if task_group[:bid_price]
                builder.send(:build_ebs_config, self, task_group[:ebs_config])
                builder.build_auto_scaling_policy(self, task_group[:auto_scaling_policy])
              end
            end

            def build_ebs_config(ctx, ebs_config)
              return unless ebs_config

              builder = self
              ctx.ebs_config do
                ebs_optimized ebs_config[:ebs_optimized] unless ebs_config[:ebs_optimized].nil?
                builder.send(:build_ebs_block_devices, self, ebs_config[:ebs_block_device_config])
              end
            end

            def build_ebs_block_devices(ctx, device_configs)
              return unless device_configs&.any?

              device_configs.each do |device_config|
                ctx.ebs_block_device_config do
                  volumes_per_instance device_config[:volumes_per_instance] if device_config[:volumes_per_instance]
                  build_volume_specification(self, device_config[:volume_specification])
                end
              end
            end

            def build_volume_specification(ctx, vol_spec)
              return unless vol_spec

              ctx.volume_specification do
                volume_type vol_spec[:volume_type]
                size_in_gb vol_spec[:size_in_gb]
                iops vol_spec[:iops] if vol_spec[:iops]
              end
            end
          end
        end
      end
    end
  end
end
