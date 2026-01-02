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
  module Architectures
    module Patterns
      module WebApplication
        # Load balancer tier creation for web application
        module LoadBalancerTier
          private

          def create_load_balancer_tier(name, arch_ref, _arch_attrs, base_tags)
            alb = create_application_load_balancer(name, arch_ref, base_tags)
            target_group = create_target_group(name, arch_ref, base_tags)
            listener = create_listener(name, alb, target_group)
            attachment = create_asg_attachment(name, arch_ref, target_group)

            { load_balancer: alb, target_group: target_group, listener: listener, asg_attachment: attachment }
          end

          def create_application_load_balancer(name, arch_ref, base_tags)
            aws_lb(
              architecture_resource_name(name, :alb),
              name: "#{name}-alb",
              load_balancer_type: 'application',
              subnets: arch_ref.network.public_subnet_ids,
              security_groups: [arch_ref.security[:web_sg].id],
              tags: base_tags.merge(Tier: 'load-balancer', Component: 'alb')
            )
          end

          def create_target_group(name, arch_ref, base_tags)
            aws_lb_target_group(
              architecture_resource_name(name, :tg),
              name: "#{name}-tg",
              port: 80,
              protocol: 'HTTP',
              vpc_id: arch_ref.network.vpc.id,
              health_check: {
                enabled: true, healthy_threshold: 2, unhealthy_threshold: 2,
                timeout: 5, interval: 30, path: '/', matcher: '200'
              },
              tags: base_tags.merge(Tier: 'load-balancer', Component: 'target-group')
            )
          end

          def create_listener(name, alb, target_group)
            aws_lb_listener(
              architecture_resource_name(name, :listener),
              load_balancer_arn: alb.arn,
              port: '80',
              protocol: 'HTTP',
              default_action: { type: 'forward', target_group_arn: target_group.arn }
            )
          end

          def create_asg_attachment(name, arch_ref, target_group)
            aws_autoscaling_attachment(
              architecture_resource_name(name, :asg_attachment),
              autoscaling_group_name: arch_ref.compute[:auto_scaling_group].name,
              lb_target_group_arn: target_group.arn
            )
          end
        end
      end
    end
  end
end
