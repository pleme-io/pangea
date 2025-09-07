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
require 'pangea/resources/aws_media_package_channel/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS MediaPackage Channel with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] MediaPackage channel attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_media_package_channel(name, attributes = {})
        # Validate attributes using dry-struct
        channel_attrs = Types::MediaPackageChannelAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_media_package_channel, name) do
          # Basic configuration
          channel_id channel_attrs.channel_id
          description channel_attrs.description if channel_attrs.description && !channel_attrs.description.empty?
          
          # Apply tags
          if channel_attrs.tags.any?
            tags do
              channel_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_media_package_channel',
          name: name,
          resource_attributes: channel_attrs.to_h,
          outputs: {
            arn: "${aws_media_package_channel.#{name}.arn}",
            channel_id: "${aws_media_package_channel.#{name}.channel_id}",
            hls_ingest: "${aws_media_package_channel.#{name}.hls_ingest}",
            id: "${aws_media_package_channel.#{name}.id}"
          },
          computed: {
            has_ingest_endpoints: channel_attrs.has_ingest_endpoints?,
            ingest_endpoint_count: channel_attrs.ingest_endpoint_count,
            has_redundant_ingest: channel_attrs.has_redundant_ingest?,
            channel_id_valid: channel_attrs.channel_id_valid?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)