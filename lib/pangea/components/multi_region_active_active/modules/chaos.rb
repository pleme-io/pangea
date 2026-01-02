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

require 'json'

module Pangea
  module Components
    module MultiRegionActiveActive
      # Chaos engineering experiment resources using AWS FIS
      module Chaos
        def create_chaos_experiments(name, attrs, resources, tags)
          chaos_resources = {}

          chaos_resources[:fis_role] = create_fis_role(name, tags)
          chaos_resources[:fis_policy] = create_fis_policy_attachment(name, chaos_resources[:fis_role])
          chaos_resources[:experiment_template] = create_experiment_template(name, attrs, chaos_resources[:fis_role], tags)

          chaos_resources
        end

        private

        def create_fis_role(name, tags)
          aws_iam_role(
            component_resource_name(name, :fis_role),
            {
              name: "#{name}-fis-role",
              assume_role_policy: JSON.generate(build_fis_assume_role_policy),
              tags: tags
            }
          )
        end

        def build_fis_assume_role_policy
          {
            Version: '2012-10-17',
            Statement: [{
              Effect: 'Allow',
              Principal: { Service: 'fis.amazonaws.com' },
              Action: 'sts:AssumeRole'
            }]
          }
        end

        def create_fis_policy_attachment(name, fis_role)
          aws_iam_role_policy_attachment(
            component_resource_name(name, :fis_policy_attachment),
            {
              role: fis_role.name,
              policy_arn: 'arn:aws:iam::aws:policy/service-role/AWSFaultInjectionSimulatorECSAccess'
            }
          )
        end

        def create_experiment_template(name, attrs, fis_role, tags)
          aws_fis_experiment_template(
            component_resource_name(name, :fis_experiment),
            {
              description: "Simulate region failure for #{attrs.deployment_name}",
              role_arn: fis_role.arn,
              stop_condition: [{ source: 'none' }],
              action: build_experiment_actions,
              target: build_experiment_targets,
              tags: tags.merge(ExperimentType: 'RegionFailure')
            }
          )
        end

        def build_experiment_actions
          {
            stop_ecs_tasks: {
              action_id: 'aws:ecs:stop-task',
              description: 'Stop ECS tasks in a region',
              target: { key: 'Tasks', value: 'ecs-tasks' }
            }
          }
        end

        def build_experiment_targets
          {
            'ecs-tasks': {
              resource_type: 'aws:ecs:task',
              selection_mode: 'PERCENT(50)',
              resource_tag: { Component: 'MultiRegionActiveActive' }
            }
          }
        end
      end
    end
  end
end
