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
require 'pangea/resources/cloudflare_workers_custom_domain/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Workers Custom Domain resource module that self-registers
    module CloudflareWorkersCustomDomain
      # Create a Cloudflare Workers Custom Domain
      #
      # Allows Workers to be accessed via custom domains instead of the
      # default workers.dev subdomain. Perfect for production APIs and services.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Custom domain attributes
      # @option attributes [String] :account_id Cloudflare account ID (required)
      # @option attributes [String] :zone_id Zone ID containing hostname (required)
      # @option attributes [String] :hostname Custom hostname (required)
      # @option attributes [String] :service Worker service name (required)
      # @option attributes [String] :environment Environment (production, staging, development)
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Attach custom domain to API worker
      #   cloudflare_workers_custom_domain(:api_domain, {
      #     account_id: "a" * 32,
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     hostname: "api.example.com",
      #     service: "api-worker",
      #     environment: "production"
      #   })
      #
      # @example Staging environment custom domain
      #   cloudflare_workers_custom_domain(:staging_api, {
      #     account_id: "a" * 32,
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     hostname: "api-staging.example.com",
      #     service: "api-worker",
      #     environment: "staging"
      #   })
      def cloudflare_workers_custom_domain(name, attributes = {})
        # Validate attributes using dry-struct
        domain_attrs = Cloudflare::Types::WorkersCustomDomainAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_workers_custom_domain, name) do
          account_id domain_attrs.account_id
          zone_id domain_attrs.zone_id
          hostname domain_attrs.hostname
          service domain_attrs.service
          environment domain_attrs.environment
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_workers_custom_domain',
          name: name,
          resource_attributes: domain_attrs.to_h,
          outputs: {
            id: "${cloudflare_workers_custom_domain.#{name}.id}",
            domain_id: "${cloudflare_workers_custom_domain.#{name}.id}",
            zone_name: "${cloudflare_workers_custom_domain.#{name}.zone_name}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareWorkersCustomDomain
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
