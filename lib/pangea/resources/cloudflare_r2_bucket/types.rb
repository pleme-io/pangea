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
    module Cloudflare
      module Types
        # R2 bucket location hint enum
        CloudflareR2Location = Dry::Types['strict.string'].enum(
          'apac',  # Asia-Pacific
          'eeur',  # Eastern Europe
          'enam',  # Eastern North America
          'weur',  # Western Europe
          'wnam',  # Western North America
          'oc'     # Oceania
        )

        # Type-safe attributes for Cloudflare R2 Bucket
        #
        # R2 is Cloudflare's S3-compatible object storage with zero egress fees.
        # Buckets are containers for objects with optional location hints.
        #
        # @example Create an R2 bucket
        #   R2BucketAttributes.new(
        #     account_id: "a" * 32,
        #     name: "media-assets",
        #     location: "wnam"
        #   )
        class R2BucketAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute account_id
          #   @return [String] The Cloudflare account ID
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId

          # @!attribute name
          #   @return [String] Bucket name (must be globally unique within account)
          attribute :name, Dry::Types['strict.string'].constrained(
            format: /\A[a-z0-9][a-z0-9-]{1,61}[a-z0-9]\z/,
            min_size: 3,
            max_size: 63
          )

          # @!attribute location
          #   @return [String, nil] Location hint for bucket data
          attribute :location, CloudflareR2Location.optional.default(nil)

          # Get the full region name from location code
          # @return [String, nil] Human-readable region name
          def region_name
            case location
            when 'apac'
              'Asia-Pacific'
            when 'eeur'
              'Eastern Europe'
            when 'enam'
              'Eastern North America'
            when 'weur'
              'Western Europe'
            when 'wnam'
              'Western North America'
            when 'oc'
              'Oceania'
            else
              'Automatic'
            end
          end

          # Check if bucket name follows S3 naming conventions
          # @return [Boolean] true if follows S3 best practices
          def s3_compatible_name?
            # Must not contain uppercase, must not end with dash
            name.match?(/\A[a-z0-9][a-z0-9-]*[a-z0-9]\z/) && !name.include?('..')
          end

          # Generate S3-compatible endpoint URL pattern
          # @return [String] S3 endpoint pattern
          def s3_endpoint
            "<account_id>.r2.cloudflarestorage.com"
          end
        end
      end
    end
  end
end
