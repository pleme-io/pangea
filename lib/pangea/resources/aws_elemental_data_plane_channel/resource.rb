# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_elemental_data_plane_channel/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Elemental Data Plane Channel with type-safe attributes
      def aws_elemental_data_plane_channel(name, attributes = {})
        channel_attrs = Types::ElementalDataPlaneChannelAttributes.new(attributes)
        
        resource(:aws_elemental_data_plane_channel, name) do
          name channel_attrs.name
          description channel_attrs.description if channel_attrs.description && !channel_attrs.description.empty?
          channel_type channel_attrs.channel_type
          
          if channel_attrs.has_input_specs?
            channel_attrs.input_specifications.each do |spec|
              input_specifications do
                codec spec[:codec]
                maximum_bitrate spec[:maximum_bitrate]
                resolution spec[:resolution]
              end
            end
          end
          
          if channel_attrs.tags.any?
            tags do
              channel_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_elemental_data_plane_channel',
          name: name,
          resource_attributes: channel_attrs.to_h,
          outputs: {
            arn: "${aws_elemental_data_plane_channel.#{name}.arn}",
            id: "${aws_elemental_data_plane_channel.#{name}.id}",
            name: "${aws_elemental_data_plane_channel.#{name}.name}"
          },
          computed: {
            live_channel: channel_attrs.live_channel?,
            playout_channel: channel_attrs.playout_channel?,
            has_input_specs: channel_attrs.has_input_specs?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)