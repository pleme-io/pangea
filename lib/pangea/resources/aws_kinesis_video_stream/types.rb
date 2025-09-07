# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Kinesis Video Stream resource attributes with validation
        class KinesisVideoStreamAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name, String.constrained(
            min_size: 1,
            max_size: 256,
            format: /\A[a-zA-Z0-9_\.\-]+\z/
          )
          attribute :data_retention_in_hours, Integer.constrained(gteq: 0, lteq: 87600).default(0) # 0 to 10 years
          attribute :device_name, String.constrained(min_size: 1, max_size: 128).optional
          attribute :media_type, String.constrained(
            format: /\Avideo\/[a-zA-Z0-9\-\+\.]+\z/
          ).default("video/h264")
          
          # KMS encryption configuration
          attribute :kms_key_id, String.optional
          
          # Tags
          attribute :tags, Resources::Types::AwsTags
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate stream name format
            if attrs[:name]
              name = attrs[:name]
              
              # Cannot start or end with underscore or period
              if name.start_with?('_', '.') || name.end_with?('_', '.')
                raise Dry::Struct::Error, "Stream name cannot start or end with underscore or period: #{name}"
              end
              
              # Cannot contain consecutive underscores, periods, or hyphens
              if name.match?(/[_.-]{2,}/)
                raise Dry::Struct::Error, "Stream name cannot contain consecutive underscores, periods, or hyphens: #{name}"
              end
            end
            
            # Validate KMS key ID if provided
            if attrs[:kms_key_id] && !valid_kms_key_id?(attrs[:kms_key_id])
              raise Dry::Struct::Error, "Invalid KMS key ID format: #{attrs[:kms_key_id]}"
            end
            
            # Validate device name format if provided
            if attrs[:device_name]
              device_name = attrs[:device_name]
              unless device_name.match?(/\A[a-zA-Z0-9_\.\-]+\z/)
                raise Dry::Struct::Error, "Device name can only contain alphanumeric characters, underscores, periods, and hyphens: #{device_name}"
              end
              
              if device_name.start_with?('_', '.', '-') || device_name.end_with?('_', '.', '-')
                raise Dry::Struct::Error, "Device name cannot start or end with underscore, period, or hyphen: #{device_name}"
              end
            end
            
            # Validate media type format
            if attrs[:media_type]
              media_type = attrs[:media_type]
              unless media_type.start_with?('video/', 'audio/')
                raise Dry::Struct::Error, "Media type must start with 'video/' or 'audio/': #{media_type}"
              end
            end
            
            super(attrs)
          end
          
          # Validation helpers
          def self.valid_kms_key_id?(key_id)
            # KMS key ID can be:
            # - Key ID: 12345678-1234-1234-1234-123456789012
            # - Key ARN: arn:aws:kms:region:account:key/key-id
            # - Alias name: alias/my-key
            # - Alias ARN: arn:aws:kms:region:account:alias/my-key
            
            # UUID format
            return true if key_id.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
            
            # Key ARN
            return true if key_id.match?(/\Aarn:aws:kms:[a-z0-9-]+:\d{12}:key\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
            
            # Alias name
            return true if key_id.match?(/\Aalias\/[a-zA-Z0-9:/_-]+\z/)
            
            # Alias ARN
            return true if key_id.match?(/\Aarn:aws:kms:[a-z0-9-]+:\d{12}:alias\/[a-zA-Z0-9:/_-]+\z/)
            
            false
          end
          
          # Computed properties
          def is_encrypted?
            !kms_key_id.nil? && !kms_key_id.empty?
          end
          
          def has_retention_configured?
            data_retention_in_hours > 0
          end
          
          def retention_period_days
            return 0 unless has_retention_configured?
            (data_retention_in_hours.to_f / 24.0).round(2)
          end
          
          def retention_period_years
            return 0 unless has_retention_configured?
            (data_retention_in_hours.to_f / (24.0 * 365.0)).round(3)
          end
          
          def is_real_time_only?
            data_retention_in_hours == 0
          end
          
          def is_h264_video?
            media_type.include?('h264')
          end
          
          def is_h265_video?
            media_type.include?('h265') || media_type.include?('hevc')
          end
          
          def is_audio_stream?
            media_type.start_with?('audio/')
          end
          
          def is_video_stream?
            media_type.start_with?('video/')
          end
          
          def has_device_name?
            !device_name.nil? && !device_name.empty?
          end
          
          def estimated_storage_gb_per_hour
            # Rough estimates based on media type and typical bitrates
            case media_type.downcase
            when /h264/
              # H.264: ~1-8 Mbps for typical video streams
              # Assume average 4 Mbps = 0.5 MB/s = 1.8 GB/hour
              1.8
            when /h265/, /hevc/
              # H.265/HEVC: ~50% more efficient than H.264
              # Assume average 2.5 Mbps = 0.31 MB/s = 1.1 GB/hour
              1.1
            when /audio/
              # Audio streams: ~128-320 kbps
              # Assume average 256 kbps = 0.032 MB/s = 0.115 GB/hour
              0.115
            else
              # Generic video estimate
              2.0
            end
          end
          
          def estimated_monthly_storage_gb
            return 0 unless has_retention_configured?
            hours_stored = [data_retention_in_hours, 24 * 30].min # Max 30 days for monthly calc
            estimated_storage_gb_per_hour * hours_stored
          end
          
          def estimated_monthly_cost_usd
            # Kinesis Video Streams pricing (approximate, varies by region)
            ingestion_cost = 0.0085 # $0.0085 per GB ingested
            storage_cost = 0.023   # $0.023 per GB-month stored
            
            # Assume continuous streaming for cost estimation
            monthly_ingestion_gb = estimated_storage_gb_per_hour * 24 * 30 # 30 days
            monthly_storage_gb = estimated_monthly_storage_gb
            
            total_cost = (monthly_ingestion_gb * ingestion_cost) + (monthly_storage_gb * storage_cost)
            total_cost.round(2)
          end
          
          def max_retention_years
            # Maximum retention is 10 years
            10
          end
          
          def streaming_endpoint_format
            "https://{random-id}.kinesisvideo.{region}.amazonaws.com"
          end
          
          def webrtc_signaling_endpoint_format
            "https://{random-id}.kinesisvideo.{region}.amazonaws.com"
          end
          
          # Common media type constants
          def self.media_types
            {
              h264: "video/h264",
              h265: "video/h265", 
              hevc: "video/hevc",
              vp8: "video/vp8",
              vp9: "video/vp9",
              aac: "audio/aac",
              opus: "audio/opus",
              pcm: "audio/pcm",
              mp3: "audio/mpeg"
            }
          end
        end
      end
    end
  end
end