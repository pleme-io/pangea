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

require 'base64'

module Pangea
  module Architectures
    module Patterns
      module WebApplication
        # Compute tier creation for web application
        module ComputeTier
          private

          def create_compute_tier(name, arch_ref, arch_attrs, base_tags)
            compute_resources = {}

            user_data = Base64.encode64(generate_user_data(name, arch_ref, arch_attrs))

            compute_resources[:launch_template] = create_launch_template(name, arch_ref, arch_attrs,
                                                                         user_data, base_tags)
            compute_resources[:auto_scaling_group] = create_auto_scaling_group(name, arch_ref, arch_attrs,
                                                                               compute_resources[:launch_template],
                                                                               base_tags)

            compute_resources
          end

          def create_launch_template(name, arch_ref, arch_attrs, user_data, base_tags)
            aws_launch_template(
              architecture_resource_name(name, :launch_template),
              name_prefix: "#{name}-web-",
              image_id: arch_attrs.ami_id,
              instance_type: arch_attrs.instance_type,
              vpc_security_group_ids: [arch_ref.security[:web_sg].id],
              key_name: arch_attrs.key_pair,
              user_data: user_data,

              tag_specifications: [
                { resource_type: 'instance',
                  tags: base_tags.merge(Tier: 'compute', Component: 'web-server') }
              ],

              tags: base_tags.merge(Tier: 'compute', Component: 'launch-template')
            )
          end

          def create_auto_scaling_group(name, arch_ref, arch_attrs, launch_template, base_tags)
            scaling_config = resolve_scaling_config(arch_attrs)

            aws_autoscaling_group(
              architecture_resource_name(name, :asg),
              name: "#{name}-web-asg",
              vpc_zone_identifier: arch_ref.network.private_subnet_ids,
              health_check_type: 'ELB',
              health_check_grace_period: 300,

              min_size: scaling_config[:min],
              max_size: scaling_config[:max],
              desired_capacity: scaling_config[:desired],

              launch_template: { id: launch_template.id, version: '$Latest' },

              tags: build_asg_tags(name, base_tags)
            )
          end

          def resolve_scaling_config(arch_attrs)
            if arch_attrs.auto_scaling.empty?
              { min: 1, max: 1, desired: 1 }
            else
              arch_attrs.auto_scaling.merge(
                desired: arch_attrs.auto_scaling[:desired] || arch_attrs.auto_scaling[:min]
              )
            end
          end

          def build_asg_tags(name, base_tags)
            [{ key: 'Name', value: "#{name}-web-asg", propagate_at_launch: true }] +
              base_tags.map { |key, value| { key: key.to_s, value: value.to_s, propagate_at_launch: true } }
          end
        end
      end
    end
  end
end
