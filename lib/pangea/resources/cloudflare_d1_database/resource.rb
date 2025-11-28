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
require 'pangea/resources/cloudflare_d1_database/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare D1 Database resource module that self-registers
    module CloudflareD1Database
      # Create a Cloudflare D1 Database
      #
      # D1 is Cloudflare's serverless SQL database built on SQLite.
      # Provides global low-latency access with automatic replication.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Database attributes
      # @option attributes [String] :account_id Cloudflare account ID (required)
      # @option attributes [String] :name Database name (required)
      # @option attributes [String] :primary_location_hint Primary region (optional: wnam, enam, weur, eeur, apac, oc)
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Create a production database
      #   d1_database(:users_db, {
      #     account_id: "a" * 32,
      #     name: "users-production",
      #     primary_location_hint: "wnam"
      #   })
      #
      # @example Create database for EU data residency
      #   d1_database(:gdpr_db, {
      #     account_id: "a" * 32,
      #     name: "eu-customer-data",
      #     primary_location_hint: "weur"
      #   })
      #
      # @example Create database with automatic location
      #   d1_database(:cache_db, {
      #     account_id: "a" * 32,
      #     name: "edge-cache"
      #   })
      def cloudflare_d1_database(name, attributes = {})
        # Validate attributes using dry-struct
        db_attrs = Cloudflare::Types::D1DatabaseAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_d1_database, name) do
          account_id db_attrs.account_id
          name db_attrs.name
          primary_location_hint db_attrs.primary_location_hint if db_attrs.primary_location_hint
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_d1_database',
          name: name,
          resource_attributes: db_attrs.to_h,
          outputs: {
            id: "${cloudflare_d1_database.#{name}.id}",
            database_id: "${cloudflare_d1_database.#{name}.id}",
            database_name: "${cloudflare_d1_database.#{name}.name}",
            version: "${cloudflare_d1_database.#{name}.version}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareD1Database
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
