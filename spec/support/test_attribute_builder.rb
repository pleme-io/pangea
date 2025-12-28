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

module Pangea
  module Testing
    # Fluent builder for test attribute creation
    #
    # Provides a clean DSL for creating test data with sensible defaults
    # for each resource type, reducing boilerplate in tests.
    #
    # @example Basic usage
    #   attrs(:aws_vpc).build
    #   # => { cidr_block: "10.0.0.0/16", enable_dns_support: true, ... }
    #
    # @example With customizations
    #   attrs(:aws_vpc).with(cidr_block: "192.168.0.0/16").tagged(Env: "test").build
    #
    # @example For Cloudflare
    #   attrs(:cloudflare_zone).for_domain("example.com").build
    #
    class TestAttributeBuilder
      # Default attributes by resource type
      DEFAULTS = {
        # AWS Core
        aws_vpc: {
          cidr_block: "10.0.0.0/16",
          enable_dns_support: true,
          enable_dns_hostnames: true
        },
        aws_subnet: {
          cidr_block: "10.0.1.0/24",
          availability_zone: "us-east-1a"
        },
        aws_security_group: {
          name: "test-sg",
          description: "Test security group"
        },
        aws_instance: {
          ami: "ami-12345678",
          instance_type: "t3.micro"
        },
        aws_s3_bucket: {
          bucket: "test-bucket"
        },
        aws_iam_role: {
          name: "test-role",
          assume_role_policy: '{"Version":"2012-10-17","Statement":[]}'
        },
        aws_lambda_function: {
          function_name: "test-function",
          runtime: "python3.12",
          handler: "index.handler",
          role: "arn:aws:iam::123456789012:role/lambda-role"
        },

        # Cloudflare
        cloudflare_zone: {
          zone: "example.com",
          plan: "free",
          type: "full"
        },
        cloudflare_record: {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "test",
          type: "A",
          value: "192.0.2.1",
          ttl: 1
        },
        cloudflare_worker_script: {
          name: "test-worker",
          content: "addEventListener('fetch', e => e.respondWith(new Response('ok')))"
        },

        # Hetzner
        hcloud_server: {
          name: "test-server",
          server_type: "cx23",
          image: "ubuntu-22.04",
          location: "fsn1"
        },
        hcloud_network: {
          name: "test-network",
          ip_range: "10.0.0.0/16"
        }
      }.freeze

      attr_reader :resource_type, :attributes, :tags

      def initialize(resource_type)
        @resource_type = resource_type.to_sym
        @attributes = (DEFAULTS[@resource_type] || {}).dup
        @tags = {}
      end

      # Merge additional attributes
      #
      # @param attrs [Hash] Attributes to merge
      # @return [self]
      def with(attrs)
        @attributes.merge!(attrs)
        self
      end

      # Add tags to the resource
      #
      # @param tag_hash [Hash] Tags to add
      # @return [self]
      def tagged(tag_hash)
        @tags.merge!(tag_hash)
        self
      end

      # Set a VPC reference
      #
      # @param vpc_name [Symbol, String] The VPC resource name
      # @return [self]
      def in_vpc(vpc_name)
        @attributes[:vpc_id] = "${aws_vpc.#{vpc_name}.id}"
        self
      end

      # Set a subnet reference
      #
      # @param subnet_name [Symbol, String] The subnet resource name
      # @return [self]
      def in_subnet(subnet_name)
        @attributes[:subnet_id] = "${aws_subnet.#{subnet_name}.id}"
        self
      end

      # Set a security group reference
      #
      # @param sg_names [Array<Symbol, String>] Security group resource names
      # @return [self]
      def with_security_groups(*sg_names)
        @attributes[:security_group_ids] = sg_names.map do |name|
          "${aws_security_group.#{name}.id}"
        end
        self
      end

      # Set a zone ID for Cloudflare resources
      #
      # @param zone_name [Symbol, String] The zone resource name or literal ID
      # @return [self]
      def in_zone(zone_name)
        if zone_name.to_s.match?(/\A[a-f0-9]{32}\z/)
          @attributes[:zone_id] = zone_name.to_s
        else
          @attributes[:zone_id] = "${cloudflare_zone.#{zone_name}.id}"
        end
        self
      end

      # Set domain for Cloudflare zone
      #
      # @param domain [String] The domain name
      # @return [self]
      def for_domain(domain)
        @attributes[:zone] = domain
        self
      end

      # Build the final attributes hash
      #
      # @return [Hash]
      def build
        result = @attributes.dup
        result[:tags] = @tags unless @tags.empty?
        result
      end

      # Build a minimal valid set of attributes
      #
      # @return [Hash]
      def minimal
        case @resource_type
        when :aws_vpc
          { cidr_block: "10.0.0.0/16" }
        when :cloudflare_zone
          { zone: "example.com" }
        when :cloudflare_record
          { zone_id: "023e105f4ecef8ad9ca31a8372d0c353", name: "test", type: "A", value: "192.0.2.1" }
        else
          @attributes
        end
      end
    end
  end
end

# Convenience method to create a builder
#
# @param resource_type [Symbol] The resource type
# @return [Pangea::Testing::TestAttributeBuilder]
def attrs(resource_type)
  Pangea::Testing::TestAttributeBuilder.new(resource_type)
end
