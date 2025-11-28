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
        # D1 database primary location hint enum
        CloudflareD1Location = Dry::Types['strict.string'].enum(
          'wnam',  # Western North America
          'enam',  # Eastern North America
          'weur',  # Western Europe
          'eeur',  # Eastern Europe
          'apac',  # Asia-Pacific
          'oc'     # Oceania
        )

        # Type-safe attributes for Cloudflare D1 Database
        #
        # D1 is Cloudflare's serverless SQL database built on SQLite.
        # Perfect for relational data with global low-latency access.
        #
        # @example Create a D1 database
        #   D1DatabaseAttributes.new(
        #     account_id: "a" * 32,
        #     name: "production-db",
        #     primary_location_hint: "wnam"
        #   )
        class D1DatabaseAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute account_id
          #   @return [String] The Cloudflare account ID
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId

          # @!attribute name
          #   @return [String] Database name (human-readable identifier)
          attribute :name, Dry::Types['strict.string'].constrained(
            min_size: 1,
            max_size: 256
          )

          # @!attribute primary_location_hint
          #   @return [String, nil] Primary location hint for database
          attribute :primary_location_hint, CloudflareD1Location.optional.default(nil)

          # Get the full region name from location code
          # @return [String, nil] Human-readable region name
          def region_name
            case primary_location_hint
            when 'wnam'
              'Western North America'
            when 'enam'
              'Eastern North America'
            when 'weur'
              'Western Europe'
            when 'eeur'
              'Eastern Europe'
            when 'apac'
              'Asia-Pacific'
            when 'oc'
              'Oceania'
            else
              'Automatic'
            end
          end

          # Extract environment from name if present
          # @return [String, nil] Environment name if detected
          def environment
            case name.downcase
            when /production|prod/
              'production'
            when /staging|stage/
              'staging'
            when /development|dev/
              'development'
            when /test/
              'test'
            else
              nil
            end
          end

          # Check if this is a production database based on naming
          # @return [Boolean] true if appears to be production
          def production?
            environment == 'production'
          end
        end
      end
    end
  end
end
