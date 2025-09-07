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
require 'pangea/resources/aws_media_package_origin_endpoint/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS MediaPackage Origin Endpoint with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] MediaPackage origin endpoint attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_media_package_origin_endpoint(name, attributes = {})
        # Validate attributes using dry-struct
        endpoint_attrs = Types::MediaPackageOriginEndpointAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_media_package_origin_endpoint, name) do
          # Basic configuration
          channel_id endpoint_attrs.channel_id
          id endpoint_attrs.id
          description endpoint_attrs.description if endpoint_attrs.description && !endpoint_attrs.description.empty?
          manifest_name endpoint_attrs.manifest_name if endpoint_attrs.manifest_name && !endpoint_attrs.manifest_name.empty?
          
          # HLS package
          if endpoint_attrs.hls_package.any?
            hls_package do
              ad_markers endpoint_attrs.hls_package[:ad_markers] if endpoint_attrs.hls_package[:ad_markers]
              ad_triggers endpoint_attrs.hls_package[:ad_triggers] if endpoint_attrs.hls_package[:ad_triggers]
              ads_on_delivery_restrictions endpoint_attrs.hls_package[:ads_on_delivery_restrictions] if endpoint_attrs.hls_package[:ads_on_delivery_restrictions]
              include_iframe_only_stream endpoint_attrs.hls_package[:include_iframe_only_stream] if endpoint_attrs.hls_package.key?(:include_iframe_only_stream)
              playlist_type endpoint_attrs.hls_package[:playlist_type] if endpoint_attrs.hls_package[:playlist_type]
              playlist_window_seconds endpoint_attrs.hls_package[:playlist_window_seconds] if endpoint_attrs.hls_package[:playlist_window_seconds]
              program_date_time_interval_seconds endpoint_attrs.hls_package[:program_date_time_interval_seconds] if endpoint_attrs.hls_package[:program_date_time_interval_seconds]
              segment_duration_seconds endpoint_attrs.hls_package[:segment_duration_seconds] if endpoint_attrs.hls_package[:segment_duration_seconds]
              use_audio_rendition_group endpoint_attrs.hls_package[:use_audio_rendition_group] if endpoint_attrs.hls_package.key?(:use_audio_rendition_group)
              
              if endpoint_attrs.hls_package[:stream_selection]
                stream_selection do
                  # Stream selection configuration would go here
                end
              end
            end
          end
          
          # DASH package
          if endpoint_attrs.dash_package.any?
            dash_package do
              ad_triggers endpoint_attrs.dash_package[:ad_triggers] if endpoint_attrs.dash_package[:ad_triggers]
              ads_on_delivery_restrictions endpoint_attrs.dash_package[:ads_on_delivery_restrictions] if endpoint_attrs.dash_package[:ads_on_delivery_restrictions]
              manifest_layout endpoint_attrs.dash_package[:manifest_layout] if endpoint_attrs.dash_package[:manifest_layout]
              manifest_window_seconds endpoint_attrs.dash_package[:manifest_window_seconds] if endpoint_attrs.dash_package[:manifest_window_seconds]
              min_buffer_time_seconds endpoint_attrs.dash_package[:min_buffer_time_seconds] if endpoint_attrs.dash_package[:min_buffer_time_seconds]
              min_update_period_seconds endpoint_attrs.dash_package[:min_update_period_seconds] if endpoint_attrs.dash_package[:min_update_period_seconds]
              profile endpoint_attrs.dash_package[:profile] if endpoint_attrs.dash_package[:profile]
              segment_duration_seconds endpoint_attrs.dash_package[:segment_duration_seconds] if endpoint_attrs.dash_package[:segment_duration_seconds]
              segment_template_format endpoint_attrs.dash_package[:segment_template_format] if endpoint_attrs.dash_package[:segment_template_format]
              suggested_presentation_delay_seconds endpoint_attrs.dash_package[:suggested_presentation_delay_seconds] if endpoint_attrs.dash_package[:suggested_presentation_delay_seconds]
              utc_timing endpoint_attrs.dash_package[:utc_timing] if endpoint_attrs.dash_package[:utc_timing]
              utc_timing_uri endpoint_attrs.dash_package[:utc_timing_uri] if endpoint_attrs.dash_package[:utc_timing_uri]
              
              if endpoint_attrs.dash_package[:stream_selection]
                stream_selection do
                  # Stream selection configuration would go here
                end
              end
            end
          end
          
          # CMAF package
          if endpoint_attrs.cmaf_package.any?
            cmaf_package do
              segment_duration_seconds endpoint_attrs.cmaf_package[:segment_duration_seconds] if endpoint_attrs.cmaf_package[:segment_duration_seconds]
              segment_prefix endpoint_attrs.cmaf_package[:segment_prefix] if endpoint_attrs.cmaf_package[:segment_prefix]
              
              if endpoint_attrs.cmaf_package[:hls_manifests]
                endpoint_attrs.cmaf_package[:hls_manifests].each do |manifest|
                  hls_manifests do
                    ad_markers manifest[:ad_markers] if manifest[:ad_markers]
                    id manifest[:id]
                    include_iframe_only_stream manifest[:include_iframe_only_stream] if manifest.key?(:include_iframe_only_stream)
                    manifest_name manifest[:manifest_name] if manifest[:manifest_name]
                    playlist_type manifest[:playlist_type] if manifest[:playlist_type]
                    playlist_window_seconds manifest[:playlist_window_seconds] if manifest[:playlist_window_seconds]
                    program_date_time_interval_seconds manifest[:program_date_time_interval_seconds] if manifest[:program_date_time_interval_seconds]
                  end
                end
              end
              
              if endpoint_attrs.cmaf_package[:dash_manifests]
                endpoint_attrs.cmaf_package[:dash_manifests].each do |manifest|
                  dash_manifests do
                    id manifest[:id]
                    manifest_layout manifest[:manifest_layout] if manifest[:manifest_layout]
                    manifest_name manifest[:manifest_name] if manifest[:manifest_name]
                    manifest_window_seconds manifest[:manifest_window_seconds] if manifest[:manifest_window_seconds]
                    min_buffer_time_seconds manifest[:min_buffer_time_seconds] if manifest[:min_buffer_time_seconds]
                    profile manifest[:profile] if manifest[:profile]
                    
                    if manifest[:stream_selection]
                      stream_selection do
                        # Stream selection configuration
                      end
                    end
                  end
                end
              end
            end
          end
          
          # MSS package
          if endpoint_attrs.mss_package.any?
            mss_package do
              manifest_window_seconds endpoint_attrs.mss_package[:manifest_window_seconds] if endpoint_attrs.mss_package[:manifest_window_seconds]
              segment_duration_seconds endpoint_attrs.mss_package[:segment_duration_seconds] if endpoint_attrs.mss_package[:segment_duration_seconds]
              
              if endpoint_attrs.mss_package[:stream_selection]
                stream_selection do
                  # Stream selection configuration
                end
              end
            end
          end
          
          # Optional configurations
          startover_window_seconds endpoint_attrs.startover_window_seconds if endpoint_attrs.startover_window_seconds
          time_delay_seconds endpoint_attrs.time_delay_seconds if endpoint_attrs.time_delay_seconds
          whitelist endpoint_attrs.whitelist if endpoint_attrs.whitelist.any?
          
          # Authorization
          if endpoint_attrs.has_authorization?
            authorization do
              cdn_identifier_secret endpoint_attrs.authorization[:cdn_identifier_secret]
              secrets_role_arn endpoint_attrs.authorization[:secrets_role_arn]
            end
          end
          
          # Apply tags
          if endpoint_attrs.tags.any?
            tags do
              endpoint_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_media_package_origin_endpoint',
          name: name,
          resource_attributes: endpoint_attrs.to_h,
          outputs: {
            arn: "${aws_media_package_origin_endpoint.#{name}.arn}",
            id: "${aws_media_package_origin_endpoint.#{name}.id}",
            url: "${aws_media_package_origin_endpoint.#{name}.url}"
          },
          computed: {
            package_type: endpoint_attrs.package_type,
            has_authorization: endpoint_attrs.has_authorization?,
            has_whitelist: endpoint_attrs.has_whitelist?,
            has_startover: endpoint_attrs.has_startover?,
            has_time_delay: endpoint_attrs.has_time_delay?,
            supports_ads: endpoint_attrs.supports_ads?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)