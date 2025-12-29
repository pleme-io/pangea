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
    module GlobalServiceMesh
      # Resilience infrastructure: FIS chaos testing experiments
      module Resilience
        def create_resilience_infrastructure(name, attrs, _resources, tags)
          resilience_resources = {}

          if attrs.resilience.chaos_testing_enabled
            create_chaos_testing_resources(name, attrs, tags, resilience_resources)
          end

          resilience_resources
        end

        private

        def create_chaos_testing_resources(name, attrs, tags, resilience_resources)
          resilience_resources[:fis_role] = create_fis_role(name, tags)
          resilience_resources[:experiment] = create_experiment_template(
            name, attrs, resilience_resources[:fis_role], tags
          )
        end

        def create_fis_role(name, tags)
          aws_iam_role(
            component_resource_name(name, :fis_role),
            {
              name: "#{name}-fis-role",
              assume_role_policy: build_fis_assume_role_policy,
              tags: tags
            }
          )
        end

        def build_fis_assume_role_policy
          JSON.generate({
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Principal: { Service: "fis.amazonaws.com" },
              Action: "sts:AssumeRole"
            }]
          })
        end

        def create_experiment_template(name, attrs, fis_role_ref, tags)
          aws_fis_experiment_template(
            component_resource_name(name, :chaos_experiment),
            {
              description: "Service mesh chaos testing",
              role_arn: fis_role_ref.arn,

              stop_condition: [{
                source: "aws:cloudwatch:alarm",
                value: "arn:aws:cloudwatch:*:*:alarm:#{name}-*"
              }],

              action: build_chaos_actions,
              target: build_chaos_targets(attrs),

              tags: tags
            }
          )
        end

        def build_chaos_actions
          {
            inject_latency: {
              action_id: "aws:network:disrupt-connectivity",
              description: "Inject network latency",
              parameters: {
                duration: "PT5M",
                scope: "SOME",
                percentage: "50"
              },
              target: {
                key: "Targets",
                value: "service-instances"
              }
            }
          }
        end

        def build_chaos_targets(attrs)
          {
            "service-instances": {
              resource_type: "aws:ecs:task",
              selection_mode: "PERCENT(25)",
              resource_tag: {
                ServiceMesh: attrs.mesh_name
              }
            }
          }
        end
      end
    end
  end
end
