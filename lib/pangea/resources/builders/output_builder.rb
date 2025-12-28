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
  module Resources
    module Builders
      # Builds Terraform output interpolation strings for resources
      #
      # Eliminates repetitive output definition code across resources by
      # providing a declarative way to specify which outputs a resource exposes.
      #
      # @example Basic usage
      #   OutputBuilder.new(:aws_vpc, :main).build
      #   # => { id: "${aws_vpc.main.id}" }
      #
      # @example With additional outputs
      #   OutputBuilder.new(:aws_vpc, :main, :arn, :cidr_block).build
      #   # => { id: "${aws_vpc.main.id}", arn: "${aws_vpc.main.arn}", cidr_block: "..." }
      #
      # @example Using output presets
      #   OutputBuilder.new(:aws_s3_bucket, :mybucket).with_preset(:s3_bucket).build
      #
      class OutputBuilder
        # Common output patterns by provider prefix
        COMMON_OUTPUTS = {
          aws: [:id, :arn],
          cloudflare: [:id],
          hcloud: [:id]
        }.freeze

        # Resource-specific output presets
        OUTPUT_PRESETS = {
          # AWS presets
          aws_vpc: [:id, :arn, :cidr_block, :default_network_acl_id,
                    :default_route_table_id, :default_security_group_id,
                    :enable_dns_hostnames, :enable_dns_support, :main_route_table_id],
          aws_subnet: [:id, :arn, :cidr_block, :availability_zone, :vpc_id],
          aws_security_group: [:id, :arn, :name, :vpc_id, :owner_id],
          aws_instance: [:id, :arn, :public_ip, :private_ip, :public_dns, :private_dns],
          aws_s3_bucket: [:id, :arn, :bucket_domain_name, :bucket_regional_domain_name, :region],
          aws_iam_role: [:id, :arn, :name, :unique_id],
          aws_lambda_function: [:id, :arn, :invoke_arn, :qualified_arn, :version],

          # Cloudflare presets
          cloudflare_zone: [:id, :status, :name_servers, :vanity_name_servers, :verification_key, :meta],
          cloudflare_record: [:id, :hostname, :proxied, :created_on, :modified_on],
          cloudflare_worker_script: [:id],
          cloudflare_pages_project: [:id, :subdomain, :domains],

          # Hetzner presets
          hcloud_server: [:id, :name, :ipv4_address, :ipv6_address, :status],
          hcloud_network: [:id, :name, :ip_range]
        }.freeze

        attr_reader :resource_type, :resource_name, :custom_outputs

        # Initialize OutputBuilder
        #
        # @param resource_type [Symbol, String] The Terraform resource type (e.g., :aws_vpc)
        # @param resource_name [Symbol, String] The resource instance name
        # @param custom_outputs [Array<Symbol>] Additional outputs to include
        def initialize(resource_type, resource_name, *custom_outputs)
          @resource_type = resource_type.to_sym
          @resource_name = resource_name
          @custom_outputs = custom_outputs.flatten
          @preset = nil
        end

        # Use a predefined output preset
        #
        # @param preset_name [Symbol] The preset name (usually same as resource_type)
        # @return [self]
        def with_preset(preset_name = nil)
          @preset = preset_name || @resource_type
          self
        end

        # Build the outputs hash with Terraform interpolation strings
        #
        # @return [Hash<Symbol, String>] Hash of output names to interpolation strings
        def build
          outputs = {}
          output_keys = determine_outputs

          output_keys.each do |output_key|
            outputs[output_key] = interpolation_string(output_key)
          end

          outputs
        end

        # Generate a single interpolation string
        #
        # @param attribute [Symbol, String] The attribute name
        # @return [String] Terraform interpolation string
        def interpolation_string(attribute)
          "${#{resource_type}.#{resource_name}.#{attribute}}"
        end

        # Get the id interpolation string (most commonly used)
        #
        # @return [String]
        def id
          interpolation_string(:id)
        end

        # Get the arn interpolation string (common for AWS)
        #
        # @return [String]
        def arn
          interpolation_string(:arn)
        end

        private

        def determine_outputs
          outputs = Set.new([:id]) # id is always included

          # Add provider-specific common outputs
          provider = detect_provider
          if COMMON_OUTPUTS[provider]
            outputs.merge(COMMON_OUTPUTS[provider])
          end

          # Add preset outputs if specified
          if @preset && OUTPUT_PRESETS[@preset]
            outputs.merge(OUTPUT_PRESETS[@preset])
          end

          # Add custom outputs
          outputs.merge(@custom_outputs)

          outputs.to_a
        end

        def detect_provider
          type_str = resource_type.to_s
          return :aws if type_str.start_with?('aws_')
          return :cloudflare if type_str.start_with?('cloudflare_')
          return :hcloud if type_str.start_with?('hcloud_')
          :unknown
        end
      end
    end
  end
end
