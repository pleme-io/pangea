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


require 'terraform-synthesizer'
require 'pangea/resources/base'
require 'pangea/resources/aws_autoscaling_tag/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # AWS Auto Scaling Group Tag resource
      # Creates and manages tags for Auto Scaling Groups with precise control over tag propagation.
      # Enables consistent tagging across Auto Scaling Groups and their launched instances.
      #
      # @example Basic environment and application tags
      #   aws_autoscaling_tag(:web_server_tags, {
      #     autoscaling_group_name: ref(:aws_autoscaling_group, :web_servers, :name),
      #     tags: [
      #       {
      #         key: "Environment",
      #         value: "production",
      #         propagate_at_launch: true
      #       },
      #       {
      #         key: "Application",
      #         value: "web-frontend",
      #         propagate_at_launch: true
      #       },
      #       {
      #         key: "Team",
      #         value: "frontend-team",
      #         propagate_at_launch: false
      #       }
      #     ]
      #   })
      #
      # @example Cost management and compliance tags
      #   aws_autoscaling_tag(:cost_management_tags, {
      #     autoscaling_group_name: ref(:aws_autoscaling_group, :api_servers, :name),
      #     tags: [
      #       {
      #         key: "CostCenter",
      #         value: "engineering-ops",
      #         propagate_at_launch: true
      #       },
      #       {
      #         key: "Project",
      #         value: "customer-api-v2",
      #         propagate_at_launch: true
      #       },
      #       {
      #         key: "Owner",
      #         value: "platform-team",
      #         propagate_at_launch: true
      #       },
      #       {
      #         key: "DataClassification",
      #         value: "internal",
      #         propagate_at_launch: false
      #       }
      #     ]
      #   })
      def aws_autoscaling_tag(name, attributes)
        validated_attributes = Types::Types::AutoScalingTagAttributes.new(attributes)
        
        # Create individual tag resources for each tag
        # AWS requires separate resources for each tag on an ASG
        tag_resources = []
        
        validated_attributes.tags.each_with_index do |tag_spec, index|
          tag_name = :"#{name}_#{tag_spec.key.downcase.gsub(/[^a-z0-9]/, '_')}"
          
          resource :aws_autoscaling_group_tag, tag_name do
            autoscaling_group_name validated_attributes.autoscaling_group_name
            
            tag do
              key tag_spec.key
              value tag_spec.value
              propagate_at_launch tag_spec.propagate_at_launch
            end
          end
          
          tag_resources << ResourceReference.new(
            type: :aws_autoscaling_group_tag,
            name: tag_name,
            attributes: tag_spec,
            terraform_resource: "aws_autoscaling_group_tag.#{tag_name}"
          )
        end
        
        # Return reference for the tag collection
        ResourceReference.new(
          type: :aws_autoscaling_tag,
          name: name,
          attributes: validated_attributes,
          terraform_resource: tag_resources.map(&:terraform_resource),
          tag_resources: tag_resources
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)