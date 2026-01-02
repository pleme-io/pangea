# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        module MediaLiveChannel
          # Output group type definitions
          module OutputGroupSettings
            T = Resources::Types

            # Destination reference
            DestinationRef = T::Hash.schema(
              destination_ref_id: T::String
            )

            # Archive group settings
            ArchiveGroupSettings = T::Hash.schema(
              destination: DestinationRef,
              rollover_interval?: T::Integer.optional
            )

            # Frame capture group settings
            FrameCaptureGroupSettings = T::Hash.schema(
              destination: DestinationRef,
              frame_capture_cdn_settings?: T::Hash.optional
            )

            # HLS CDN settings
            HlsAkamaiSettings = T::Hash.schema(
              connection_retry_interval?: T::Integer.optional,
              filecache_duration?: T::Integer.optional,
              http_transfer_mode?: T::String.enum('CHUNKED', 'NON_CHUNKED').optional,
              num_retries?: T::Integer.optional,
              restart_delay?: T::Integer.optional,
              salt?: T::String.optional,
              token?: T::String.optional
            )

            HlsBasicPutSettings = T::Hash.schema(
              connection_retry_interval?: T::Integer.optional,
              filecache_duration?: T::Integer.optional,
              num_retries?: T::Integer.optional,
              restart_delay?: T::Integer.optional
            )

            HlsMediaStoreSettings = T::Hash.schema(
              connection_retry_interval?: T::Integer.optional,
              filecache_duration?: T::Integer.optional,
              media_store_storage_class?: T::String.enum('TEMPORAL').optional,
              num_retries?: T::Integer.optional,
              restart_delay?: T::Integer.optional
            )

            HlsS3Settings = T::Hash.schema(
              canned_acl?: T::String.enum('AUTHENTICATED_READ', 'BUCKET_OWNER_FULL_CONTROL', 'BUCKET_OWNER_READ', 'PUBLIC_READ').optional
            )

            HlsWebdavSettings = T::Hash.schema(
              connection_retry_interval?: T::Integer.optional,
              filecache_duration?: T::Integer.optional,
              http_transfer_mode?: T::String.enum('CHUNKED', 'NON_CHUNKED').optional,
              num_retries?: T::Integer.optional,
              restart_delay?: T::Integer.optional
            )

            HlsCdnSettings = T::Hash.schema(
              hls_akamai_settings?: HlsAkamaiSettings.optional,
              hls_basic_put_settings?: HlsBasicPutSettings.optional,
              hls_media_store_settings?: HlsMediaStoreSettings.optional,
              hls_s3_settings?: HlsS3Settings.optional,
              hls_webdav_settings?: HlsWebdavSettings.optional
            )

            # Key provider settings
            StaticKeySettings = T::Hash.schema(
              key_provider_server?: T::Hash.schema(
                password_param: T::String,
                uri: T::String,
                username: T::String
              ).optional,
              static_key_value: T::String
            )

            KeyProviderSettings = T::Hash.schema(
              static_key_settings?: StaticKeySettings.optional
            )

            # Caption language mapping
            CaptionLanguageMapping = T::Hash.schema(
              caption_channel: T::Integer,
              language_code: T::String,
              language_description: T::String
            )
          end
        end
      end
    end
  end
end
