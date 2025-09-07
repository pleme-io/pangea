# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      # AWS Outposts - Bring AWS infrastructure and services on premises
      # Outposts is a fully managed service that extends AWS infrastructure, services, and tools to virtually any datacenter
      
      # Create an Outposts outpost
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Outpost attributes
      # @option attributes [String] :outpost_name (required) The outpost name
      # @option attributes [String] :site_id (required) The site ID
      # @option attributes [String] :availability_zone The availability zone
      # @option attributes [String] :availability_zone_id The availability zone ID
      # @option attributes [String] :description Description of the outpost
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_outposts_outpost(name, attributes = {})
        required_attrs = %i[outpost_name site_id]
        optional_attrs = {
          availability_zone: nil,
          availability_zone_id: nil,
          description: nil,
          tags: {}
        }
        
        outpost_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless outpost_attrs.key?(attr)
        end
        
        resource(:aws_outposts_outpost, name) do
          name outpost_attrs[:outpost_name]
          site_id outpost_attrs[:site_id]
          availability_zone outpost_attrs[:availability_zone] if outpost_attrs[:availability_zone]
          availability_zone_id outpost_attrs[:availability_zone_id] if outpost_attrs[:availability_zone_id]
          description outpost_attrs[:description] if outpost_attrs[:description]
          
          if outpost_attrs[:tags].any?
            tags outpost_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_outposts_outpost',
          name: name,
          resource_attributes: outpost_attrs,
          outputs: {
            id: "${aws_outposts_outpost.#{name}.id}",
            arn: "${aws_outposts_outpost.#{name}.arn}",
            availability_zone: "${aws_outposts_outpost.#{name}.availability_zone}",
            availability_zone_id: "${aws_outposts_outpost.#{name}.availability_zone_id}",
            owner_id: "${aws_outposts_outpost.#{name}.owner_id}",
            site_arn: "${aws_outposts_outpost.#{name}.site_arn}"
          }
        )
      end
      
      # Create an Outposts site
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Site attributes
      # @option attributes [String] :site_name (required) The site name
      # @option attributes [String] :description Description of the site
      # @option attributes [String] :notes Notes about the site
      # @option attributes [Hash] :operating_address Site operating address
      # @option attributes [Hash] :shipping_address Site shipping address
      # @option attributes [Hash] :rack_physical_properties Rack physical properties
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_outposts_site(name, attributes = {})
        required_attrs = %i[site_name]
        optional_attrs = {
          description: nil,
          notes: nil,
          operating_address: {},
          shipping_address: {},
          rack_physical_properties: {},
          tags: {}
        }
        
        site_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless site_attrs.key?(attr)
        end
        
        resource(:aws_outposts_site, name) do
          name site_attrs[:site_name]
          description site_attrs[:description] if site_attrs[:description]
          notes site_attrs[:notes] if site_attrs[:notes]
          
          if site_attrs[:operating_address].any?
            operating_address site_attrs[:operating_address]
          end
          
          if site_attrs[:shipping_address].any?
            shipping_address site_attrs[:shipping_address]
          end
          
          if site_attrs[:rack_physical_properties].any?
            rack_physical_properties site_attrs[:rack_physical_properties]
          end
          
          if site_attrs[:tags].any?
            tags site_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_outposts_site',
          name: name,
          resource_attributes: site_attrs,
          outputs: {
            id: "${aws_outposts_site.#{name}.id}",
            account_id: "${aws_outposts_site.#{name}.account_id}",
            description: "${aws_outposts_site.#{name}.description}",
            name: "${aws_outposts_site.#{name}.name}"
          }
        )
      end
      
      # Create an Outposts capacity task
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Capacity task attributes
      # @option attributes [String] :outpost_identifier (required) The outpost ID
      # @option attributes [Hash] :order (required) The capacity order details
      # @option attributes [Boolean] :dry_run Perform a dry run (default: false)
      # @return [ResourceReference] Reference object with outputs
      def aws_outposts_capacity_task(name, attributes = {})
        required_attrs = %i[outpost_identifier order]
        optional_attrs = {
          dry_run: false
        }
        
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
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Order attributes
      # @option attributes [String] :outpost_id (required) The outpost ID
      # @option attributes [Array<Hash>] :line_items (required) The line items for the order
      # @option attributes [String] :payment_option Payment option (default: "ALL_UPFRONT")
      # @option attributes [String] :payment_term Payment term
      # @return [ResourceReference] Reference object with outputs
      def aws_outposts_order(name, attributes = {})
        required_attrs = %i[outpost_id line_items]
        optional_attrs = {
          payment_option: "ALL_UPFRONT",
          payment_term: nil
        }
        
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
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Connection attributes
      # @option attributes [String] :device_id (required) The device ID
      # @option attributes [String] :connection_name (required) The connection name
      # @option attributes [String] :network_interface_device_index Network interface device index
      # @return [ResourceReference] Reference object with outputs
      def aws_outposts_connection(name, attributes = {})
        required_attrs = %i[device_id connection_name]
        optional_attrs = {
          network_interface_device_index: nil
        }
        
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
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Asset attributes
      # @option attributes [String] :arn (required) The asset ARN
      # @option attributes [String] :asset_id (required) The asset ID
      # @return [ResourceReference] Reference object with outputs
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
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Instance type attributes
      # @option attributes [String] :arn (required) The outpost ARN
      # @return [ResourceReference] Reference object with outputs
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
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Hardware type attributes
      # @return [ResourceReference] Reference object with outputs
      def aws_outposts_supported_hardware_type(name, attributes = {})
        optional_attrs = {}
        
        hw_attrs = optional_attrs.merge(attributes)
        
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