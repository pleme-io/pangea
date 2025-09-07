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
require 'pangea/resources/aws_kinesis_video_stream/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Kinesis Video Stream for real-time video and audio streaming
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Kinesis Video Stream attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_kinesis_video_stream(name, attributes = {})
        # Validate attributes using dry-struct
        video_stream_attrs = Types::KinesisVideoStreamAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_kinesis_video_stream, name) do
          name video_stream_attrs.name
          data_retention_in_hours video_stream_attrs.data_retention_in_hours
          device_name video_stream_attrs.device_name if video_stream_attrs.has_device_name?
          media_type video_stream_attrs.media_type
          kms_key_id video_stream_attrs.kms_key_id if video_stream_attrs.is_encrypted?
          
          # Apply tags if present
          if video_stream_attrs.tags.any?
            tags do
              video_stream_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_kinesis_video_stream',
          name: name,
          resource_attributes: video_stream_attrs.to_h,
          outputs: {
            id: "${aws_kinesis_video_stream.#{name}.id}",
            name: "${aws_kinesis_video_stream.#{name}.name}",
            arn: "${aws_kinesis_video_stream.#{name}.arn}",
            version: "${aws_kinesis_video_stream.#{name}.version}",
            creation_time: "${aws_kinesis_video_stream.#{name}.creation_time}",
            data_retention_in_hours: "${aws_kinesis_video_stream.#{name}.data_retention_in_hours}",
            device_name: "${aws_kinesis_video_stream.#{name}.device_name}",
            media_type: "${aws_kinesis_video_stream.#{name}.media_type}",
            kms_key_id: "${aws_kinesis_video_stream.#{name}.kms_key_id}",
            tags_all: "${aws_kinesis_video_stream.#{name}.tags_all}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)