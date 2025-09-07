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