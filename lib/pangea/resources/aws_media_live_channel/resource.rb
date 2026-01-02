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
require 'pangea/resources/aws_media_live_channel/types'
require 'pangea/resource_registry'

require_relative 'resource/dsl_builder'

module Pangea
  module Resources
    module AWS
      # Create an AWS MediaLive Channel with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] MediaLive channel attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_media_live_channel(name, attributes = {})
        channel_attrs = Types::MediaLiveChannelAttributes.new(attributes)
        builder = MediaLiveChannel::DSLBuilder.new(channel_attrs)

        resource(:aws_medialive_channel, name) do
          name channel_attrs.name
          channel_class channel_attrs.channel_class

          builder.build_input_attachments(self)

          encoder_settings do
            builder.build_encoder_settings(self)
          end

          builder.build_destinations(self)
          builder.build_input_specification(self)

          log_level channel_attrs.log_level

          builder.build_maintenance(self)
          builder.build_reserved_instances(self)

          role_arn channel_attrs.role_arn

          builder.build_vpc(self)
          builder.build_tags(self)
        end

        ResourceReference.new(
          type: 'aws_medialive_channel',
          name: name,
          resource_attributes: channel_attrs.to_h,
          outputs: {
            arn: "${aws_medialive_channel.#{name}.arn}",
            channel_id: "${aws_medialive_channel.#{name}.channel_id}",
            id: "${aws_medialive_channel.#{name}.id}"
          },
          computed: {
            single_pipeline: channel_attrs.single_pipeline?,
            standard_channel: channel_attrs.standard_channel?,
            has_redundancy: channel_attrs.has_redundancy?,
            input_count: channel_attrs.input_count,
            output_group_count: channel_attrs.output_group_count,
            destination_count: channel_attrs.destination_count,
            has_vpc_config: channel_attrs.has_vpc_config?,
            maintenance_scheduled: channel_attrs.maintenance_scheduled?,
            schedule_actions_count: channel_attrs.schedule_actions_count,
            supports_hdr: channel_attrs.supports_hdr?,
            maximum_resolution: channel_attrs.maximum_resolution
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
