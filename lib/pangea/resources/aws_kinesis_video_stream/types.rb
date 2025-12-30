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
require_relative 'types/kms_validation'
require_relative 'types/media_type_helpers'
require_relative 'types/storage_estimation'

module Pangea
  module Resources
    module AWS
      module Types
        # Kinesis Video Stream resource attributes with validation
        class KinesisVideoStreamAttributes < Dry::Struct
          include KmsValidation
          include MediaTypeHelpers
          include StorageEstimation

          transform_keys(&:to_sym)

          attribute :name, String.constrained(
            min_size: 1,
            max_size: 256,
            format: /\A[a-zA-Z0-9_\.\-]+\z/
          )
          attribute :data_retention_in_hours, Integer.constrained(gteq: 0, lteq: 87600).default(0)
          attribute :device_name, String.constrained(min_size: 1, max_size: 128).optional
          attribute :media_type, String.constrained(
            format: /\Avideo\/[a-zA-Z0-9\-\+\.]+\z/
          ).default("video/h264")
          attribute :kms_key_id, String.optional
          attribute :tags, Resources::Types::AwsTags

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            validate_stream_name(attrs[:name]) if attrs[:name]
            validate_kms_key(attrs[:kms_key_id]) if attrs[:kms_key_id]
            validate_device_name(attrs[:device_name]) if attrs[:device_name]
            validate_media_type(attrs[:media_type]) if attrs[:media_type]

            super(attrs)
          end

          def self.validate_stream_name(name)
            if name.start_with?('_', '.') || name.end_with?('_', '.')
              raise Dry::Struct::Error, "Stream name cannot start or end with underscore or period: #{name}"
            end

            return unless name.match?(/[_.-]{2,}/)

            raise Dry::Struct::Error, "Stream name cannot contain consecutive underscores, periods, or hyphens: #{name}"
          end

          def self.validate_kms_key(kms_key_id)
            return if KmsValidation.valid_kms_key_id?(kms_key_id)

            raise Dry::Struct::Error, "Invalid KMS key ID format: #{kms_key_id}"
          end

          def self.validate_device_name(device_name)
            unless device_name.match?(/\A[a-zA-Z0-9_\.\-]+\z/)
              raise Dry::Struct::Error,
                    "Device name can only contain alphanumeric characters, underscores, periods, and hyphens: #{device_name}"
            end

            return unless device_name.start_with?('_', '.', '-') || device_name.end_with?('_', '.', '-')

            raise Dry::Struct::Error, "Device name cannot start or end with underscore, period, or hyphen: #{device_name}"
          end

          def self.validate_media_type(media_type)
            return if media_type.start_with?('video/', 'audio/')

            raise Dry::Struct::Error, "Media type must start with 'video/' or 'audio/': #{media_type}"
          end

          def self.media_types
            MediaTypeHelpers::MEDIA_TYPES
          end

          # Retention computed properties
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

          def has_device_name?
            !device_name.nil? && !device_name.empty?
          end

          def max_retention_years
            10
          end
        end
      end
    end
  end
end
