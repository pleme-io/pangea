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
      module MediaLiveChannel
        class DSLBuilder
          # Configuration blocks DSL building for MediaLive Channel
          module Configurations
            def build_input_specification(ctx)
              ctx.input_specification do
                codec attrs.input_specification[:codec]
                maximum_bitrate attrs.input_specification[:maximum_bitrate]
                resolution attrs.input_specification[:resolution]
              end
            end

            def build_maintenance(ctx)
              return unless attrs.maintenance.any?

              ctx.maintenance do
                maintenance_day attrs.maintenance[:maintenance_day]
                maintenance_start_time attrs.maintenance[:maintenance_start_time]
              end
            end

            def build_reserved_instances(ctx)
              attrs.reserved_instances.each do |reserved_instance|
                ctx.reserved_instances do
                  count reserved_instance[:count]
                  name reserved_instance[:name]
                end
              end
            end

            def build_vpc(ctx)
              return unless attrs.vpc.any?

              ctx.vpc do
                public_address_allocation_ids attrs.vpc[:public_address_allocation_ids]
                security_group_ids attrs.vpc[:security_group_ids]
                subnet_ids attrs.vpc[:subnet_ids]
              end
            end

            def build_tags(ctx)
              return unless attrs.tags.any?

              ctx.tags do
                attrs.tags.each do |key, value|
                  public_send(key, value)
                end
              end
            end
          end
        end
      end
    end
  end
end
