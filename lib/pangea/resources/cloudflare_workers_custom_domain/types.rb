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
        # Worker environment enum
        CloudflareWorkerEnvironment = Dry::Types['strict.string'].default('production').enum(
          'production',
          'staging',
          'development'
        )

        # Type-safe attributes for Cloudflare Workers Custom Domain
        #
        # Allows Workers to be accessed via custom domains instead of
        # the default workers.dev subdomain.
        #
        # @example Attach custom domain to worker
        #   WorkersCustomDomainAttributes.new(
        #     account_id: "a" * 32,
        #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        #     hostname: "api.example.com",
        #     service: "api-worker",
        #     environment: "production"
        #   )
        class WorkersCustomDomainAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute account_id
          #   @return [String] The Cloudflare account ID
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId

          # @!attribute zone_id
          #   @return [String] The zone ID containing the hostname
          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId

          # @!attribute hostname
          #   @return [String] Custom hostname for the worker
          attribute :hostname, ::Pangea::Resources::Types::DomainName

          # @!attribute service
          #   @return [String] Worker service name
          attribute :service, Dry::Types['strict.string'].constrained(
            min_size: 1,
            max_size: 256
          )

          # @!attribute environment
          #   @return [String] Worker environment (production, staging, development)
          attribute :environment, CloudflareWorkerEnvironment

          # Check if this is a production environment
          # @return [Boolean] true if environment is production
          def production?
            environment == 'production'
          end

          # Check if hostname is a subdomain
          # @return [Boolean] true if hostname has multiple parts
          def subdomain?
            hostname.split('.').length > 2
          end

          # Get the subdomain part if present
          # @return [String, nil] Subdomain or nil
          def subdomain_part
            parts = hostname.split('.')
            return nil if parts.length <= 2
            parts[0]
          end
        end
      end
    end
  end
end
