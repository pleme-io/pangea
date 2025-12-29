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
    module Composition
      # Auto-scaling web tier composition pattern
      module AutoScalingWebTier
        # Create an auto-scaling web tier with load balancer integration
        #
        # @param name [Symbol] Base name for resources
        # @param vpc_ref [ResourceReference] VPC reference
        # @param subnet_refs [Array<ResourceReference>] Subnet references for instances
        # @param load_balancer_ref [ResourceReference] Load balancer reference (optional)
        # @param attributes [Hash] Configuration attributes
        # @return [CompositeAutoScalingReference] Composite reference with all created resources
        def auto_scaling_web_tier(name, vpc_ref:, subnet_refs:, load_balancer_ref: nil, **attributes)
          config = default_config.merge(attributes)
          results = CompositeAutoScalingReference.new(name)

          results.security_group = create_asg_security_group(name, vpc_ref, config)
          results.launch_template = create_launch_template(name, results.security_group, config)
          results.target_group = create_target_group(name, vpc_ref, config)
          create_auto_scaling_resources(results, name, subnet_refs, config)
          create_scaling_policies(results, name)
          create_cloudwatch_alarms(results, name)

          results
        end

        private

        def default_config
          {
            instance_type: 't3.micro',
            min_instances: 1,
            max_instances: 10,
            desired_instances: 2,
            ami_id: 'ami-0c55b159cbfafe1f0',
            key_name: nil,
            user_data: nil,
            health_check_path: '/',
            tags: {}
          }
        end

        def create_asg_security_group(name, vpc_ref, config)
          aws_security_group(:"#{name}_sg", {
                               name_prefix: "#{name}-sg-",
                               vpc_id: vpc_ref.id,
                               description: "Security group for #{name} auto scaling group",
                               ingress_rules: [
                                 { from_port: 80, to_port: 80, protocol: 'tcp',
                                   cidr_blocks: ['0.0.0.0/0'], description: 'HTTP' },
                                 { from_port: 443, to_port: 443, protocol: 'tcp',
                                   cidr_blocks: ['0.0.0.0/0'], description: 'HTTPS' }
                               ],
                               egress_rules: [
                                 { from_port: 0, to_port: 0, protocol: '-1',
                                   cidr_blocks: ['0.0.0.0/0'], description: 'All outbound traffic' }
                               ],
                               tags: { Name: "#{name}-security-group" }.merge(config[:tags])
                             })
        end

        def create_launch_template(name, security_group, config)
          aws_launch_template(:"#{name}_launch_template", {
                                name_prefix: "#{name}-lt-",
                                image_id: config[:ami_id],
                                instance_type: config[:instance_type],
                                key_name: config[:key_name],
                                vpc_security_group_ids: [security_group.id],
                                user_data: config[:user_data],
                                tags: { Name: "#{name}-launch-template" }.merge(config[:tags])
                              })
        end

        def create_target_group(name, vpc_ref, config)
          aws_lb_target_group(:"#{name}_target_group", {
                                port: 80,
                                protocol: 'HTTP',
                                vpc_id: vpc_ref.id,
                                target_type: 'instance',
                                health_check: {
                                  enabled: true,
                                  healthy_threshold: 2,
                                  unhealthy_threshold: 2,
                                  timeout: 5,
                                  interval: 30,
                                  path: config[:health_check_path],
                                  matcher: '200'
                                },
                                tags: { Name: "#{name}-target-group" }.merge(config[:tags])
                              })
        end

        def create_auto_scaling_resources(results, name, subnet_refs, config)
          results.auto_scaling_group = aws_autoscaling_group(:"#{name}_asg", {
                                                               min_size: config[:min_instances],
                                                               max_size: config[:max_instances],
                                                               desired_capacity: config[:desired_instances],
                                                               vpc_zone_identifier: subnet_refs.map(&:id),
                                                               launch_template: { id: results.launch_template.id, version: '$Latest' },
                                                               health_check_type: 'ELB',
                                                               health_check_grace_period: 300,
                                                               tags: build_asg_tags(name, config)
                                                             })

          results.asg_attachment = aws_autoscaling_attachment(:"#{name}_asg_attachment", {
                                                                autoscaling_group_name: results.auto_scaling_group.ref(:name),
                                                                lb_target_group_arn: results.target_group.ref(:arn)
                                                              })
        end

        def build_asg_tags(name, config)
          [{ key: 'Name', value: "#{name}-instance", propagate_at_launch: true }]
            .concat(config[:tags].map { |k, v| { key: k.to_s, value: v, propagate_at_launch: true } })
        end

        def create_scaling_policies(results, name)
          results.scale_up_policy = aws_autoscaling_policy(:"#{name}_scale_up", {
                                                             autoscaling_group_name: results.auto_scaling_group.ref(:name),
                                                             adjustment_type: 'ChangeInCapacity',
                                                             scaling_adjustment: 1,
                                                             cooldown: 300
                                                           })

          results.scale_down_policy = aws_autoscaling_policy(:"#{name}_scale_down", {
                                                               autoscaling_group_name: results.auto_scaling_group.ref(:name),
                                                               adjustment_type: 'ChangeInCapacity',
                                                               scaling_adjustment: -1,
                                                               cooldown: 300
                                                             })
        end

        def create_cloudwatch_alarms(results, name)
          results.cpu_high_alarm = aws_cloudwatch_metric_alarm(:"#{name}_cpu_high", {
                                                                 alarm_description: 'Trigger scale up when CPU exceeds 70%',
                                                                 comparison_operator: 'GreaterThanThreshold',
                                                                 evaluation_periods: 2,
                                                                 metric_name: 'CPUUtilization',
                                                                 namespace: 'AWS/EC2',
                                                                 period: 300,
                                                                 statistic: 'Average',
                                                                 threshold: 70,
                                                                 alarm_actions: [results.scale_up_policy.ref(:arn)],
                                                                 dimensions: { AutoScalingGroupName: results.auto_scaling_group.ref(:name) }
                                                               })

          results.cpu_low_alarm = aws_cloudwatch_metric_alarm(:"#{name}_cpu_low", {
                                                                alarm_description: 'Trigger scale down when CPU drops below 30%',
                                                                comparison_operator: 'LessThanThreshold',
                                                                evaluation_periods: 2,
                                                                metric_name: 'CPUUtilization',
                                                                namespace: 'AWS/EC2',
                                                                period: 300,
                                                                statistic: 'Average',
                                                                threshold: 30,
                                                                alarm_actions: [results.scale_down_policy.ref(:arn)],
                                                                dimensions: { AutoScalingGroupName: results.auto_scaling_group.ref(:name) }
                                                              })
        end
      end
    end
  end
end
