# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module SnowFamily
        # Create a DataSync on Snow task
        def aws_datasync_on_snow_task(name, attributes = {})
          required_attrs = %i[source_location_arn destination_location_arn]
          optional_attrs = {
            name: nil,
            options: {},
            schedule: {},
            tags: {}
          }

          task_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless task_attrs.key?(attr)
          end

          resource(:aws_datasync_task, name) do
            source_location_arn task_attrs[:source_location_arn]
            destination_location_arn task_attrs[:destination_location_arn]
            name task_attrs[:name] if task_attrs[:name]

            if task_attrs[:options].any?
              options task_attrs[:options]
            end

            if task_attrs[:schedule].any?
              schedule task_attrs[:schedule]
            end

            if task_attrs[:tags].any?
              tags task_attrs[:tags]
            end
          end

          ResourceReference.new(
            type: 'aws_datasync_task',
            name: name,
            resource_attributes: task_attrs,
            outputs: {
              id: "${aws_datasync_task.#{name}.id}",
              arn: "${aws_datasync_task.#{name}.arn}",
              current_task_execution_arn: "${aws_datasync_task.#{name}.current_task_execution_arn}"
            }
          )
        end

        # Create a DataSync location for Snow devices
        def aws_datasync_on_snow_location(name, attributes = {})
          required_attrs = %i[agent_arns]
          optional_attrs = {
            server_hostname: nil,
            subdirectory: "/",
            tags: {}
          }

          location_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless location_attrs.key?(attr)
          end

          resource(:aws_datasync_location_nfs, name) do
            server_hostname location_attrs[:server_hostname] if location_attrs[:server_hostname]
            subdirectory location_attrs[:subdirectory]

            on_prem_config do
              agent_arns location_attrs[:agent_arns]
            end

            if location_attrs[:tags].any?
              tags location_attrs[:tags]
            end
          end

          ResourceReference.new(
            type: 'aws_datasync_location_nfs',
            name: name,
            resource_attributes: location_attrs,
            outputs: {
              id: "${aws_datasync_location_nfs.#{name}.id}",
              arn: "${aws_datasync_location_nfs.#{name}.arn}",
              uri: "${aws_datasync_location_nfs.#{name}.uri}"
            }
          )
        end

        # Query DataSync agent on Snow Ball Edge
        def aws_datasync_snow_ball_edge(name, attributes = {})
          optional_attrs = {
            ip_address: nil,
            activation_key: nil
          }

          agent_attrs = optional_attrs.merge(attributes)

          resource(:aws_datasync_agent, name) do
            ip_address agent_attrs[:ip_address] if agent_attrs[:ip_address]
            activation_key agent_attrs[:activation_key] if agent_attrs[:activation_key]
          end

          ResourceReference.new(
            type: 'aws_datasync_agent',
            name: name,
            resource_attributes: agent_attrs,
            outputs: {
              id: "${aws_datasync_agent.#{name}.id}",
              arn: "${aws_datasync_agent.#{name}.arn}",
              name: "${aws_datasync_agent.#{name}.name}",
              status: "${aws_datasync_agent.#{name}.status}"
            }
          )
        end
      end
    end
  end
end
