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
require 'pangea/resources/cloudflare_spectrum_application/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Spectrum Application resource module that self-registers
    module CloudflareSpectrumApplication
      # Create a Cloudflare Spectrum Application
      #
      # Spectrum provides DDoS protection and acceleration for any TCP/UDP
      # application running on any port. Perfect for SSH, gaming, IoT, etc.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Spectrum application attributes
      # @option attributes [String] :zone_id Zone ID (required)
      # @option attributes [String] :protocol Protocol and port (required, e.g., "tcp/22")
      # @option attributes [String] :dns_name DNS name (required)
      # @option attributes [String] :dns_type DNS type (CNAME or ADDRESS)
      # @option attributes [Array<String>] :origin_direct Direct origin addresses
      # @option attributes [String] :origin_dns_name Origin DNS name
      # @option attributes [Integer] :origin_port Origin port
      # @option attributes [String] :edge_ip_connectivity Edge IP connectivity
      # @option attributes [String] :edge_ip_type Edge IP type
      # @option attributes [Boolean] :ip_firewall Enable IP firewall
      # @option attributes [String] :proxy_protocol Proxy protocol mode
      # @option attributes [String] :tls TLS mode
      # @option attributes [String] :traffic_type Traffic type
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example SSH application
      #   cloudflare_spectrum_application(:ssh, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     protocol: "tcp/22",
      #     dns_name: "ssh.example.com",
      #     origin_direct: ["tcp://192.0.2.1:22"]
      #   })
      #
      # @example Gaming server with port range
      #   cloudflare_spectrum_application(:game_server, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     protocol: "udp/27015-27020",
      #     dns_name: "game.example.com",
      #     origin_dns_name: "origin.example.com",
      #     origin_port: 27015
      #   })
      def cloudflare_spectrum_application(name, attributes = {})
        # Validate attributes using dry-struct
        spectrum_attrs = Cloudflare::Types::SpectrumApplicationAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_spectrum_application, name) do
          zone_id spectrum_attrs.zone_id
          protocol spectrum_attrs.protocol

          dns do
            name spectrum_attrs.dns_name
            type spectrum_attrs.dns_type
          end

          if spectrum_attrs.origin_direct
            origin_direct spectrum_attrs.origin_direct
          elsif spectrum_attrs.origin_dns_name
            origin_dns do
              name spectrum_attrs.origin_dns_name
            end
            origin_port spectrum_attrs.origin_port if spectrum_attrs.origin_port
          end

          if spectrum_attrs.edge_ip_connectivity || spectrum_attrs.edge_ip_type
            edge_ips do
              connectivity spectrum_attrs.edge_ip_connectivity if spectrum_attrs.edge_ip_connectivity
              type spectrum_attrs.edge_ip_type if spectrum_attrs.edge_ip_type
            end
          end

          ip_firewall spectrum_attrs.ip_firewall if spectrum_attrs.ip_firewall
          proxy_protocol spectrum_attrs.proxy_protocol if spectrum_attrs.proxy_protocol
          tls spectrum_attrs.tls if spectrum_attrs.tls
          traffic_type spectrum_attrs.traffic_type if spectrum_attrs.traffic_type
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_spectrum_application',
          name: name,
          resource_attributes: spectrum_attrs.to_h,
          outputs: {
            id: "${cloudflare_spectrum_application.#{name}.id}",
            application_id: "${cloudflare_spectrum_application.#{name}.id}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareSpectrumApplication
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
