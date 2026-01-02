# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module OutpostsResources
        # Create an Outposts capacity task
        def aws_outposts_capacity_task(name, attributes = {})
          required_attrs = %i[outpost_identifier order]
          optional_attrs = { dry_run: false }

          task_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless task_attrs.key?(attr)
          end

          resource(:aws_outposts_capacity_task, name) do
            outpost_identifier task_attrs[:outpost_identifier]
            order task_attrs[:order]
            dry_run task_attrs[:dry_run]
          end

          ResourceReference.new(
            type: 'aws_outposts_capacity_task',
            name: name,
            resource_attributes: task_attrs,
            outputs: {
              id: "${aws_outposts_capacity_task.#{name}.id}",
              capacity_task_status: "${aws_outposts_capacity_task.#{name}.capacity_task_status}",
              completed_date: "${aws_outposts_capacity_task.#{name}.completed_date}",
              creation_date: "${aws_outposts_capacity_task.#{name}.creation_date}",
              last_modified_date: "${aws_outposts_capacity_task.#{name}.last_modified_date}"
            }
          )
        end

        # Create an Outposts order
        def aws_outposts_order(name, attributes = {})
          required_attrs = %i[outpost_id line_items]
          optional_attrs = { payment_option: "ALL_UPFRONT", payment_term: nil }

          order_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless order_attrs.key?(attr)
          end

          resource(:aws_outposts_order, name) do
            outpost_id order_attrs[:outpost_id]
            line_items order_attrs[:line_items]
            payment_option order_attrs[:payment_option]
            payment_term order_attrs[:payment_term] if order_attrs[:payment_term]
          end

          ResourceReference.new(
            type: 'aws_outposts_order',
            name: name,
            resource_attributes: order_attrs,
            outputs: {
              id: "${aws_outposts_order.#{name}.id}",
              order_submission_date: "${aws_outposts_order.#{name}.order_submission_date}",
              order_type: "${aws_outposts_order.#{name}.order_type}",
              status: "${aws_outposts_order.#{name}.status}"
            }
          )
        end

        # Create an Outposts connection
        def aws_outposts_connection(name, attributes = {})
          required_attrs = %i[device_id connection_name]
          optional_attrs = { network_interface_device_index: nil }

          conn_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless conn_attrs.key?(attr)
          end

          resource(:aws_outposts_connection, name) do
            device_id conn_attrs[:device_id]
            name conn_attrs[:connection_name]
            network_interface_device_index conn_attrs[:network_interface_device_index] if conn_attrs[:network_interface_device_index]
          end

          ResourceReference.new(
            type: 'aws_outposts_connection',
            name: name,
            resource_attributes: conn_attrs,
            outputs: {
              id: "${aws_outposts_connection.#{name}.id}",
              status: "${aws_outposts_connection.#{name}.status}",
              provider_name: "${aws_outposts_connection.#{name}.provider_name}"
            }
          )
        end

        # Query Outposts assets
        def aws_outposts_asset(name, attributes = {})
          required_attrs = %i[arn asset_id]
          asset_attrs = attributes

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless asset_attrs.key?(attr)
          end

          data(:aws_outposts_asset, name) do
            arn asset_attrs[:arn]
            asset_id asset_attrs[:asset_id]
          end

          ResourceReference.new(
            type: 'aws_outposts_asset',
            name: name,
            resource_attributes: asset_attrs,
            outputs: {
              id: "${data.aws_outposts_asset.#{name}.id}",
              asset_type: "${data.aws_outposts_asset.#{name}.asset_type}",
              host_id: "${data.aws_outposts_asset.#{name}.host_id}",
              rack_elevation: "${data.aws_outposts_asset.#{name}.rack_elevation}",
              rack_id: "${data.aws_outposts_asset.#{name}.rack_id}"
            }
          )
        end

        # Query Outposts instance types for an outpost
        def aws_outposts_outpost_instance_type(name, attributes = {})
          required_attrs = %i[arn]
          type_attrs = attributes

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless type_attrs.key?(attr)
          end

          data(:aws_outposts_outpost_instance_types, name) do
            arn type_attrs[:arn]
          end

          ResourceReference.new(
            type: 'aws_outposts_outpost_instance_types',
            name: name,
            resource_attributes: type_attrs,
            outputs: {
              id: "${data.aws_outposts_outpost_instance_types.#{name}.id}",
              instance_types: "${data.aws_outposts_outpost_instance_types.#{name}.instance_types}"
            }
          )
        end

        # Query supported hardware types for Outposts
        def aws_outposts_supported_hardware_type(name, attributes = {})
          hw_attrs = attributes

          data(:aws_outposts_assets, name) do
            # This data source doesn't require any arguments
          end

          ResourceReference.new(
            type: 'aws_outposts_assets',
            name: name,
            resource_attributes: hw_attrs,
            outputs: {
              id: "${data.aws_outposts_assets.#{name}.id}",
              asset_ids: "${data.aws_outposts_assets.#{name}.asset_ids}"
            }
          )
        end
      end
    end
  end
end
