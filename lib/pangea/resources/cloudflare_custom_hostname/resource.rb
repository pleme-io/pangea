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
require 'pangea/resources/cloudflare_custom_hostname/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Custom Hostname resource module that self-registers
    module CloudflareCustomHostname
      # Create a Cloudflare Custom Hostname
      #
      # Custom hostnames allow customers to use their own domains with
      # Cloudflare services via CNAME records (also known as SSL for SaaS).
      #
      # Supports automatic SSL certificate provisioning via Let's Encrypt,
      # DigiCert, or Google Trust Services, with multiple validation methods.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Custom hostname attributes
      # @option attributes [String] :zone_id Zone ID (required)
      # @option attributes [String] :hostname Custom hostname (required, e.g., "app.customer.com")
      # @option attributes [Hash] :ssl SSL configuration
      # @option attributes [String] :custom_origin_server Custom origin server
      # @option attributes [String] :custom_origin_sni Custom origin SNI
      # @option attributes [Hash] :custom_metadata Custom metadata key-value pairs
      # @option attributes [Boolean] :wait_for_ssl_pending_validation Wait for SSL validation
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Basic custom hostname with HTTP validation
      #   cloudflare_custom_hostname(:customer_app, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     hostname: "app.customer.com",
      #     ssl: {
      #       method: "http",
      #       type: "dv",
      #       certificate_authority: "lets_encrypt"
      #     }
      #   })
      #
      # @example Custom hostname with custom origin
      #   cloudflare_custom_hostname(:saas_app, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     hostname: "branded.customer.com",
      #     ssl: {
      #       method: "txt",
      #       certificate_authority: "digicert",
      #       bundle_method: "ubiquitous"
      #     },
      #     custom_origin_server: "origin.myapp.com",
      #     custom_origin_sni: "sni.myapp.com"
      #   })
      #
      # @example Wildcard custom hostname
      #   cloudflare_custom_hostname(:wildcard, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     hostname: "*.customer.com",
      #     ssl: {
      #       method: "txt",
      #       type: "dv_wildcard",
      #       wildcard: true
      #     }
      #   })
      def cloudflare_custom_hostname(name, attributes = {})
        # Validate attributes using dry-struct
        hostname_attrs = Cloudflare::Types::CustomHostnameAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_custom_hostname, name) do
          zone_id hostname_attrs.zone_id
          hostname hostname_attrs.hostname

          # SSL configuration
          if hostname_attrs.ssl
            ssl do
              method hostname_attrs.ssl.method if hostname_attrs.ssl.method
              type hostname_attrs.ssl.type if hostname_attrs.ssl.type
              certificate_authority hostname_attrs.ssl.certificate_authority if hostname_attrs.ssl.certificate_authority
              bundle_method hostname_attrs.ssl.bundle_method if hostname_attrs.ssl.bundle_method
              wildcard hostname_attrs.ssl.wildcard if hostname_attrs.ssl.wildcard

              custom_certificate hostname_attrs.ssl.custom_certificate if hostname_attrs.ssl.custom_certificate
              custom_key hostname_attrs.ssl.custom_key if hostname_attrs.ssl.custom_key

              # SSL settings
              if hostname_attrs.ssl.settings
                settings do
                  min_tls_version hostname_attrs.ssl.settings.min_tls_version if hostname_attrs.ssl.settings.min_tls_version
                  early_hints hostname_attrs.ssl.settings.early_hints if hostname_attrs.ssl.settings.early_hints
                  http2 hostname_attrs.ssl.settings.http2 if hostname_attrs.ssl.settings.http2
                  tls13 hostname_attrs.ssl.settings.tls13 if hostname_attrs.ssl.settings.tls13
                  ciphers hostname_attrs.ssl.settings.ciphers if hostname_attrs.ssl.settings.ciphers
                end
              end
            end
          end

          # Custom origin configuration
          custom_origin_server hostname_attrs.custom_origin_server if hostname_attrs.custom_origin_server
          custom_origin_sni hostname_attrs.custom_origin_sni if hostname_attrs.custom_origin_sni

          # Custom metadata
          if hostname_attrs.custom_metadata
            custom_metadata do
              hostname_attrs.custom_metadata.each do |key, value|
                send(key.to_sym, value)
              end
            end
          end

          # Wait for SSL validation
          wait_for_ssl_pending_validation hostname_attrs.wait_for_ssl_pending_validation if hostname_attrs.wait_for_ssl_pending_validation
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_custom_hostname',
          name: name,
          resource_attributes: hostname_attrs.to_h,
          outputs: {
            id: "${cloudflare_custom_hostname.#{name}.id}",
            status: "${cloudflare_custom_hostname.#{name}.status}",
            ownership_verification: "${cloudflare_custom_hostname.#{name}.ownership_verification}",
            ownership_verification_http: "${cloudflare_custom_hostname.#{name}.ownership_verification_http}",
            ssl_status: "${cloudflare_custom_hostname.#{name}.ssl.0.status}",
            ssl_validation_errors: "${cloudflare_custom_hostname.#{name}.ssl.0.validation_errors}",
            ssl_validation_records: "${cloudflare_custom_hostname.#{name}.ssl.0.validation_records}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareCustomHostname
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
