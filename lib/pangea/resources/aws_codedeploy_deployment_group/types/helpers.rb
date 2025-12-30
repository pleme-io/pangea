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
        # Helper methods for CodeDeploy deployment group attributes
        module CodeDeployDeploymentGroupHelpers
          def uses_ec2_tags?
            ec2_tag_filters.any?
          end

          def uses_on_premises_tags?
            on_premises_instance_tag_filters.any?
          end

          def uses_auto_scaling?
            auto_scaling_groups.any?
          end

          def has_triggers?
            trigger_configurations.any?
          end

          def auto_rollback_enabled?
            auto_rollback_configuration[:enabled] == true
          end

          def uses_alarms?
            alarm_configuration[:enabled] == true && alarm_configuration[:alarms]&.any?
          end

          def blue_green_deployment?
            deployment_style[:deployment_type] == 'BLUE_GREEN'
          end

          def in_place_deployment?
            deployment_style[:deployment_type] == 'IN_PLACE' || deployment_style[:deployment_type].nil?
          end

          def uses_load_balancer?
            load_balancer_info[:elb_info]&.any? ||
              load_balancer_info[:target_group_info]&.any? ||
              load_balancer_info[:target_group_pair_info]&.any?
          end

          def ecs_deployment?
            !ecs_service[:cluster_name].nil? && !ecs_service[:cluster_name].empty?
          end

          def traffic_control_enabled?
            deployment_style[:deployment_option] == 'WITH_TRAFFIC_CONTROL'
          end

          def deployment_target_type
            if uses_ec2_tags?
              'EC2 instances (tag-based)'
            elsif uses_auto_scaling?
              'Auto Scaling groups'
            elsif uses_on_premises_tags?
              'On-premises instances'
            elsif ecs_deployment?
              'ECS service'
            else
              'Unknown'
            end
          end
        end
      end
    end
  end
end
