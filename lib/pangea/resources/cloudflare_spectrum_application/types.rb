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
        # Spectrum protocol validator (tcp/port or udp/port)
        CloudflareSpectrumProtocol = Dry::Types['strict.string'].constructor do |value|
          unless value.match?(/\A(tcp|udp)\/\d+(-\d+)?\z/)
            raise Dry::Types::ConstraintError, "Protocol must be in format 'tcp/port' or 'udp/port' or 'tcp/port-port'"
          end
          value
        end

        # Edge IP connectivity enum
        CloudflareEdgeIPConnectivity = Dry::Types['strict.string'].enum('all', 'ipv4', 'ipv6')

        # Edge IP type enum
        CloudflareEdgeIPType = Dry::Types['strict.string'].enum('dynamic', 'static')

        # Type-safe attributes for Cloudflare Spectrum Application
        #
        # Spectrum provides DDoS protection and acceleration for any TCP/UDP
        # application running on any port.
        #
        # @example Create SSH Spectrum application
        #   SpectrumApplicationAttributes.new(
        #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        #     protocol: "tcp/22",
        #     dns_name: "ssh.example.com",
        #     dns_type: "CNAME",
        #     origin_direct: ["tcp://192.0.2.1:22"]
        #   )
        class SpectrumApplicationAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute zone_id
          #   @return [String] The zone ID
          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId

          # @!attribute protocol
          #   @return [String] Protocol and port (tcp/22, udp/53, tcp/1000-2000)
          attribute :protocol, CloudflareSpectrumProtocol

          # @!attribute dns_name
          #   @return [String] DNS name for the application
          attribute :dns_name, ::Pangea::Resources::Types::DomainName

          # @!attribute dns_type
          #   @return [String] DNS record type (CNAME or ADDRESS)
          attribute :dns_type, Dry::Types['strict.string'].default('CNAME').enum('CNAME', 'ADDRESS')

          # @!attribute origin_direct
          #   @return [Array<String>, nil] Direct origin addresses
          attribute :origin_direct, Dry::Types['strict.array'].of(
            Dry::Types['strict.string']
          ).optional.default(nil)

          # @!attribute origin_dns_name
          #   @return [String, nil] Origin DNS name
          attribute :origin_dns_name, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute origin_port
          #   @return [Integer, nil] Origin port
          attribute :origin_port, Dry::Types['coercible.integer']
            .constrained(gteq: 1, lteq: 65535)
            .optional
            .default(nil)

          # @!attribute edge_ip_connectivity
          #   @return [String, nil] Edge IP connectivity (all, ipv4, ipv6)
          attribute :edge_ip_connectivity, CloudflareEdgeIPConnectivity.optional.default(nil)

          # @!attribute edge_ip_type
          #   @return [String, nil] Edge IP type (dynamic, static)
          attribute :edge_ip_type, CloudflareEdgeIPType.optional.default(nil)

          # @!attribute ip_firewall
          #   @return [Boolean, nil] Enable IP access rules
          attribute :ip_firewall, ::Pangea::Resources::Types::Bool.optional.default(nil)

          # @!attribute proxy_protocol
          #   @return [String, nil] Enable proxy protocol (off, v1, v2, simple)
          attribute :proxy_protocol, Dry::Types['strict.string']
            .enum('off', 'v1', 'v2', 'simple')
            .optional
            .default(nil)

          # @!attribute tls
          #   @return [String, nil] TLS termination (off, flexible, full, strict)
          attribute :tls, Dry::Types['strict.string']
            .enum('off', 'flexible', 'full', 'strict')
            .optional
            .default(nil)

          # @!attribute traffic_type
          #   @return [String, nil] Traffic type (direct, http, https)
          attribute :traffic_type, Dry::Types['strict.string']
            .enum('direct', 'http', 'https')
            .optional
            .default(nil)

          # Extract protocol type (tcp/udp)
          # @return [String] Protocol type
          def protocol_type
            protocol.split('/').first
          end

          # Extract port or port range
          # @return [String] Port or port range
          def port_range
            protocol.split('/').last
          end

          # Check if this is a port range
          # @return [Boolean] true if port range configured
          def port_range?
            port_range.include?('-')
          end

          # Check if TLS is enabled
          # @return [Boolean] true if TLS mode is not 'off'
          def tls_enabled?
            tls && tls != 'off'
          end
        end
      end
    end
  end
end
