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

require_relative '../core'

module Pangea
  module Resources
    module Types
      # Hetzner datacenter locations
      HetznerLocation = String.enum(
        'fsn1', 'nbg1', 'hel1', 'ash', 'hil', 'sin'
      )

      # Hetzner server types by series
      HetznerServerType = String.enum(
        'cx23', 'cx33', 'cx43', 'cx53',
        'cax11', 'cax21', 'cax31', 'cax41',
        'cpx11', 'cpx21', 'cpx31', 'cpx41', 'cpx51',
        'ccx13', 'ccx23', 'ccx33', 'ccx43', 'ccx53', 'ccx63'
      )

      # Hetzner network zones
      HetznerNetworkZone = String.enum('eu-central', 'us-east', 'us-west', 'ap-southeast')

      # Hetzner firewall rule direction
      HetznerFirewallDirection = String.enum('in', 'out')

      # Hetzner firewall protocols
      HetznerFirewallProtocol = String.enum('tcp', 'udp', 'icmp', 'esp', 'gre')

      # Hetzner load balancer types
      HetznerLoadBalancerType = String.enum('lb11', 'lb21', 'lb31')

      # Hetzner load balancing algorithms
      HetznerLoadBalancerAlgorithm = String.enum('round_robin', 'least_connections')

      # Hetzner certificate types
      HetznerCertificateType = String.enum('uploaded', 'managed')

      # Hetzner volume filesystem formats
      HetznerVolumeFormat = String.enum('xfs', 'ext4')

      # Hetzner server ID (positive integer)
      HetznerServerId = Integer.constrained(gteq: 1)

      # IPv4 address validation
      HetznerIpv4 = String.constrained(format: /\A(?:[0-9]{1,3}\.){3}[0-9]{1,3}\z/)

      # IPv6 address/range validation
      HetznerIpv6 = String.constrained(format: /\A(?:[0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}(\/\d{1,3})?\z/)

      # Hetzner image name (OS images)
      HetznerImageName = String.constrained(format: /\A[a-z0-9\-\.]+\z/)

      # Hetzner placement group types
      HetznerPlacementGroupType = String.enum('spread')

      # Hetzner load balancer protocol
      HetznerLoadBalancerProtocol = String.enum('http', 'https', 'tcp')

      # Hetzner load balancer health check protocol
      HetznerHealthCheckProtocol = String.enum('http', 'https', 'tcp')

      # Hetzner network subnet type
      HetznerSubnetType = String.enum('cloud', 'server', 'vswitch')

      # Hetzner common labels (like tags)
      HetznerLabels = Hash.map(String, String).default({}.freeze)

      # Hetzner firewall rule
      HetznerFirewallRule = Hash.schema(
        direction: HetznerFirewallDirection,
        protocol: HetznerFirewallProtocol,
        port?: String.optional,
        source_ips?: Array.of(String).optional,
        destination_ips?: Array.of(String).optional,
        description?: String.optional
      )

      # Hetzner DNS record types
      HetznerDnsRecordType = String.enum(
        'A', 'AAAA', 'NS', 'MX', 'CNAME', 'RP', 'TXT', 'SOA', 'HINFO',
        'SRV', 'DANE', 'TLSA', 'DS', 'CAA'
      )

      # Hetzner DNS zone TTL (60-86400 seconds)
      HetznerDnsZoneTtl = Integer.constrained(gteq: 60, lteq: 86400).default(86400)

      # Hetzner DNS record TTL
      HetznerDnsRecordTtl = Integer.constrained(gteq: 60, lteq: 86400)

      # Hetzner snapshot type
      HetznerSnapshotType = String.enum('snapshot')

      # Hetzner PEM certificate validation
      HetznerPemCertificate = String.constructor { |value|
        unless value.strip.start_with?('-----BEGIN CERTIFICATE-----')
          raise Dry::Types::ConstraintError, "Certificate must be in PEM format starting with '-----BEGIN CERTIFICATE-----'"
        end
        unless value.strip.end_with?('-----END CERTIFICATE-----')
          raise Dry::Types::ConstraintError, "Certificate must be in PEM format ending with '-----END CERTIFICATE-----'"
        end
        value
      }

      # Hetzner PEM private key validation
      HetznerPemPrivateKey = String.constructor { |value|
        valid_headers = [
          '-----BEGIN PRIVATE KEY-----',
          '-----BEGIN RSA PRIVATE KEY-----',
          '-----BEGIN EC PRIVATE KEY-----',
          '-----BEGIN ENCRYPTED PRIVATE KEY-----'
        ]
        unless valid_headers.any? { |header| value.strip.start_with?(header) }
          raise Dry::Types::ConstraintError, "Private key must be in PEM format"
        end
        value
      }

      # Hetzner volume size validation (10-10000 GB)
      HetznerVolumeSize = Integer.constrained(gteq: 10, lteq: 10000)
    end
  end
end
