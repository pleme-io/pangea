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
  module Architectures
    module Types
      # Validation helpers
      # Note: Use ::String, ::Hash, ::Array to reference Ruby's built-in classes
      # since the Types module includes Dry.Types() which shadows these names
      def self.validate_cidr_block(cidr)
        return false unless cidr.is_a?(::String)
        return false unless cidr.match?(/^\d+\.\d+\.\d+\.\d+\/\d+$/)

        ip, prefix = cidr.split('/')
        return false unless (8..30).include?(prefix.to_i)

        octets = ip.split('.').map(&:to_i)
        octets.all? { |octet| (0..255).include?(octet) }
      end

      def self.validate_domain_name(domain)
        return false unless domain.is_a?(String)
        return false if domain.length > 253

        domain.match?(/^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$/)
      end

      def self.validate_auto_scaling_config(config)
        return false unless config.is_a?(Hash)
        return false unless config[:min] && config[:max]
        return false unless config[:min] <= config[:max]

        if config[:desired]
          return false unless config[:min] <= config[:desired] && config[:desired] <= config[:max]
        end

        true
      end

      def self.validate_availability_zones(azs, region = nil)
        return false unless azs.is_a?(Array) && azs.any?
        return false unless azs.all? { |az| az.match?(/^[a-z]{2}-[a-z]+-[0-9][a-z]$/) }

        if region
          return false unless azs.all? { |az| az.start_with?(region) }
        end

        true
      end

      def self.validate_instance_type(instance_type)
        return false unless instance_type.is_a?(String)

        instance_type.match?(/^[a-z]+[0-9]+[a-z]*\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge)$/)
      end

      def self.validate_database_engine(engine)
        %w[mysql postgresql mariadb aurora aurora-mysql aurora-postgresql].include?(engine)
      end

      def self.validate_environment(environment)
        %w[development staging production].include?(environment)
      end

      def self.validate_region(region)
        return false unless region.is_a?(String)

        region.match?(/^[a-z]{2}-[a-z]+-[0-9]$/)
      end

      # Type coercion helpers
      def self.coerce_tags(tags)
        case tags
        when Hash
          tags.transform_keys(&:to_sym).transform_values(&:to_s)
        when NilClass
          {}
        else
          raise ArgumentError, "Tags must be a Hash, got #{tags.class}"
        end
      end

      def self.coerce_auto_scaling_config(config)
        case config
        when Hash
          {
            min: config[:min]&.to_i,
            max: config[:max]&.to_i,
            desired: config[:desired]&.to_i
          }.compact
        else
          raise ArgumentError, "Auto scaling config must be a Hash, got #{config.class}"
        end
      end
    end
  end
end
