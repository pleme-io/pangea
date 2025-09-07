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
require 'pangea/resources/aws_launch_template/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Launch Template with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Launch Template attributes
      # @option attributes [String, nil] :name Template name (conflicts with name_prefix)
      # @option attributes [String, nil] :name_prefix Template name prefix
      # @option attributes [String, nil] :description Template description
      # @option attributes [Hash] :launch_template_data Launch configuration data
      # @option attributes [Hash] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Basic launch template
      #   template = aws_launch_template(:web_server, {
      #     name: "web-server-template",
      #     description: "Template for web servers",
      #     launch_template_data: {
      #       image_id: "ami-12345678",
      #       instance_type: "t3.micro",
      #       key_name: "my-key",
      #       vpc_security_group_ids: [sg.id],
      #       user_data: Base64.encode64(user_data_script)
      #     },
      #     tags: { Name: "web-server-template" }
      #   })
      #
      # @example Template with block devices and monitoring
      #   template = aws_launch_template(:app_server, {
      #     name_prefix: "app-server-",
      #     launch_template_data: {
      #       image_id: "ami-12345678",
      #       instance_type: "m5.large",
      #       monitoring: { enabled: true },
      #       block_device_mappings: [{
      #         device_name: "/dev/sda1",
      #         ebs: {
      #           volume_size: 100,
      #           volume_type: "gp3",
      #           encrypted: true,
      #           delete_on_termination: true
      #         }
      #       }]
      #     }
      #   })
      def aws_launch_template(name, attributes = {})
        # Validate attributes using dry-struct
        lt_attrs = Types::Types::LaunchTemplateAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_launch_template, name) do
          # Name or name_prefix
          if lt_attrs.name
            __send__(:name, lt_attrs.name)
          elsif lt_attrs.name_prefix
            name_prefix lt_attrs.name_prefix
          end
          
          description lt_attrs.description if lt_attrs.description
          
          # Launch template data block
          if lt_attrs.launch_template_data
            launch_template_data do
              data = lt_attrs.launch_template_data
              
              # Basic instance configuration
              image_id data.image_id if data.image_id
              instance_type data.instance_type if data.instance_type
              key_name data.key_name if data.key_name
              user_data data.user_data if data.user_data
              
              # Security groups
              security_group_ids data.security_group_ids if data.security_group_ids.any?
              vpc_security_group_ids data.vpc_security_group_ids if data.vpc_security_group_ids.any?
              
              # IAM instance profile
              if data.iam_instance_profile
                iam_instance_profile do
                  arn data.iam_instance_profile.arn if data.iam_instance_profile.arn
                  __send__(:name, data.iam_instance_profile.name) if data.iam_instance_profile.name
                end
              end
              
              # Instance behavior
              instance_initiated_shutdown_behavior data.instance_initiated_shutdown_behavior if data.instance_initiated_shutdown_behavior != 'stop'
              disable_api_termination data.disable_api_termination if data.disable_api_termination
              
              # Monitoring
              if data.monitoring
                monitoring do
                  enabled data.monitoring[:enabled]
                end
              end
              
              # Block device mappings
              data.block_device_mappings.each do |bdm|
                block_device_mappings do
                  device_name bdm.device_name
                  no_device bdm.no_device if bdm.no_device
                  virtual_name bdm.virtual_name if bdm.virtual_name
                  
                  if bdm.ebs
                    ebs do
                      delete_on_termination bdm.ebs[:delete_on_termination] if bdm.ebs.key?(:delete_on_termination)
                      encrypted bdm.ebs[:encrypted] if bdm.ebs.key?(:encrypted)
                      iops bdm.ebs[:iops] if bdm.ebs[:iops]
                      kms_key_id bdm.ebs[:kms_key_id] if bdm.ebs[:kms_key_id]
                      snapshot_id bdm.ebs[:snapshot_id] if bdm.ebs[:snapshot_id]
                      throughput bdm.ebs[:throughput] if bdm.ebs[:throughput]
                      volume_size bdm.ebs[:volume_size] if bdm.ebs[:volume_size]
                      volume_type bdm.ebs[:volume_type] if bdm.ebs[:volume_type]
                    end
                  end
                end
              end
              
              # Network interfaces
              data.network_interfaces.each do |ni|
                network_interfaces do
                  associate_public_ip_address ni.associate_public_ip_address unless ni.associate_public_ip_address.nil?
                  delete_on_termination ni.delete_on_termination if ni.delete_on_termination != true
                  description ni.description if ni.description
                  device_index ni.device_index
                  groups ni.groups if ni.groups.any?
                  network_interface_id ni.network_interface_id if ni.network_interface_id
                  private_ip_address ni.private_ip_address if ni.private_ip_address
                  subnet_id ni.subnet_id if ni.subnet_id
                end
              end
              
              # Tag specifications
              data.tag_specifications.each do |ts|
                tag_specifications do
                  resource_type ts.resource_type
                  if ts.tags.any?
                    tags do
                      ts.tags.each do |key, value|
                        public_send(key, value)
                      end
                    end
                  end
                end
              end
            end
          end
          
          # Apply template-level tags
          if lt_attrs.tags.any?
            tags do
              lt_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_launch_template',
          name: name,
          resource_attributes: lt_attrs.to_h,
          outputs: {
            id: "${aws_launch_template.#{name}.id}",
            arn: "${aws_launch_template.#{name}.arn}",
            latest_version: "${aws_launch_template.#{name}.latest_version}",
            default_version: "${aws_launch_template.#{name}.default_version}",
            name: "${aws_launch_template.#{name}.name}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)