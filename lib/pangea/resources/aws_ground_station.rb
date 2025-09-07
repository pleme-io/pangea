# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      # AWS Ground Station - Satellite communications service
      # Ground Station provides satellite communications capabilities to control satellite communications, downlink and process satellite data, and scale satellite operations
      
      # Create a Ground Station contact for satellite communications
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Contact attributes
      # @option attributes [String] :mission_profile_arn (required) Mission profile ARN
      # @option attributes [String] :satellite_arn (required) Satellite ARN
      # @option attributes [String] :start_time (required) Contact start time (ISO format)
      # @option attributes [String] :end_time (required) Contact end time (ISO format)
      # @option attributes [String] :ground_station Ground station ID
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_groundstation_contact(name, attributes = {})
        required_attrs = %i[mission_profile_arn satellite_arn start_time end_time]
        optional_attrs = {
          ground_station: nil,
          tags: {}
        }
        
        contact_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless contact_attrs.key?(attr)
        end
        
        resource(:aws_groundstation_contact, name) do
          mission_profile_arn contact_attrs[:mission_profile_arn]
          satellite_arn contact_attrs[:satellite_arn]
          start_time contact_attrs[:start_time]
          end_time contact_attrs[:end_time]
          ground_station contact_attrs[:ground_station] if contact_attrs[:ground_station]
          
          if contact_attrs[:tags].any?
            tags contact_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_groundstation_contact',
          name: name,
          resource_attributes: contact_attrs,
          outputs: {
            id: "${aws_groundstation_contact.#{name}.id}",
            arn: "${aws_groundstation_contact.#{name}.arn}",
            contact_status: "${aws_groundstation_contact.#{name}.contact_status}",
            error_message: "${aws_groundstation_contact.#{name}.error_message}",
            maximum_elevation: "${aws_groundstation_contact.#{name}.maximum_elevation}",
            post_pass_end_time: "${aws_groundstation_contact.#{name}.post_pass_end_time}",
            pre_pass_start_time: "${aws_groundstation_contact.#{name}.pre_pass_start_time}"
          }
        )
      end
      
      # Create a Ground Station mission profile
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Mission profile attributes
      # @option attributes [String] :profile_name (required) Mission profile name
      # @option attributes [Integer] :minimum_viable_contact_duration_seconds (required) Minimum contact duration in seconds
      # @option attributes [Array<String>] :dataflow_edge_pairs (required) Dataflow edge configuration pairs
      # @option attributes [String] :tracking_config_arn Tracking configuration ARN
      # @option attributes [String] :contact_pre_pass_duration_seconds Pre-pass duration in seconds
      # @option attributes [String] :contact_post_pass_duration_seconds Post-pass duration in seconds
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_groundstation_mission_profile(name, attributes = {})
        required_attrs = %i[profile_name minimum_viable_contact_duration_seconds dataflow_edge_pairs]
        optional_attrs = {
          tracking_config_arn: nil,
          contact_pre_pass_duration_seconds: 120,
          contact_post_pass_duration_seconds: 180,
          tags: {}
        }
        
        profile_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless profile_attrs.key?(attr)
        end
        
        resource(:aws_groundstation_mission_profile, name) do
          name profile_attrs[:profile_name]
          minimum_viable_contact_duration_seconds profile_attrs[:minimum_viable_contact_duration_seconds]
          dataflow_edge_pairs profile_attrs[:dataflow_edge_pairs]
          tracking_config_arn profile_attrs[:tracking_config_arn] if profile_attrs[:tracking_config_arn]
          contact_pre_pass_duration_seconds profile_attrs[:contact_pre_pass_duration_seconds]
          contact_post_pass_duration_seconds profile_attrs[:contact_post_pass_duration_seconds]
          
          if profile_attrs[:tags].any?
            tags profile_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_groundstation_mission_profile',
          name: name,
          resource_attributes: profile_attrs,
          outputs: {
            id: "${aws_groundstation_mission_profile.#{name}.id}",
            arn: "${aws_groundstation_mission_profile.#{name}.arn}",
            mission_profile_id: "${aws_groundstation_mission_profile.#{name}.mission_profile_id}"
          }
        )
      end
      
      # Create a Ground Station configuration
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Configuration attributes
      # @option attributes [String] :config_name (required) Configuration name
      # @option attributes [Hash] :config_data (required) Configuration data specific to config type
      # @option attributes [String] :config_type Configuration type ("antenna-downlink", "antenna-uplink", "dataflow-endpoint", "tracking", "uplink-echo", "s3-recording")
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_groundstation_config(name, attributes = {})
        required_attrs = %i[config_name config_data]
        optional_attrs = {
          config_type: "antenna-downlink",
          tags: {}
        }
        
        config_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless config_attrs.key?(attr)
        end
        
        resource(:aws_groundstation_config, name) do
          name config_attrs[:config_name]
          config_type config_attrs[:config_type]
          config_data config_attrs[:config_data]
          
          if config_attrs[:tags].any?
            tags config_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_groundstation_config',
          name: name,
          resource_attributes: config_attrs,
          outputs: {
            id: "${aws_groundstation_config.#{name}.id}",
            arn: "${aws_groundstation_config.#{name}.arn}",
            config_id: "${aws_groundstation_config.#{name}.config_id}",
            config_type: "${aws_groundstation_config.#{name}.config_type}"
          }
        )
      end
      
      # Create a Ground Station dataflow endpoint group
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Endpoint group attributes
      # @option attributes [Array<Hash>] :endpoints_details (required) Endpoint details
      # @option attributes [String] :contact_pre_pass_duration_seconds Pre-pass duration
      # @option attributes [String] :contact_post_pass_duration_seconds Post-pass duration
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_groundstation_dataflow_endpoint_group(name, attributes = {})
        required_attrs = %i[endpoints_details]
        optional_attrs = {
          contact_pre_pass_duration_seconds: 120,
          contact_post_pass_duration_seconds: 180,
          tags: {}
        }
        
        group_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless group_attrs.key?(attr)
        end
        
        resource(:aws_groundstation_dataflow_endpoint_group, name) do
          endpoints_details group_attrs[:endpoints_details]
          contact_pre_pass_duration_seconds group_attrs[:contact_pre_pass_duration_seconds]
          contact_post_pass_duration_seconds group_attrs[:contact_post_pass_duration_seconds]
          
          if group_attrs[:tags].any?
            tags group_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_groundstation_dataflow_endpoint_group',
          name: name,
          resource_attributes: group_attrs,
          outputs: {
            id: "${aws_groundstation_dataflow_endpoint_group.#{name}.id}",
            arn: "${aws_groundstation_dataflow_endpoint_group.#{name}.arn}",
            endpoints_details: "${aws_groundstation_dataflow_endpoint_group.#{name}.endpoints_details}"
          }
        )
      end
      
      # Create an antenna downlink configuration
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Downlink configuration attributes
      # @option attributes [String] :config_name (required) Configuration name
      # @option attributes [Hash] :spectrum_config (required) Spectrum configuration
      # @option attributes [Hash] :decode_config Decode configuration
      # @option attributes [Hash] :demodulation_config Demodulation configuration
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_groundstation_antenna_downlink_config(name, attributes = {})
        required_attrs = %i[config_name spectrum_config]
        optional_attrs = {
          decode_config: {},
          demodulation_config: {},
          tags: {}
        }
        
        config_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless config_attrs.key?(attr)
        end
        
        # Build antenna downlink config data
        config_data = {
          spectrum_config: config_attrs[:spectrum_config]
        }
        config_data[:decode_config] = config_attrs[:decode_config] if config_attrs[:decode_config].any?
        config_data[:demodulation_config] = config_attrs[:demodulation_config] if config_attrs[:demodulation_config].any?
        
        resource(:aws_groundstation_config, name) do
          name config_attrs[:config_name]
          config_type "antenna-downlink"
          config_data config_data
          
          if config_attrs[:tags].any?
            tags config_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_groundstation_config',
          name: name,
          resource_attributes: config_attrs,
          outputs: {
            id: "${aws_groundstation_config.#{name}.id}",
            arn: "${aws_groundstation_config.#{name}.arn}",
            config_id: "${aws_groundstation_config.#{name}.config_id}"
          }
        )
      end
      
      # Create an antenna uplink configuration
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Uplink configuration attributes
      # @option attributes [String] :config_name (required) Configuration name
      # @option attributes [Hash] :spectrum_config (required) Spectrum configuration
      # @option attributes [Hash] :target_eirp Target EIRP configuration
      # @option attributes [Boolean] :transmit_disabled Disable transmission (default: false)
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_groundstation_antenna_uplink_config(name, attributes = {})
        required_attrs = %i[config_name spectrum_config]
        optional_attrs = {
          target_eirp: {},
          transmit_disabled: false,
          tags: {}
        }
        
        config_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless config_attrs.key?(attr)
        end
        
        # Build antenna uplink config data
        config_data = {
          spectrum_config: config_attrs[:spectrum_config],
          transmit_disabled: config_attrs[:transmit_disabled]
        }
        config_data[:target_eirp] = config_attrs[:target_eirp] if config_attrs[:target_eirp].any?
        
        resource(:aws_groundstation_config, name) do
          name config_attrs[:config_name]
          config_type "antenna-uplink"
          config_data config_data
          
          if config_attrs[:tags].any?
            tags config_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_groundstation_config',
          name: name,
          resource_attributes: config_attrs,
          outputs: {
            id: "${aws_groundstation_config.#{name}.id}",
            arn: "${aws_groundstation_config.#{name}.arn}",
            config_id: "${aws_groundstation_config.#{name}.config_id}"
          }
        )
      end
      
      # Create a tracking configuration
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Tracking configuration attributes
      # @option attributes [String] :config_name (required) Configuration name
      # @option attributes [String] :autotrack (required) Autotrack mode ("PREFERRED", "REMOVED", "REQUIRED")
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_groundstation_tracking_config(name, attributes = {})
        required_attrs = %i[config_name autotrack]
        optional_attrs = {
          tags: {}
        }
        
        config_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless config_attrs.key?(attr)
        end
        
        # Build tracking config data
        config_data = {
          autotrack: config_attrs[:autotrack]
        }
        
        resource(:aws_groundstation_config, name) do
          name config_attrs[:config_name]
          config_type "tracking"
          config_data config_data
          
          if config_attrs[:tags].any?
            tags config_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_groundstation_config',
          name: name,
          resource_attributes: config_attrs,
          outputs: {
            id: "${aws_groundstation_config.#{name}.id}",
            arn: "${aws_groundstation_config.#{name}.arn}",
            config_id: "${aws_groundstation_config.#{name}.config_id}"
          }
        )
      end
    end
  end
end