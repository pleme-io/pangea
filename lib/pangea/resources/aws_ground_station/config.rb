# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      # Ground Station Configuration methods
      module GroundStationConfig
        # Create a Ground Station configuration
        def aws_groundstation_config(name, attributes = {})
          required_attrs = %i[config_name config_data]
          optional_attrs = { config_type: 'antenna-downlink', tags: {} }

          config_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless config_attrs.key?(attr)
          end

          resource(:aws_groundstation_config, name) do
            name config_attrs[:config_name]
            config_type config_attrs[:config_type]
            config_data config_attrs[:config_data]
            tags config_attrs[:tags] if config_attrs[:tags].any?
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

        # Create an antenna downlink configuration
        def aws_groundstation_antenna_downlink_config(name, attributes = {})
          required_attrs = %i[config_name spectrum_config]
          optional_attrs = { decode_config: {}, demodulation_config: {}, tags: {} }

          config_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless config_attrs.key?(attr)
          end

          config_data = { spectrum_config: config_attrs[:spectrum_config] }
          config_data[:decode_config] = config_attrs[:decode_config] if config_attrs[:decode_config].any?
          config_data[:demodulation_config] = config_attrs[:demodulation_config] if config_attrs[:demodulation_config].any?

          resource(:aws_groundstation_config, name) do
            name config_attrs[:config_name]
            config_type 'antenna-downlink'
            config_data config_data
            tags config_attrs[:tags] if config_attrs[:tags].any?
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
        def aws_groundstation_antenna_uplink_config(name, attributes = {})
          required_attrs = %i[config_name spectrum_config]
          optional_attrs = { target_eirp: {}, transmit_disabled: false, tags: {} }

          config_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless config_attrs.key?(attr)
          end

          config_data = {
            spectrum_config: config_attrs[:spectrum_config],
            transmit_disabled: config_attrs[:transmit_disabled]
          }
          config_data[:target_eirp] = config_attrs[:target_eirp] if config_attrs[:target_eirp].any?

          resource(:aws_groundstation_config, name) do
            name config_attrs[:config_name]
            config_type 'antenna-uplink'
            config_data config_data
            tags config_attrs[:tags] if config_attrs[:tags].any?
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
        def aws_groundstation_tracking_config(name, attributes = {})
          required_attrs = %i[config_name autotrack]
          optional_attrs = { tags: {} }

          config_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless config_attrs.key?(attr)
          end

          config_data = { autotrack: config_attrs[:autotrack] }

          resource(:aws_groundstation_config, name) do
            name config_attrs[:config_name]
            config_type 'tracking'
            config_data config_data
            tags config_attrs[:tags] if config_attrs[:tags].any?
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
end
