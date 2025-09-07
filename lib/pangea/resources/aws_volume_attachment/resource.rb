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
require 'pangea/resources/aws_volume_attachment/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EBS Volume Attachment with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_volume_attachment(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::VolumeAttachmentAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_volume_attachment, name) do
          # Required attributes
          device_name attrs.device_name
          instance_id attrs.instance_id
          volume_id attrs.volume_id
          
          # Optional attributes (only include if explicitly set to true)
          force_detach attrs.force_detach if attrs.force_detach
          skip_destroy attrs.skip_destroy if attrs.skip_destroy
          stop_instance_before_detaching attrs.stop_instance_before_detaching if attrs.stop_instance_before_detaching
          
          # Apply tags if present
          if attrs.tags.any?
            tags do
              attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_volume_attachment',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            device_name: "${aws_volume_attachment.#{name}.device_name}",
            instance_id: "${aws_volume_attachment.#{name}.instance_id}",
            volume_id: "${aws_volume_attachment.#{name}.volume_id}",
            force_detach: "${aws_volume_attachment.#{name}.force_detach}",
            skip_destroy: "${aws_volume_attachment.#{name}.skip_destroy}",
            stop_instance_before_detaching: "${aws_volume_attachment.#{name}.stop_instance_before_detaching}",
            tags_all: "${aws_volume_attachment.#{name}.tags_all}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)