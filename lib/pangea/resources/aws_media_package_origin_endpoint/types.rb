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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS MediaPackage Origin Endpoint resources
      class MediaPackageOriginEndpointAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Channel ID that this endpoint belongs to (required)
        attribute :channel_id, Resources::Types::String

        # Endpoint ID (required) - unique within channel
        attribute :id, Resources::Types::String

        # Endpoint description
        attribute :description, Resources::Types::String.default("")

        # Manifest name for the endpoint
        attribute :manifest_name, Resources::Types::String.default("")

        # HLS package configuration
        attribute :hls_package, Resources::Types::Hash.schema(
          ad_markers?: Resources::Types::String.enum('NONE', 'SCTE35_ENHANCED', 'PASSTHROUGH').optional,
          ad_triggers?: Resources::Types::Array.of(Resources::Types::String).optional,
          ads_on_delivery_restrictions?: Resources::Types::String.enum('NONE', 'RESTRICTED', 'UNRESTRICTED', 'BOTH').optional,
          include_iframe_only_stream?: Resources::Types::Bool.optional,
          playlist_type?: Resources::Types::String.enum('NONE', 'EVENT', 'VOD').optional,
          playlist_window_seconds?: Resources::Types::Integer.optional,
          program_date_time_interval_seconds?: Resources::Types::Integer.optional,
          segment_duration_seconds?: Resources::Types::Integer.optional,
          stream_selection?: Resources::Types::Hash.optional,
          use_audio_rendition_group?: Resources::Types::Bool.optional
        ).default({}.freeze)

        # DASH package configuration
        attribute :dash_package, Resources::Types::Hash.schema(
          ad_triggers?: Resources::Types::Array.of(Resources::Types::String).optional,
          ads_on_delivery_restrictions?: Resources::Types::String.enum('NONE', 'RESTRICTED', 'UNRESTRICTED', 'BOTH').optional,
          manifest_layout?: Resources::Types::String.enum('FULL', 'COMPACT').optional,
          manifest_window_seconds?: Resources::Types::Integer.optional,
          min_buffer_time_seconds?: Resources::Types::Integer.optional,
          min_update_period_seconds?: Resources::Types::Integer.optional,
          profile?: Resources::Types::String.enum('NONE', 'HBBTV_1_5').optional,
          segment_duration_seconds?: Resources::Types::Integer.optional,
          segment_template_format?: Resources::Types::String.enum('NUMBER_WITH_TIMELINE', 'TIME_WITH_TIMELINE', 'NUMBER_WITH_DURATION').optional,
          stream_selection?: Resources::Types::Hash.optional,
          suggested_presentation_delay_seconds?: Resources::Types::Integer.optional,
          utc_timing?: Resources::Types::String.optional,
          utc_timing_uri?: Resources::Types::String.optional
        ).default({}.freeze)

        # CMAF package configuration
        attribute :cmaf_package, Resources::Types::Hash.schema(
          encryption?: Resources::Types::Hash.optional,
          hls_manifests?: Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              ad_markers?: Resources::Types::String.optional,
              id: Resources::Types::String,
              include_iframe_only_stream?: Resources::Types::Bool.optional,
              manifest_name?: Resources::Types::String.optional,
              playlist_type?: Resources::Types::String.optional,
              playlist_window_seconds?: Resources::Types::Integer.optional,
              program_date_time_interval_seconds?: Resources::Types::Integer.optional
            )
          ).optional,
          dash_manifests?: Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              id: Resources::Types::String,
              manifest_layout?: Resources::Types::String.optional,
              manifest_name?: Resources::Types::String.optional,
              manifest_window_seconds?: Resources::Types::Integer.optional,
              min_buffer_time_seconds?: Resources::Types::Integer.optional,
              profile?: Resources::Types::String.optional,
              stream_selection?: Resources::Types::Hash.optional
            )
          ).optional,
          segment_duration_seconds?: Resources::Types::Integer.optional,
          segment_prefix?: Resources::Types::String.optional
        ).default({}.freeze)

        # MSS package configuration
        attribute :mss_package, Resources::Types::Hash.schema(
          manifest_window_seconds?: Resources::Types::Integer.optional,
          segment_duration_seconds?: Resources::Types::Integer.optional,
          stream_selection?: Resources::Types::Hash.optional
        ).default({}.freeze)

        # Start over behavior
        attribute :startover_window_seconds, Resources::Types::Integer.optional

        # Time delay seconds
        attribute :time_delay_seconds, Resources::Types::Integer.optional

        # Whitelist for endpoint access
        attribute :whitelist, Resources::Types::Array.of(Resources::Types::String).default([].freeze)

        # Authorization configuration
        attribute :authorization, Resources::Types::Hash.schema(
          cdn_identifier_secret: Resources::Types::String,
          secrets_role_arn: Resources::Types::String
        ).default({}.freeze)

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate endpoint ID format
          unless attrs.id.match?(/^[a-zA-Z0-9_-]{1,256}$/)
            raise Dry::Struct::Error, "Endpoint ID must be 1-256 characters containing only letters, numbers, underscores, and hyphens"
          end

          # Validate that exactly one package type is specified
          package_types = [attrs.hls_package, attrs.dash_package, attrs.cmaf_package, attrs.mss_package]
          non_empty_packages = package_types.count { |pkg| pkg.any? }
          
          if non_empty_packages != 1
            raise Dry::Struct::Error, "Exactly one package type (HLS, DASH, CMAF, or MSS) must be specified"
          end

          # Validate segment duration
          [attrs.hls_package, attrs.dash_package, attrs.cmaf_package, attrs.mss_package].each do |package|
            if package[:segment_duration_seconds] && !package[:segment_duration_seconds].between?(1, 30)
              raise Dry::Struct::Error, "Segment duration must be between 1 and 30 seconds"
            end
          end

          # Validate playlist window
          if attrs.hls_package[:playlist_window_seconds] && attrs.hls_package[:playlist_window_seconds] < 60
            raise Dry::Struct::Error, "HLS playlist window must be at least 60 seconds"
          end

          attrs
        end

        # Helper methods
        def package_type
          return :hls if hls_package.any?
          return :dash if dash_package.any?
          return :cmaf if cmaf_package.any?
          return :mss if mss_package.any?
          nil
        end

        def has_authorization?
          authorization[:cdn_identifier_secret] && authorization[:secrets_role_arn]
        end

        def has_whitelist?
          whitelist.any?
        end

        def has_startover?
          startover_window_seconds && startover_window_seconds > 0
        end

        def has_time_delay?
          time_delay_seconds && time_delay_seconds > 0
        end

        def supports_ads?
          case package_type
          when :hls
            hls_package[:ad_markers] && hls_package[:ad_markers] != 'NONE'
          when :dash
            dash_package[:ads_on_delivery_restrictions] && dash_package[:ads_on_delivery_restrictions] != 'NONE'
          else
            false
          end
        end
      end
    end
      end
    end
  end
end