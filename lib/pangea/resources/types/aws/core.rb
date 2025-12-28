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
      # AWS Region validation
      AwsRegion = String.enum(
        'us-east-1', 'us-east-2', 'us-west-1', 'us-west-2',
        'eu-west-1', 'eu-west-2', 'eu-central-1',
        'ap-southeast-1', 'ap-southeast-2', 'ap-northeast-1'
      )

      # AWS Availability Zone validation
      AwsAvailabilityZone = String.constrained(format: /\A[a-z]{2}-[a-z]+-\d[a-z]\z/)

      # CIDR block validation
      CidrBlock = String.constrained(format: /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/)

      # Common AWS resource attributes
      AwsTags = Hash.map(Symbol, String).default({}.freeze)

      # Network protocols
      IpProtocol = String.enum('tcp', 'udp', 'icmp', 'icmpv6', 'all', '-1')

      # Port ranges
      Port = Integer.constrained(gteq: 0, lteq: 65535)
      PortRange = Hash.schema(from_port: Port, to_port: Port)

      # Security group rule
      SecurityGroupRule = Hash.schema(
        from_port: Port,
        to_port: Port,
        protocol: IpProtocol,
        cidr_blocks?: Array.of(CidrBlock).default([].freeze),
        security_groups?: Array.of(String).default([].freeze),
        description?: String.optional
      )

      # Instance tenancy
      InstanceTenancy = String.default('default').enum('default', 'dedicated', 'host')

      # EBS volume types
      EbsVolumeType = String.enum('gp2', 'gp3', 'io1', 'io2', 'st1', 'sc1', 'standard')

      # Domain name validation
      DomainName = String.constrained(
        format: /\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)*[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/i
      )

      # Wildcard domain name validation
      WildcardDomainName = String.constrained(
        format: /\A\*\.(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)*[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/i
      )

      # Email address validation
      EmailAddress = String.constrained(format: /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/)

      # AWS Account ID validation
      AwsAccountId = String.constrained(format: /\A\d{12}\z/).constructor { |value|
        unless value.length == 12 && value.match?(/\A\d+\z/)
          raise Dry::Types::ConstraintError, "AWS Account ID must be exactly 12 digits"
        end
        value
      }

      # S3 bucket name validation
      S3BucketName = String.constrained(format: /\A[a-z0-9][a-z0-9\-\.]{1,61}[a-z0-9]\z/).constructor { |value|
        if value.include?('..')
          raise Dry::Types::ConstraintError, "S3 bucket name cannot contain consecutive periods"
        end
        if value.match?(/\A\d+\.\d+\.\d+\.\d+\z/)
          raise Dry::Types::ConstraintError, "S3 bucket name cannot be formatted as IP address"
        end
        if value.start_with?('xn--')
          raise Dry::Types::ConstraintError, "S3 bucket name cannot start with 'xn--'"
        end
        if value.end_with?('-s3alias')
          raise Dry::Types::ConstraintError, "S3 bucket name cannot end with '-s3alias'"
        end
        value
      }

      # Public IP address validation (for customer gateway)
      PublicIpAddress = String.constrained(
        format: /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/
      ).constructor { |value|
        ip_parts = value.split('.').map(&:to_i)
        if ip_parts[0] == 10
          raise Dry::Types::ConstraintError, "Customer Gateway IP cannot be in private range 10.0.0.0/8"
        end
        if ip_parts[0] == 172 && (16..31).include?(ip_parts[1])
          raise Dry::Types::ConstraintError, "Customer Gateway IP cannot be in private range 172.16.0.0/12"
        end
        if ip_parts[0] == 192 && ip_parts[1] == 168
          raise Dry::Types::ConstraintError, "Customer Gateway IP cannot be in private range 192.168.0.0/16"
        end
        value
      }

      # BGP ASN validation (16-bit and 32-bit ASNs)
      BgpAsn = Integer.constrained(gteq: 1, lteq: 4294967295).constructor { |value|
        reserved_asns = [7224, 9059, 10124, 17943]
        if reserved_asns.include?(value)
          raise Dry::Types::ConstraintError, "ASN #{value} is reserved by AWS"
        end
        value
      }

      # POSIX permissions (octal format)
      PosixPermissions = String.constrained(format: /\A[0-7]{3,4}\z/)

      # Unix User/Group IDs
      UnixUserId = Integer.constrained(gteq: 0, lteq: 4294967295)
      UnixGroupId = Integer.constrained(gteq: 0, lteq: 4294967295)
    end
  end
end
