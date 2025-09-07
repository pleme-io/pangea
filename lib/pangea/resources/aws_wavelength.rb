# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      # AWS Wavelength - Ultra-low latency applications at the edge of 5G networks
      # Wavelength embeds AWS compute and storage services within 5G networks, providing mobile edge computing infrastructure for developing, deploying, and scaling ultra-low-latency applications
      
      # Create a Carrier Gateway for Wavelength Zones
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Carrier gateway attributes
      # @option attributes [String] :vpc_id (required) The VPC ID
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_ec2_carrier_gateway(name, attributes = {})
        required_attrs = %i[vpc_id]
        optional_attrs = {
          tags: {}
        }
        
        cgw_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless cgw_attrs.key?(attr)
        end
        
        resource(:aws_ec2_carrier_gateway, name) do
          vpc_id cgw_attrs[:vpc_id]
          
          if cgw_attrs[:tags].any?
            tags cgw_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_ec2_carrier_gateway',
          name: name,
          resource_attributes: cgw_attrs,
          outputs: {
            id: "${aws_ec2_carrier_gateway.#{name}.id}",
            arn: "${aws_ec2_carrier_gateway.#{name}.arn}",
            owner_id: "${aws_ec2_carrier_gateway.#{name}.owner_id}",
            state: "${aws_ec2_carrier_gateway.#{name}.state}",
            vpc_id: "${aws_ec2_carrier_gateway.#{name}.vpc_id}"
          }
        )
      end
      
      # Create a Wavelength workload
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Workload attributes
      # @option attributes [String] :workload_name (required) The workload name
      # @option attributes [String] :workload_type (required) The workload type (e.g., "COMPUTE", "STORAGE")
      # @option attributes [String] :wavelength_zone (required) The Wavelength zone
      # @option attributes [Hash] :configuration Workload configuration
      # @option attributes [String] :description Workload description
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_wavelength_workload(name, attributes = {})
        required_attrs = %i[workload_name workload_type wavelength_zone]
        optional_attrs = {
          configuration: {},
          description: nil,
          tags: {}
        }
        
        workload_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless workload_attrs.key?(attr)
        end
        
        resource(:aws_wavelength_workload, name) do
          workload_name workload_attrs[:workload_name]
          workload_type workload_attrs[:workload_type]
          wavelength_zone workload_attrs[:wavelength_zone]
          description workload_attrs[:description] if workload_attrs[:description]
          
          if workload_attrs[:configuration].any?
            configuration workload_attrs[:configuration]
          end
          
          if workload_attrs[:tags].any?
            tags workload_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_wavelength_workload',
          name: name,
          resource_attributes: workload_attrs,
          outputs: {
            id: "${aws_wavelength_workload.#{name}.id}",
            arn: "${aws_wavelength_workload.#{name}.arn}",
            status: "${aws_wavelength_workload.#{name}.status}",
            creation_time: "${aws_wavelength_workload.#{name}.creation_time}"
          }
        )
      end
      
      # Create a Wavelength deployment
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Deployment attributes
      # @option attributes [String] :deployment_name (required) The deployment name
      # @option attributes [String] :workload_id (required) The workload ID
      # @option attributes [String] :deployment_configuration (required) The deployment configuration
      # @option attributes [String] :description Deployment description
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_wavelength_deployment(name, attributes = {})
        required_attrs = %i[deployment_name workload_id deployment_configuration]
        optional_attrs = {
          description: nil,
          tags: {}
        }
        
        deploy_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless deploy_attrs.key?(attr)
        end
        
        resource(:aws_wavelength_deployment, name) do
          deployment_name deploy_attrs[:deployment_name]
          workload_id deploy_attrs[:workload_id]
          deployment_configuration deploy_attrs[:deployment_configuration]
          description deploy_attrs[:description] if deploy_attrs[:description]
          
          if deploy_attrs[:tags].any?
            tags deploy_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_wavelength_deployment',
          name: name,
          resource_attributes: deploy_attrs,
          outputs: {
            id: "${aws_wavelength_deployment.#{name}.id}",
            arn: "${aws_wavelength_deployment.#{name}.arn}",
            status: "${aws_wavelength_deployment.#{name}.status}",
            deployment_url: "${aws_wavelength_deployment.#{name}.deployment_url}"
          }
        )
      end
      
      # Create a Wavelength application deployment
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Application deployment attributes
      # @option attributes [String] :application_name (required) The application name
      # @option attributes [String] :wavelength_zone (required) The Wavelength zone
      # @option attributes [Hash] :application_configuration Application configuration
      # @option attributes [String] :runtime_environment Runtime environment (e.g., "docker", "kubernetes")
      # @option attributes [Hash] :network_configuration Network configuration
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_wavelength_application_deployment(name, attributes = {})
        required_attrs = %i[application_name wavelength_zone]
        optional_attrs = {
          application_configuration: {},
          runtime_environment: "docker",
          network_configuration: {},
          tags: {}
        }
        
        app_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless app_attrs.key?(attr)
        end
        
        resource(:aws_wavelength_application_deployment, name) do
          application_name app_attrs[:application_name]
          wavelength_zone app_attrs[:wavelength_zone]
          runtime_environment app_attrs[:runtime_environment]
          
          if app_attrs[:application_configuration].any?
            application_configuration app_attrs[:application_configuration]
          end
          
          if app_attrs[:network_configuration].any?
            network_configuration app_attrs[:network_configuration]
          end
          
          if app_attrs[:tags].any?
            tags app_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_wavelength_application_deployment',
          name: name,
          resource_attributes: app_attrs,
          outputs: {
            id: "${aws_wavelength_application_deployment.#{name}.id}",
            arn: "${aws_wavelength_application_deployment.#{name}.arn}",
            endpoint_url: "${aws_wavelength_application_deployment.#{name}.endpoint_url}",
            status: "${aws_wavelength_application_deployment.#{name}.status}"
          }
        )
      end
      
      # Create a Wavelength network interface
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Network interface attributes
      # @option attributes [String] :subnet_id (required) The subnet ID (must be in Wavelength zone)
      # @option attributes [String] :description Interface description
      # @option attributes [Array<String>] :security_groups Security group IDs
      # @option attributes [String] :private_ip Private IP address
      # @option attributes [Boolean] :source_dest_check Source/destination check (default: true)
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_wavelength_network_interface(name, attributes = {})
        required_attrs = %i[subnet_id]
        optional_attrs = {
          description: nil,
          security_groups: [],
          private_ip: nil,
          source_dest_check: true,
          tags: {}
        }
        
        eni_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless eni_attrs.key?(attr)
        end
        
        resource(:aws_network_interface, name) do
          subnet_id eni_attrs[:subnet_id]
          description eni_attrs[:description] if eni_attrs[:description]
          security_groups eni_attrs[:security_groups] if eni_attrs[:security_groups].any?
          private_ip eni_attrs[:private_ip] if eni_attrs[:private_ip]
          source_dest_check eni_attrs[:source_dest_check]
          
          if eni_attrs[:tags].any?
            tags eni_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_network_interface',
          name: name,
          resource_attributes: eni_attrs,
          outputs: {
            id: "${aws_network_interface.#{name}.id}",
            arn: "${aws_network_interface.#{name}.arn}",
            mac_address: "${aws_network_interface.#{name}.mac_address}",
            private_dns_name: "${aws_network_interface.#{name}.private_dns_name}",
            private_ip: "${aws_network_interface.#{name}.private_ip}",
            private_ips: "${aws_network_interface.#{name}.private_ips}",
            security_groups: "${aws_network_interface.#{name}.security_groups}",
            subnet_id: "${aws_network_interface.#{name}.subnet_id}"
          }
        )
      end
      
      # Query Wavelength edge location mappings
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Edge location attributes
      # @option attributes [String] :region The AWS region
      # @option attributes [String] :carrier_name The carrier name (e.g., "verizon", "att")
      # @return [ResourceReference] Reference object with outputs
      def aws_wavelength_edge_location_mapping(name, attributes = {})
        optional_attrs = {
          region: nil,
          carrier_name: nil
        }
        
        edge_attrs = optional_attrs.merge(attributes)
        
        data(:aws_availability_zones, name) do
          state "available"
          
          # Filter for Wavelength zones
          filter do
            name "zone-type"
            values ["wavelength-zone"]
          end
          
          if edge_attrs[:region]
            filter do
              name "region-name"
              values [edge_attrs[:region]]
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_availability_zones',
          name: name,
          resource_attributes: edge_attrs,
          outputs: {
            id: "${data.aws_availability_zones.#{name}.id}",
            names: "${data.aws_availability_zones.#{name}.names}",
            zone_ids: "${data.aws_availability_zones.#{name}.zone_ids}",
            group_names: "${data.aws_availability_zones.#{name}.group_names}"
          }
        )
      end
    end
  end
end