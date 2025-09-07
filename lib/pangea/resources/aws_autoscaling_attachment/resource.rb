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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_autoscaling_attachment/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Auto Scaling Attachment to attach an Auto Scaling Group to a load balancer
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Attachment attributes
      # @option attributes [String] :autoscaling_group_name The ASG name (required)
      # @option attributes [String] :elb Classic Load Balancer name
      # @option attributes [String] :lb_target_group_arn Target Group ARN for ALB/NLB
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Attach ASG to ALB Target Group
      #   attachment = aws_autoscaling_attachment(:web_asg_attachment, {
      #     autoscaling_group_name: asg.name,
      #     lb_target_group_arn: target_group.arn
      #   })
      #
      # @example Attach ASG to Classic Load Balancer
      #   attachment = aws_autoscaling_attachment(:classic_attachment, {
      #     autoscaling_group_name: "my-asg",
      #     elb: "my-classic-lb"
      #   })
      def aws_autoscaling_attachment(name, attributes = {})
        # Validate attributes using dry-struct
        attach_attrs = Types::Types::AutoScalingAttachmentAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_autoscaling_attachment, name) do
          autoscaling_group_name attach_attrs.autoscaling_group_name
          
          # Add the appropriate attachment type
          if attach_attrs.elb
            elb attach_attrs.elb
          elsif attach_attrs.lb_target_group_arn
            lb_target_group_arn attach_attrs.lb_target_group_arn
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_autoscaling_attachment',
          name: name,
          resource_attributes: attach_attrs.to_h,
          outputs: {
            id: "${aws_autoscaling_attachment.#{name}.id}",
            autoscaling_group_name: "${aws_autoscaling_attachment.#{name}.autoscaling_group_name}"
          },
          computed_properties: {
            attachment_type: attach_attrs.attachment_type,
            target_arn: attach_attrs.target_arn
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)