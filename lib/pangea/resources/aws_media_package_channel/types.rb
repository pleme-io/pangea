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
      # Type-safe attributes for AWS MediaPackage Channel resources
      class MediaPackageChannelAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Channel ID (required) - must be unique within account
        attribute :channel_id, Resources::Types::String

        # Channel description for documentation
        attribute :description, Resources::Types::String.default("")

        # HLS ingest configuration
        attribute :hls_ingest, Resources::Types::Hash.schema(
          ingest_endpoints?: Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              id: Resources::Types::String,
              password?: Resources::Types::String.optional,
              url?: Resources::Types::String.optional,
              username?: Resources::Types::String.optional
            )
          ).optional
        ).default({}.freeze)

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate channel ID format
          unless attrs.channel_id.match?(/^[a-zA-Z0-9_-]{1,256}$/)
            raise Dry::Struct::Error, "Channel ID must be 1-256 characters containing only letters, numbers, underscores, and hyphens"
          end

          # Validate ingest endpoints if provided
          if attrs.hls_ingest[:ingest_endpoints]
            attrs.hls_ingest[:ingest_endpoints].each do |endpoint|
              if endpoint[:id].empty?
                raise Dry::Struct::Error, "Ingest endpoint ID cannot be empty"
              end
              
              # Check for valid endpoint ID format
              unless endpoint[:id].match?(/^[a-zA-Z0-9_-]{1,32}$/)
                raise Dry::Struct::Error, "Ingest endpoint ID must be 1-32 characters containing only letters, numbers, underscores, and hyphens"
              end
            end
          end

          attrs
        end

        # Helper methods
        def has_ingest_endpoints?
          hls_ingest[:ingest_endpoints] && hls_ingest[:ingest_endpoints].any?
        end

        def ingest_endpoint_count
          return 0 unless has_ingest_endpoints?
          hls_ingest[:ingest_endpoints].size
        end

        def primary_ingest_endpoint
          return nil unless has_ingest_endpoints?
          hls_ingest[:ingest_endpoints].first
        end

        def backup_ingest_endpoints
          return [] unless has_ingest_endpoints?
          hls_ingest[:ingest_endpoints][1..-1] || []
        end

        def has_redundant_ingest?
          ingest_endpoint_count > 1
        end

        def channel_id_valid?
          channel_id.match?(/^[a-zA-Z0-9_-]{1,256}$/)
        end
      end
    end
      end
    end
  end
end