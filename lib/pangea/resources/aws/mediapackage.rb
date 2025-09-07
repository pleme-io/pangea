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


require_relative 'mediapackage/channel'
require_relative 'mediapackage/origin_endpoint'
require_relative 'mediapackage/packaging_configuration'
require_relative 'mediapackage/packaging_group'

module Pangea
  module Resources
    module AWS
      # AWS Elemental MediaPackage service module
      # Provides type-safe resource functions for video streaming and packaging
      module MediaPackage
        # Creates a MediaPackage channel for video stream ingestion
        #
        # @param name [Symbol] Unique name for the channel resource
        # @param attributes [Hash] Configuration attributes for the channel
        # @return [MediaPackage::Channel::ChannelReference] Reference to the created channel
        def aws_mediapackage_channel(name, attributes = {})
          resource = MediaPackage::Channel.new(
            name: name,
            synthesizer: synthesizer,
            attributes: MediaPackage::Channel::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a MediaPackage origin endpoint for content distribution
        #
        # @param name [Symbol] Unique name for the origin endpoint resource
        # @param attributes [Hash] Configuration attributes for the origin endpoint
        # @return [MediaPackage::OriginEndpoint::OriginEndpointReference] Reference to the created origin endpoint
        def aws_mediapackage_origin_endpoint(name, attributes = {})
          resource = MediaPackage::OriginEndpoint.new(
            name: name,
            synthesizer: synthesizer,
            attributes: MediaPackage::OriginEndpoint::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a MediaPackage packaging configuration for video-on-demand content
        #
        # @param name [Symbol] Unique name for the packaging configuration resource
        # @param attributes [Hash] Configuration attributes for the packaging configuration
        # @return [MediaPackage::PackagingConfiguration::PackagingConfigurationReference] Reference to the created packaging configuration
        def aws_mediapackage_packaging_configuration(name, attributes = {})
          resource = MediaPackage::PackagingConfiguration.new(
            name: name,
            synthesizer: synthesizer,
            attributes: MediaPackage::PackagingConfiguration::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a MediaPackage packaging group for organizing packaging configurations
        #
        # @param name [Symbol] Unique name for the packaging group resource
        # @param attributes [Hash] Configuration attributes for the packaging group
        # @return [MediaPackage::PackagingGroup::PackagingGroupReference] Reference to the created packaging group
        def aws_mediapackage_packaging_group(name, attributes = {})
          resource = MediaPackage::PackagingGroup.new(
            name: name,
            synthesizer: synthesizer,
            attributes: MediaPackage::PackagingGroup::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end
      end
    end
  end
end