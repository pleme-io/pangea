# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'base64'

module Pangea
  module Components
    module AutoScalingWebServersComponent
      module LaunchTemplate
        def create_launch_template(name, component_attrs, component_tag_set)
          user_data_encoded = prepare_user_data(component_attrs)

          aws_launch_template(component_resource_name(name, :launch_template), {
            name: "#{name}-launch-template",
            description: "Launch template for #{name} web servers",
            image_id: component_attrs.ami_id,
            instance_type: component_attrs.instance_type,
            key_name: component_attrs.key_name,
            vpc_security_group_ids: component_attrs.security_group_refs.map(&:id),
            user_data: user_data_encoded,
            iam_instance_profile: component_attrs.iam_instance_profile ? {
              name: component_attrs.iam_instance_profile
            } : nil,
            block_device_mappings: component_attrs.block_device_mappings.map do |bdm|
              {
                device_name: bdm.device_name,
                ebs: {
                  volume_type: bdm.volume_type,
                  volume_size: bdm.volume_size,
                  iops: bdm.iops,
                  throughput: bdm.throughput,
                  encrypted: bdm.encrypted,
                  delete_on_termination: bdm.delete_on_termination
                }.compact
              }
            end,
            metadata_options: component_attrs.metadata_options,
            monitoring: { enabled: component_attrs.monitoring.enabled },
            placement: component_attrs.placement_group ? { group_name: component_attrs.placement_group } : nil,
            tag_specifications: [
              { resource_type: "instance", tags: component_tag_set.merge({ Name: "#{name}-web-server" }) },
              { resource_type: "volume", tags: component_tag_set.merge({ Name: "#{name}-web-server-volume" }) }
            ],
            tags: component_tag_set
          }.compact)
        end

        def prepare_user_data(component_attrs)
          if component_attrs.user_data_base64
            component_attrs.user_data_base64
          elsif component_attrs.user_data
            Base64.strict_encode64(component_attrs.user_data)
          else
            Base64.strict_encode64(default_user_data_script)
          end
        end

        def default_user_data_script
          <<~SCRIPT
            #!/bin/bash
            yum update -y
            yum install -y httpd
            systemctl start httpd
            systemctl enable httpd

            echo '<html><body><h1>Health Check OK</h1></body></html>' > /var/www/html/health

            yum install -y amazon-cloudwatch-agent
            systemctl start amazon-cloudwatch-agent
            systemctl enable amazon-cloudwatch-agent

            /opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${AWS::Region}
          SCRIPT
        end
      end
    end
  end
end
